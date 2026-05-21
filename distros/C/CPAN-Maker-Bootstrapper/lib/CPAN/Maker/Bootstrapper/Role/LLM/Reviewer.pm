package CPAN::Maker::Bootstrapper::Role::LLM::Reviewer;

use strict;
use warnings;

use open ':std', ':encoding(UTF-8)';

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use CPAN::Maker::Bootstrapper::Constants qw(:all);
use Cwd qw(getcwd abs_path);
use English qw(-no_match_vars);
use File::Basename qw(basename);
use File::Copy qw(copy);
use File::Find;
use File::Path qw(make_path);
use Role::Tiny;

########################################################################
sub _get_review_prompt {
########################################################################
  my ( $self, $review_type, $review ) = @_;

  if ( !-d '.prompts' || !-e ".prompts/$review_type-review.prompt" ) {
    $self->_install_prompts;
  }

  my @prompts = ( $self->get_prompt // ".prompts/$review_type-review.prompt" );
  my @profiles
    = $review && !$self->get_prompt_profile ? @{ $review->{prompt_profiles} // [] } : @{ $self->get_prompt_profile // [] };

  push @prompts, map {".prompts/$_.prompt"} @profiles;

  my $prompt = q{};

  foreach my $f (@prompts) {
    my $abs_path = abs_path($f)
      or die "ERROR: $f not found\n";

    die "ERROR: $f is empty or not found\n"
      if !-e $abs_path || !-s $abs_path;

    $prompt .= "\n" . slurp($abs_path);
  }

  $prompt =~ s/^#[^\n]*(?:\n|\z)//xsmg;
  $prompt =~ s/\n{2,}/\n/xsmg;  # collapse 2+ blank lines to one
  $prompt =~ s/\A\n+//xsm;  # strip leading blank lines

  die "ERROR: prompt file prompt is essentially empty\n"
    if $prompt !~ /\S/xsm;

  return $prompt;
}

########################################################################
sub _install_prompts {
########################################################################
  my ($self) = @_;

  make_path('.prompts');

  die "ERROR: could not create .prompts directory\n"
    if !-d '.prompts';

  my $dist_dir = $self->get_dist_dir;

  for my $type (qw(code pod)) {
    my $file = "$type-review.prompt";
    my $dest = ".prompts/$file";

    next if -e $dest;

    copy "$dist_dir/$file", $dest
      or die "ERROR: could not install $file to .prompts/: $OS_ERROR\n";

    print "Installed default prompt: $dest\n";
  }

  print "\nEdit these files to customize your review prompts.\n";
  print "Set code-review-prompt or pod-review-prompt in your\n";
  print "config to use prompts from an explicit path.\n\n";

  return;
}

########################################################################
sub _get_latest_review {
########################################################################
  my ( $self, $file, $review_type ) = @_;

  return ( undef, undef )
    if !$self->get_history;

  my $name = basename($file);
  $name =~ s/[.]in\z//xsm;
  $name =~ s/[.][^.]+\z//xsm;

  my @review_files;

  find(
    sub {
      return if !-f $File::Find::name;
      return if $_ !~ /^\Q$name\E-review.*[.]\Q$review_type\E$/xsm;
      push @review_files, $File::Find::name;
    },
    getcwd,
  );

  my ($review_file) = reverse sort { $a cmp $b } @review_files;

  return ( undef, undef )
    if !$review_file;

  my $content = slurp $review_file;

  die "ERROR: no content for $review_file\n"
    if !length $content;

  my $review = JSON::PP->new->decode($content);

  return ( $review, $review_file );
}

########################################################################
sub cmd_pod_finding {
########################################################################
  my ($self) = @_;

  my ($file) = $self->get_args;

  my ( $review, $review_file ) = $self->_get_latest_review( $file, 'pod' );

  die "ERROR: no findings for $file\n"
    if !$review || !$review_file;

  $self->_show_pod_findings( $review, $review_file );

  return $SUCCESS;
}

########################################################################
sub _show_pod_findings {
########################################################################
  my ( $self, $review, $review_file ) = @_;

  require Text::ASCIITable;

  my $mode     = $review->{mode}     // 'review';
  my $findings = $review->{findings} // [];

  if ( $mode eq 'generate' ) {
    printf {*STDOUT} "Mode: POD generation\n\n";
  }

  my $t = Text::ASCIITable->new( { headingText => "POD Review: $review_file" } );

  $t->setCols( 'ID', 'Section/Method', 'Severity', 'Description' );
  $t->setColWidth( 'ID',             4 );
  $t->setColWidth( 'Section/Method', 30 );
  $t->setColWidth( 'Severity',       12 );
  $t->setColWidth( 'Description',    40 );

  if ( !@{$findings} ) {
    print {*STDOUT} "No findings.\n\n";
    return;
  }

  foreach my $f ( sort { $a->{id} <=> $b->{id} } @{$findings} ) {
    my $location = $f->{method} // $f->{section} // '-';
    my $severity = $f->{severity};

    $t->addRow( $f->{id}, $location, $severity, $f->{description} );
    $t->addRow( q{},      q{},       q{},       "\nDetail:\n\n" . $f->{detail} );
    $t->addRow( q{},      q{},       q{},       "\nSuggestion:\n\n" . $f->{suggestion} );
    $t->addRowLine;
  }

  print {*STDOUT} $t;

  printf {*STDOUT} "%d finding%s.\n\n", scalar @{$findings}, scalar @{$findings} == 1 ? q{} : 's';

  return;
}

########################################################################
sub cmd_code_review {
########################################################################
  my ($self) = @_;

  my ( $file, $api_key ) = $self->get_args;

  my ( $review, $review_file ) = $self->_get_latest_review( $file, 'code' );

  die "ERROR: set all disposition statuses before resubmitting a review\n"
    if !$self->_check_annotation_dispositions($review);

  my $llm_rsp = $self->_cmd_review(
    type          => 'code',
    file          => $file,
    review        => $review,
    model         => $review && $review->{model} ? $review->{model} : $DEFAULT_CODE_REVIEW_MODEL,
    api_key       => $api_key,
    context_files => $self->get_context,
  );

  return $FAILURE
    if !$llm_rsp;

  $self->_print_token_usage( $llm_rsp, 'Code Review: Token Usage Report' );

  return $SUCCESS;
}

########################################################################
sub cmd_pod_review {
########################################################################
  my ($self) = @_;

  my ( $file, $api_key ) = $self->get_args;

  my ( $review, $review_file ) = $self->_get_latest_review( $file, 'pod' );

  my $llm_rsp = $self->_cmd_review(
    type    => 'pod',
    file    => $file,
    api_key => $api_key,
    model   => $review && $review->{model} ? $review->{model} : $DEFAULT_POD_REVIEW_MODEL,
  );

  return $FAILURE
    if !$llm_rsp;

  $self->_print_token_usage( $llm_rsp, 'POD Review: Token Usage Report' );

  return $SUCCESS;
}

########################################################################
sub _cmd_review {
########################################################################
  my ( $self, %args ) = @_;

  my ( $review_type, $api_key, $default_model ) = @args{qw(type api_key model)};

  my ( $file, $review, $context_files ) = @args{qw(file review context_files)};

  my $model = $self->get_model // $default_model;

  warn sprintf "WARNING: model changed from %s => %s\n", $review->{model}, $model
    if $review && $review->{model} && $model ne $review->{model};

  $self->set_model($model);

  my @context_files = $review && !$context_files ? @{ $review->{context} // [] } : @{ $context_files // [] };

  foreach my $f ( grep {defined} ( $file, @context_files ) ) {
    my $abs_path = abs_path($f);

    die "ERROR: file [$f] not found or empty.\n"
      if !$abs_path || !-e $abs_path || !-s $abs_path;
  }

  my $llm = $self->_check_llm($api_key);

  my $prompt_str = $self->_get_review_prompt( $review_type, $review );

  my @prompt;

  push @prompt, $llm->text($prompt_str);

  my $text  = $review_type eq 'pod' ? slurp( abs_path($file) ) : $self->_strip_pod($file);
  my $title = $review_type eq 'pod' ? basename($file)          : 'primary: ' . basename($file);

  push @prompt,
    $llm->document(
    data  => $text,
    title => $title,
    );

  foreach my $f (@context_files) {
    push @prompt,
      $llm->document(
      data  => $self->_strip_pod($f),
      title => 'context:' . basename($f),
      );
  }

  if ($review) {
    push @prompt,
      $llm->document(
      data  => JSON::PP->new->utf8->encode($review),
      title => 'annotations:' . basename($file),
      );
  }

  my ( $input_tokens, $input_cost ) = $llm->count_input_tokens( \@prompt );

  $self->_pre_submission_report(
    type          => $review_type,
    prompt        => $prompt_str,
    text          => $text,
    annotations   => $review ? JSON::PP->new->utf8->encode($review) : undef,
    context_files => \@context_files,
    max_tokens    => $self->get_max_tokens // 4096,
    input_tokens  => $input_tokens,
    input_cost    => $input_cost,
  );

  return $SUCCESS
    if $self->get_dry_run;

  my $llm_rsp = $self->_submit_prompt( $llm, \@prompt );
  my $content = $llm_rsp->content;

  die "ERROR: no content object returned by LLM\n"
    if !$content;

  if ( !$content->text ) {
    warn "WARNING: LLM did not return any text from request.\n";
    return;
  }

  my $name = basename($file);
  $name =~ s/[.].*$//xsm;

  my ( $sec, $min, $hour, $day, $month, $year ) = localtime;
  $year += 1900;
  $month++;

  my $ts = sprintf '%04d-%02d-%02d-%02d%02d%02d', $year, $month, $day, $hour, $min, $sec;

  my $review_file = sprintf '%s-review-%s.%s', $name, $ts, $review_type;

  my $json_text = $content->text;
  $json_text =~ s/\A\s*```(?:json)?\s*\n?//xsm;
  $json_text =~ s/\s*```\s*\z//xsm;

  $review = eval { JSON::PP->new->decode($json_text); };

  die "ERROR: unable to decode JSON\n$EVAL_ERROR\nresponse was:\n" . $content->text
    if $EVAL_ERROR;

  $review->{model} = $self->get_model;  # save for next time

  if ( $review_type eq 'code' ) {

    if ( $self->get_prompt_profile ) {
      $review->{prompt_profiles} = $self->get_prompt_profile;
    }

    if ( $self->get_context ) {
      $review->{context} = $self->get_context;
    }
  }

  open my $fh, '>', $review_file
    or die "ERROR: could not open $review_file for writing.\n$OS_ERROR";

  print {$fh} JSON::PP->new->utf8->pretty->encode($review);

  close $fh
    or warn "WARNING: could not close $review_file: $OS_ERROR";

  return $llm_rsp;
}
########################################################################
sub cmd_code_finding {
########################################################################
  my ($self) = @_;

  my ( $file, $finding_id ) = $self->get_args;

  die "ERROR: file argument is required\n"
    if !$file;

  die "ERROR: finding ID is required\n"
    if !$finding_id;

  die "ERROR: finding ID must be a positive integer\n"
    if $finding_id !~ /^\d+$/xsm || $finding_id < 1;

  die "ERROR: $file not found or inaccessible\n"
    if !abs_path($file);

  my ( $review, $review_file ) = $self->_get_latest_review( $file, 'code' );

  die "ERROR: no review file found for $file\n"
    if !$review;

  my ($finding) = grep { $_->{id} == $finding_id } @{ $review->{findings} };

  die "ERROR: finding $finding_id not found in $review_file\n"
    if !$finding;

  my $total = scalar @{ $review->{findings} };

  require Text::ASCIITable;

  my $t = Text::ASCIITable->new( { headingText => sprintf 'Finding %d of %d  -  %s', $finding_id, $total, $review_file } );

  $t->setCols( 'Field', 'Value' );
  $t->setColWidth( 'Field', 16 );
  $t->setColWidth( 'Value', 56 );
  $t->alignCol( Value => sub { return sprintf '%-56s', shift; } );

  $t->addRow( 'ID',          $finding->{id} );
  $t->addRow( 'Function',    $finding->{function} );
  $t->addRow( 'Severity',    $finding->{severity} );
  $t->addRow( 'Disposition', $finding->{disposition} // '-' );
  $t->addRow( 'Comment',     $finding->{comment}     // '-' );
  $t->addRowLine;
  $t->addRow( 'Description', $finding->{description} );
  $t->addRowLine;
  $t->addRow( 'Excerpt', $finding->{excerpt} );
  $t->addRowLine;
  $t->addRow( 'Detail', $finding->{detail} );

  print {*STDOUT} $t;

  return $SUCCESS;
}

1;

__END__
