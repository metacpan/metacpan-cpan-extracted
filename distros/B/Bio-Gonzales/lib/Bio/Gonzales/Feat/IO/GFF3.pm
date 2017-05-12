package Bio::Gonzales::Feat::IO::GFF3;

use Mouse;

use warnings;
use strict;

use 5.010;
use Carp;

use List::MoreUtils qw/zip/;
use Bio::Gonzales::Feat;
use Data::Dumper;
use Carp;
use Scalar::Util qw/blessed/;
use Bio::Gonzales::Seq::Util qw/strand_convert/;

extends 'Bio::Gonzales::Feat::IO::Base';

our $VERSION = '0.062'; # VERSION

our $FASTA_RE         = qr/^\>/;
our $SEQ_REGION_RE    = qr/^\#\#sequence-region\s+(\S+)\s+(\S+)\s+(\S+)\s*/;
our $ATTR_UNESCAPE_RE = qr/%([0-9A-Fa-f]{2})/;

our @GFF_COLUMN_NAMES = qw/
  seq_id
  source
  type
  start
  end
  score
  strand
  phase
  attributes
  /;

has segments => ( is => 'rw', default => sub { [] } );
has _wrote_sth_before => ( is => 'rw' );
has pragmas           => ( is => 'rw', default => sub { {} } );
has preprocess        => ( is => 'rw' );
has comments          => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has no_header         => ( is => 'rw' );
has escape_whitespace => ( is => 'rw' );
has quiet             => ( is => 'rw' );

sub BUILD {
  my ($self) = @_;

  $self->_parse_header if ( $self->mode eq '<' );
}

sub _parse_header {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my $l;
  while ( defined( $l = $fhi->() ) ) {
    next if ( !$l || $l =~ /^\s*$/ );

    if ( $l =~ /^##gff-version\s+(\d+)/ ) {
      confess "I need gff version 3" if ( $1 != 3 );
      # if no tag given, assume 3 by default
    } elsif ( $l =~ /$SEQ_REGION_RE/ ) {
      my ( $seqid, $start, $end ) = ( $1, $2, $3 );
      push @{ $self->segments }, { id => $seqid, start => $start, end => $end };
    } elsif ( $l =~ /^\#\#(feature-ontology)\s+(.*)$/ ) {
      $self->pragmas->{$1} //= [];
      push @{ $self->pragmas->{$1} }, $2;
    } elsif ( $l =~ /^\#\#(attribute-ontology)\s+(.*)$/ ) {
      $self->pragmas->{$1} //= [];
      push @{ $self->pragmas->{$1} }, $2;
    } elsif ( $l =~ /^\#\#(source-ontology)\s+(.*)$/ ) {
      $self->pragmas->{$1} //= [];
      push @{ $self->pragmas->{$1} }, $2;
    } elsif ( $l =~ /^\#\#(species)\s+(.*)$/ ) {
      $self->pragmas->{$1} //= [];
      push @{ $self->pragmas->{$1} }, $2;
    } elsif ( $l =~ /^\#\#(genome-build)\s+(.*)$/ ) {
      $self->pragmas->{$1} //= [];
      push @{ $self->pragmas->{$1} }, $2;
    } elsif ( $l =~ /^(\#\#\#)/ ) {
    } elsif ( $l =~ /^(\#\#FASTA)/ ) {
    } elsif ( $l =~ /$FASTA_RE/ ) {
      $self->_parse_seq($l);
    }

    #looks like the header is over!
    last unless $l =~ /^\#/;
  }

  push @{ $self->_cached_records }, $l;

  return;
}

sub _write_header {
  my ($self) = @_;

  $self->_wrote_sth_before(1) && return if ( $self->no_header );
  my $fh = $self->fh;
  say $fh '##gff-version 3';

  while ( my ( $p, $entries ) = each %{ $self->pragmas } ) {
    for my $e (@$entries) {
      say $fh '##' . $p . " " . $e;
    }
  }

  for my $c ( @{ $self->comments } ) {
    say $fh '#' . $c;
  }

  for my $s ( @{ $self->segments } ) {
    say $fh join ' ', '##sequence-region', @{$s}{qw/id start end/};
  }

  $self->_wrote_sth_before(1);
}

sub _parse_seq {
  my ( $self, $faheader ) = @_;

  my $fhi = $self->_fhi;

  # defined check not necessary
  while ( my $l = $fhi->() ) {
    if ( $l =~ /^\#/ ) {
      last;
    }
    if ( $l =~ /$FASTA_RE/ ) {
      push @{ $self->_cached_records }, $l;
      last;
    }
  }
  return;
}

sub next_feat {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my $l;
  while ( defined( $l = $fhi->() ) ) {
    if ( $l =~ /$SEQ_REGION_RE/ ) {
      my ( $seqid, $start, $end ) = ( $1, $2, $3 );
      push @{ $self->segments }, { id => $seqid, start => $start, end => $end };
    } elsif ( $l =~ /^\#\#\#/ ) {
      next;
    } elsif ( $l =~ /^\#/ || $l =~ /^\s*$/ || $l =~ m{^//} ) {
      next;
    } elsif ( $l =~ /$FASTA_RE/ ) {
      $self->_parse_seq($l);
      next;
    } else {
      last;
    }
  }
  return unless $l;

  my $feat = $self->_parse_gff_line($l);

  return $feat;
}

sub next_feat_raw {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my $l;
  while ( defined( $l = $fhi->() ) ) {
    if ( $l =~ /$SEQ_REGION_RE/ ) {
      my ( $seqid, $start, $end ) = ( $1, $2, $3 );
      push @{ $self->segments }, { id => $seqid, start => $start, end => $end };
    } elsif ( $l =~ /^\#\#\#/ ) {
      next;
    } elsif ( $l =~ /^\#/ || $l =~ /^\s*$/ || $l =~ m{^//} ) {
      next;
    } elsif ( $l =~ /$FASTA_RE/ ) {
      $self->_parse_seq($l);
      next;
    } else {
      last;
    }
  }
  return unless $l;

  return $l;
}

sub write_feat {
  my ( $self, @feats ) = @_;
  my $fh = $self->fh;

  $self->_write_header
    unless ( $self->_wrote_sth_before );

  for my $f (@feats) {
    confess "feature is no a Bio::Gonzales::Feat: " . Dumper($f)
      unless ( blessed $f eq 'Bio::Gonzales::Feat' );
    print $fh $f->to_gff3( $self->escape_whitespace );
  }

  return $self;
}

sub write_comment {
  my ( $self, $text ) = @_;

  my $fh = $self->fh;

  $self->_write_header
    unless ( $self->_wrote_sth_before );

  print $fh '#' . $text . "\n";

  return $self;
}

sub _from_gff3_string {
}

sub _split_attributes {
  my ( $self, $attributes ) = @_;

  my %attrs;
  my @groups = split( /\s*;\s*/, $attributes );

  for my $group (@groups) {
    my ( $tag, $value ) = split /=/, $group;

    $tag =~ s/$ATTR_UNESCAPE_RE/chr(hex($1))/eg;
    if ( defined($value) ) {
      my @values = map { s/$ATTR_UNESCAPE_RE/chr(hex($1))/eg; $_ } split /,/, $value;
      $attrs{$tag} //= [];
      push @{ $attrs{$tag} }, @values;
    } else {
      carp "WARNING: Problems to extract attribute, found: $tag" unless ( $self->quiet );
    }
  }
  return \%attrs;
}

sub _parse_gff_line {
  my ( $self, $l ) = @_;

  my @d = split( /\t/, $l );

  confess "error in gff:\n$l\n"
    unless ( @d == 9 );

  if ( ref $self->preprocess eq 'CODE' ) {
    @d = $self->preprocess->(@d);
  }

  $d[8] = $self->_split_attributes( $d[8] );

  if    ( $d[6] eq '-' ) { $d[6] = -1; }
  elsif ( $d[6] eq '+' ) { $d[6] = 1; }
  else                   { $d[6] = 0; }

  my %feat;
  for ( my $i = 0; $i < @GFF_COLUMN_NAMES; $i++ ) {
    $feat{ $GFF_COLUMN_NAMES[$i] } = $d[$i] unless ( $d[$i] eq '.' );
  }

  return Bio::Gonzales::Feat->new( \%feat );
}

sub write_collected_feats {
  my ( $self, $sub ) = @_;
  my $fh = $self->fh;

  $self->_connect_feats;
  my $parents           = $self->_find_parent_feats;
  my $escape_whitespace = $self->escape_whitespace;

  my $gsub = sub {
    my ( $f, $id ) = @_;
    $sub->( $f, $id ) if ($sub);
    $f->sort_subfeats;
    print $fh $f->to_gff3($escape_whitespace);
    return;
  };

  for my $p (@$parents) {
    $gsub->($p);
    $p->recurse_subfeats($gsub);
  }
  return;

}

1;

__END__

=head1 NAME

Bio::Gonzales::Feat::IO::GFF3 - read and write gff files

=head1 SYNOPSIS

  use Bio::Gonzales::Feat::IO::GFF3;

  my $output = Bio::Gonzales::Feat::IO::GFF3->new( file => 'a.gff', mode => '>', escape_whitespace => 1 );
  my $gffin = Bio::Gonzales::Feat::IO::GFF3->new( file => 'a.gff' );

  # gzipped files can be read directly.
  my $gffin = Bio::Gonzales::Feat::IO::GFF3->new( file => 'a.gff.gz' );

  my $gffin = Bio::Gonzales::Feat::IO::GFF3->new('a.gff');

  while ( my $feat = $gffin->next_feat ) {
    # $feat is a Bio::Gonzales::Feat
    next if ( $feat->type ne 'mRNA' );

    say STDERR $feat->id . " - " . $feat->parent_id;
  }

  $gffin->close;


=head1 DESCRIPTION

=head1 OPTIONS

=over 4

=item B<< mode => $mode >>

Bio::Gonzales::Feat::IO::GFF3 supports 3 different modes,

  Bio::Gonzales::Feat::IO::GFF3->new(mode => '>', ...); #output
  Bio::Gonzales::Feat::IO::GFF3->new(mode => '<', ...); #input, DEFAULT
  Bio::Gonzales::Feat::IO::GFF3->new(mode => '>>', ...); #append

all modes also work with gzipped files (ending on '.gz').

=item B<< fh => $fh >>

Bio::Gonzales::Feat::IO::GFF3 uses $fh to read or write data.

  open my $fh, '<', 'file.gff3' or confess "Can't open filehandle: $!";
  my $gff = Bio::Gonzales::Feat::IO::GFF3->new(fh => $fh, ...);

  # ... do something ...

  $gff->close;
  close $fh;

=item B<< file => $file >>

read from or write to the file C<$file>

=item B<< escape_whitespace => 1 >>

Usually, only whitespaces in the C<Target> attribute are escaped. If this
feature is turned on, whitespace in all attribute values will be escaped.

=item B<< record_filter => sub { ... } >>

Before reading in the GFF3 information, filter the raw line content according
to the supplied function. This functionality is handy for big gff3 files where
only a part of the output should be parsed.

Example:

  my $sub = sub {
    my $line = shift;

    return $line =~ /\tmRNA\t/;
  };
  my $gff = Bio::Gonzales::Feat::IO::GFF3->new( file => '...', mode => '<', record_filter => $sub );

  # ... only lines with the type 'mRNA' will be parsed ...

  $gff->close;


=back

=head1 METHODS

=over 4

=item B<< $gffio->write_feat($feat) >>

Write the feature to the output. Do not forget to call C<$gffio->close> at the
end of the processing, otherwise you probably end up writing only half of the
features.

=item B<< my $feat = $gffio->next_feat() >>

Retrieve the next feature, if in reading mode.

=item B<< $gffio->segments >>

=item B<< $gffio->pragmas >>

=item B<< $gffio->preprocess(\&process) >>

Change the gff input before the feature object gets instantiated. Arguments of the C<&process> sub are the nine columns of the gff file split into an array.

Example sub:
    sub process {
        my @cols = @_;

        $cols[1] = "createdbyme";
        return @cols;
    }

=item B<< $gffio->comments >>

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
