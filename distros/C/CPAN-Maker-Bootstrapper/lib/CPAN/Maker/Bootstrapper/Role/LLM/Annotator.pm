package CPAN::Maker::Bootstrapper::Role::LLM::Annotator;
# implements cmd_annotate, cmd_update_annotations

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use CPAN::Maker::Bootstrapper::Constants qw(:all);

use Cwd qw(getcwd abs_path);
use English qw(-no_match_vars);
use File::Basename qw(basename);
use File::Copy;
use File::Temp qw(tempfile);
use JSON::PP;
use List::Util qw(none);
use Role::Tiny;

########################################################################
sub cmd_update_annotations {
########################################################################
  my ($self) = @_;

  my ($file) = $self->get_args;

  die "ERROR: file argument is required\n"
    if !$file;

  die "ERROR: $file not found or inaccessible\n"
    if !abs_path($file);

  my ( $review, $review_file ) = $self->_get_latest_review( $file, 'code' );

  die "ERROR: no review file found for $file\n"
    if !$review || !$review_file;

  ( my $annotate_file = $review_file ) =~ s/[.]\w+\z/.annotate/xsm;

  if ( !-e $annotate_file ) {
    my $generated = $self->_generate_annotate_file( $review, $review_file );
    printf {*STDOUT} "Generated %s - edit and re-run to apply.\n", $generated;
    return $SUCCESS;
  }

  my $parsed  = $self->_parse_annotate_file($annotate_file);
  my $applied = $self->_apply_annotate_file( $review, $parsed );

  my ( $fh, $tempfile ) = tempfile( 'annotations-XXXX', DIR => getcwd );

  die "ERROR: could not create temporary annotations file\n$OS_ERROR\n"
    if !$fh;

  print {$fh} JSON::PP->new->pretty->utf8->encode($review);

  close $fh
    or die "ERROR: could not close temporary annotations file\n";

  rename $tempfile, $review_file
    or die "ERROR: could not save $review_file\n$OS_ERROR\n";

  printf {*STDOUT} "Applied %d disposition%s from %s\n\n", $applied, $applied == 1 ? q{} : 's', $annotate_file;

  $self->_show_annotations( $review, $review_file );

  return $SUCCESS;
}

########################################################################
sub cmd_annotate {
########################################################################
  my ($self) = @_;

  my ( $file, $api_key ) = $self->get_args;

  die "ERROR: $file is a required argument\n"
    if !$file;

  die "ERROR: $file not found or inaccessible\n"
    if !abs_path($file);

  my ( $review, $review_file ) = $self->_get_latest_review( $file, 'code' );

  die "ERROR: nothing to annotate. No review file found.\n"
    if !$review_file;

  $review = $self->_annotate($review);

  my ( $fh, $tempfile ) = tempfile( 'annotations-XXXX', DIR => getcwd );

  die "ERROR: could not create temporary annotations file\n$OS_ERROR\n"
    if !$fh;

  print {$fh} JSON::PP->new->pretty->utf8->encode($review);

  close $fh
    or die "ERROR: could not close temporary annotations file!\n";

  rename $tempfile, $review_file
    or die "ERROR: could not save $review_file\n$OS_ERROR\n";

  $self->_show_annotations( $review, $review_file );

  if ( $self->get_finalize_annotations ) {
    $self->_finalize_annotations( $review, $review_file );
  }
  elsif ( $self->get_auto_annotate ) {
    my $llm_rsp = $self->_cmd_review(
      type          => 'code',
      file          => $file,
      review        => $review,
      model         => $review->{model} // $DEFAULT_CODE_REVIEW_MODEL,
      api_key       => $api_key,
      context_files => $self->get_context,
    );

    return $FAILURE
      if !$llm_rsp;

    $self->_print_token_usage( $llm_rsp, 'Code Review: Token Usage Report' );
  }
  else {
    # keep .annotate file in sync with review JSON
    if ( -e ( my $annotate_file = $review_file =~ s/[.]\w+\z/.annotate/xsmr ) ) {
      $self->_generate_annotate_file( $review, $review_file );
    }
  }

  return $SUCCESS;
}

########################################################################
sub _show_annotations {
########################################################################
  my ( $self, $review, $review_file ) = @_;

  require Text::ASCIITable;
  my $color_on = $self->get_color;

  my $t = Text::ASCIITable->new( { headingText => "Annotations: $review_file", allowANSI => $color_on } );

  $t->setCols( 'ID', 'Function', 'Severity', 'Disposition', 'Description' );
  $t->setColWidth( 'ID',          4 );
  $t->setColWidth( 'Function',    30 );
  $t->setColWidth( 'Severity',    $color_on ? 20 : 12 );
  $t->setColWidth( 'Disposition', $color_on ? 20 : 12 );
  $t->setColWidth( 'Description', 40 );

  my $findings = $review->{findings} // [];

  my $pending = 0;

  foreach my $f ( sort { $a->{id} <=> $b->{id} } @{$findings} ) {
    my $disposition = $f->{disposition} // q{-};

    if ( $disposition eq q{-} ) {
      $pending++;
    }

    my $severity = $f->{severity};
    $t->addRow(
      $f->{id}, $f->{function},
      $color_on ? colored( [ $COLORS->{$severity} ],         $severity )    : $severity,
      $color_on ? colored( [ $COLORS->{ uc $disposition } ], $disposition ) : $disposition,
      $f->{description},
    );
  }

  print {*STDOUT} $t;

  my $total   = scalar @{$findings};
  my $applied = $total - $pending;

  printf {*STDOUT} "%d of %d annotated. %d pending.\n\n", $applied, $total, $pending;

  return;
}

########################################################################
sub _generate_annotate_file {
########################################################################
  my ( $self, $review, $review_file ) = @_;

  ( my $annotate_file = $review_file ) =~ s/[.]\w+\z/.annotate/xsm;

  open my $fh, '>', $annotate_file
    or die "ERROR: could not open $annotate_file for writing\n$OS_ERROR";

  printf {$fh} "# source: %s\n",         $review_file;
  printf {$fh} "# model:  %s\n",         $review->{model} // 'unknown';
  printf {$fh} "# Dispositions: %s\n\n", join q{ }, sort keys %{$DISPOSITIONS};

  foreach my $f ( sort { $a->{id} <=> $b->{id} } @{ $review->{findings} } ) {
    printf {$fh} "[%d]\n",            $f->{id};
    printf {$fh} "# %s | %s\n",       $f->{function} // 'unknown', $f->{severity};
    printf {$fh} "# %s\n",            $f->{description};
    printf {$fh} "disposition: %s\n", $f->{disposition} // q{};
    printf {$fh} "comment: %s\n\n",   $f->{comment}     // q{};
  }

  close $fh
    or warn "WARNING: could not close $annotate_file: $OS_ERROR\n";

  return $annotate_file;
}
########################################################################
sub _parse_annotate_file {
########################################################################
  my ( $self, $annotate_file ) = @_;

  open my $fh, '<', $annotate_file
    or die "ERROR: could not open $annotate_file for reading\n$OS_ERROR";

  my %parsed;
  my $current_id;
  my @comment_lines;

  while ( my $line = <$fh> ) {
    chomp $line;

    next if $line =~ /\A#/xsm;  # skip comment lines
    next if $line =~ /\A\s*\z/xsm && !defined $current_id;  # skip leading blanks

    if ( $line =~ /\A\[(\d+)\]\z/xsm ) {
      if ( defined $current_id ) {
        $parsed{$current_id}{comment} = join "\n", @comment_lines;
      }
      $current_id          = $1;
      @comment_lines       = ();
      $parsed{$current_id} = {};
      next;
    }

    next if !defined $current_id;

    if ( $line =~ /\Adisposition:\s*(.*)\z/xsm ) {
      my $d = uc $1;
      $parsed{$current_id}{disposition} = $d if length $d;
      next;
    }

    if ( $line =~ /\Acomment:\s*(.*)\z/xsm ) {
      push @comment_lines, $1 if length $1;
      next;
    }

    # continuation line for comment
    if ( $line =~ /\A\s+(.*)\z/xsm ) {
      push @comment_lines, $1;
      next;
    }
  }

  # flush final section
  if ( defined $current_id ) {
    $parsed{$current_id}{comment} = join "\n", @comment_lines;
  }

  close $fh
    or warn "WARNING: could not close $annotate_file: $OS_ERROR\n";

  return \%parsed;
}
########################################################################
sub _apply_annotate_file {
########################################################################
  my ( $self, $review, $parsed ) = @_;

  my $applied = 0;

  foreach my $f ( @{ $review->{findings} } ) {
    my $entry = $parsed->{ $f->{id} }
      or next;

    if ( my $d = $entry->{disposition} ) {
      die sprintf "ERROR: invalid disposition '%s' for finding %d\n", $d, $f->{id}
        if !$DISPOSITIONS->{$d};
      $f->{disposition} = $d;
      $applied++;
    }

    # only overwrite comment if the file supplied one
    if ( defined $entry->{comment} && length $entry->{comment} ) {
      $f->{comment} = $entry->{comment};
    }
  }

  return $applied;
}

########################################################################
sub _annotate {
########################################################################
  my ( $self, $review ) = @_;

  my @annotations = @{ $self->get_annotate || [] };

  return $review
    if !@annotations;

  my $batch_comment = $self->get_comment;  # may be undef

  foreach my $a (@annotations) {
    my ( $finding, $disposition, $inline_comment ) = split /:/, $a, 3;
    $disposition = uc $disposition;

    die sprintf "ERROR: invalid disposition, must be n:{disposition} where disposition=%s\n", join q{|}, keys %{$DISPOSITIONS}
      if !$finding || $finding !~ /^\d+$/xsm || !$disposition || !$DISPOSITIONS->{$disposition};

    # inline comment beats --comment; --comment beats preserve
    my $comment = $inline_comment // $batch_comment;

    $self->_set_finding_disposition( $review, $finding, $disposition, $comment );
  }

  return $review;
}

########################################################################
sub _set_finding_disposition {
########################################################################
  my ( $self, $review, $finding, $disposition, $comment ) = @_;

  my $findings = $review->{findings};

  return
    if !$findings || !@{$findings};

  foreach my $f ( @{$findings} ) {
    next if $finding != $f->{id};
    $f->{disposition} = $disposition;
    $f->{comment}     = $comment if defined $comment;  # preserve existing if not supplied
    last;
  }

  return;
}

########################################################################
sub _finalize_annotations {
########################################################################
  my ( $self, $review, $review_file ) = @_;

  die "ERROR: mark all findings before finalizing!\n"
    if !$self->_check_annotation_dispositions($review);

  foreach my $f ( @{ $review->{findings} } ) {
    next if !$f->{disposition} || $f->{disposition} ne 'WRONG';
    $f->{disposition} = 'WRONG-RECONSIDER';
  }

  my $version = eval { slurp('VERSION') };

  die "ERROR: could not determine VERSION\n$EVAL_ERROR"
    if !$version;

  chomp $version;

  my ($stem) = $review_file =~ /^(.*?)-review/xsm;

  my $final_review_file   = sprintf '%s-%s.review',   $stem, $version;
  my $final_annotate_file = sprintf '%s-%s.annotate', $stem, $version;

  # write modified review (with WRONG-RECONSIDER conversions) to final file
  open my $fh, '>', $final_review_file
    or die "ERROR: could not open $final_review_file for writing: $OS_ERROR\n";

  print {$fh} JSON::PP->new->pretty->utf8->encode($review);

  close $fh
    or warn "WARNING: could not close $final_review_file: $OS_ERROR\n";

  # enshrine the annotate file if one exists
  ( my $annotate_file = $review_file ) =~ s/[.]\w+\z/.annotate/xsm;

  if ( -e $annotate_file ) {
    copy $annotate_file, $final_annotate_file
      or warn "WARNING: could not copy $annotate_file to $final_annotate_file: $OS_ERROR\n";
  }
  else {
    $self->_generate_annotate_file( $review, $final_review_file );
  }

  return;
}

########################################################################
sub _check_annotation_dispositions {
########################################################################
  my ( $self, $review ) = @_;

  return $TRUE
    if !$review;

  my @findings = @{ $review->{findings} };

  return $TRUE
    if !@findings || none { !defined $_->{disposition} } @findings;

  return $FALSE;
}

1;

__END__
