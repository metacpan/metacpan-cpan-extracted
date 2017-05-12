package Bio::Gonzales::Seq::Util;

use warnings;
use strict;
use Carp;

use Scalar::Util qw/blessed/;
use Data::Dumper;
use Bio::Gonzales::Matrix::IO;
use File::Which qw/which/;
use Bio::Gonzales::Seq::IO;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.062'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(
  pairwise_identity_l
  pairwise_identity_s
  pairwise_identity_gaps_l
  pairwise_identity_gaps_s
  pairwise_identities
  map_seqids
  seqid_mapper
  crc64
  strand_convert
  seq_lengths
  seq_apply
);

our %STRAND_CHAR_TABLE = (
  '+' => 1,
  '-' => -1,
  '.' => 0,
  -1  => '-',
  1   => '+',
  0   => '.',
);

our $BLASTDB_CMD  = which('blastdbcmd');
our $SAMTOOLS_CMD = which('samtools');

sub strand_convert {
  if ( @_ && @_ > 0 && $_[-1] && exists( $STRAND_CHAR_TABLE{ $_[-1] } ) ) {
    return $STRAND_CHAR_TABLE{ $_[-1] };
  } else {
    return '.';
  }
}

sub seq_lengths {
  my $f = shift;

  my $d;
  if ( -f $f . ".fai" ) {
    $d = mslurp( $f . ".fai", { header => undef } );
  } elsif ( -f $f . ".nhr" ) {
    open my $fh, '-|', $BLASTDB_CMD, '-db', $f, '-entry', 'all', '-outfmt', "%a\t%l"
      or die "Can't open filehandle: $!";
    $d = mslurp( $fh, { header => undef } );
    close $fh;
  } elsif ($SAMTOOLS_CMD) {
    system( 'samtools', 'faidx', $f ) == 0 or die "system failed: $?";
    $d = mslurp( $f . ".fai", { header => undef } ) if ( -f $f . ".fai" );
  }

  # nothing worked so far
  unless ($d) {
    say STDERR "could not use samtools or blast indices, using std method";
    my @lengths;
    my $fit = faiterate($f);
    while ( my $seq = $fit->() ) {
      push @lengths, [ $seq->id, $seq->length ];
    }
    $d = \@lengths;
  }

  my %sl;
  for my $r (@$d) {
    die "double ID" if ( $sl{ $r->[0] } );
    $sl{ $r->[0] } = $r->[1];
  }

  return \%sl;
}

sub seq_apply {
  my ( $f, $sub, $pattern ) = @_;

  die "file or sub ref not correct" unless ( ref $sub eq 'CODE' && -f $f );
  my $seq_lengths = seq_lengths($f);
  my @res;
  my $num = keys %$seq_lengths;
  for my $sid ( keys %$seq_lengths ) {
    my $spat;
    if ($pattern) {
      $spat = $pattern;
      $spat =~ s/\{id\}/$sid/g;
      $spat =~ s/\{begin\}/1/g;
      $spat =~ s/\{end\}/$seq_lengths->{$sid}/g;
    }
    push @res, $sub->( { id => $sid, begin => 1, end => $seq_lengths->{$sid}, num => $num }, $spat );
  }
  return \@res;
}

sub pairwise_identity_l {
  my ( $seq1, $seq2 ) = @_;
  return _pairwise_identity_generic( $seq1, $seq2, 1, 0 );
}

sub pairwise_identity_s {
  my ( $seq1, $seq2 ) = @_;
  return _pairwise_identity_generic( $seq1, $seq2, 0, 0 );
}

sub pairwise_identity_gaps_l {
  my ( $seq1, $seq2 ) = @_;
  return _pairwise_identity_generic( $seq1, $seq2, 1, 1 );
}

sub _pairwise_identity_generic {
  my ( $seq1, $seq2, $use_longest, $include_gaps ) = @_;

  $seq1 = $seq1->seq if ( blessed $seq1);
  $seq2 = $seq2->seq if ( blessed $seq2);

  my $seq1_gaps = 0;
  my $seq2_gaps = 0;
  if ( !$include_gaps ) {
    $seq1_gaps = $seq1 =~ y/-/./;
    $seq2_gaps = () = $seq2 =~ /-/g;
  }

  my $mask    = $seq1 ^ $seq2;
  my $matches = $mask =~ tr/\x0/\x0/;

  my $longest;
  my $shortest;
  if ( length($seq2) - $seq2_gaps < length($seq1) - $seq1_gaps ) {
    $longest  = length($seq1) - $seq1_gaps;
    $shortest = length($seq2) - $seq2_gaps;
  } else {
    $shortest = length($seq1) - $seq1_gaps;
    $longest  = length($seq2) - $seq2_gaps;
  }

  if ($use_longest) {
    return ( $matches / $longest );
  } else {
    return ( $matches / $shortest );
  }
}

sub pairwise_identity_gaps_s {
  my ( $seq1, $seq2 ) = @_;

  return _pairwise_identity_generic( $seq1, $seq2, 0, 1 );
}

sub pairwise_identities {
  my ( $sub, @seqs ) = @_;

  #creating an upper triangular matrix

  my @dist;
  for ( my $i = 0; $i < @seqs; $i++ ) {
    push @dist, [];
  }

  my $i;
  for ( $i = 0; $i < @seqs - 1; $i++ ) {
    $dist[$i][$i] = 1;
    for ( my $j = $i + 1; $j < @seqs; $j++ ) {
      $dist[$j][$i] = $sub->( $seqs[$j], $seqs[$i] );
    }
  }
  $dist[$i][$i] = 1;

  return \@dist;
}

sub map_seqids {
  my ( $seqs, $pattern ) = @_;

  my %map;

  my $i = seqid_mapper($pattern);

  for my $s (@$seqs) {
    my ( $new, $old ) = $i->($s);
    $map{$new} = $old;
  }

  return \%map;
}

sub seqid_mapper {
  my ( $pattern, @extra_args ) = @_;
  $pattern = 's%08d' unless defined $pattern;

  my $handler;
  if ( ref $pattern eq 'CODE' ) {
    $handler = $pattern;
  } elsif ( ref $pattern eq 'HASH' ) {
    my $i = 1;
    $handler = sub {
      my $id = shift;
      return defined $pattern->{$id} ? $pattern->{$id} : 'unknown_' . $i++;
    };
  } else {
    my $i = 1;
    $handler = sub {
      return sprintf $pattern, $i++;

    };
  }

  return sub {
    my ($seq) = @_;
    return unless ($seq);
    unless ( blessed($seq) ) {
      if ( ref $seq eq 'ARRAY' ) {
        croak "you supplied an array to the mapper function, use single seq Bio::Gonzales::Seq objects";
      } else {
        confess Dumper $seq ;
      }
    }

    my $orig_id = $seq->id;
    my $id = $handler->( $orig_id, @extra_args );
    $seq->id($id);

    return ( $id, $orig_id );
  };
}

{
  my $POLY64REVh = 0xd8000000;
  my @CRCTableh  = 256;
  my @CRCTablel  = 256;
  my $initialized;

  sub crc64 {
    my $sequence = shift;
    my $crcl     = 0;
    my $crch     = 0;
    if ( !$initialized ) {
      $initialized = 1;
      for ( my $i = 0; $i < 256; $i++ ) {
        my $partl = $i;
        my $parth = 0;
        for ( my $j = 0; $j < 8; $j++ ) {
          my $rflag = $partl & 1;
          $partl >>= 1;
          $partl |= ( 1 << 31 ) if $parth & 1;
          $parth >>= 1;
          $parth ^= $POLY64REVh if $rflag;
        }
        $CRCTableh[$i] = $parth;
        $CRCTablel[$i] = $partl;
      }
    }

    foreach ( split '', $sequence ) {
      my $shr        = ( $crch & 0xFF ) << 24;
      my $temp1h     = $crch >> 8;
      my $temp1l     = ( $crcl >> 8 ) | $shr;
      my $tableindex = ( $crcl ^ ( unpack "C", $_ ) ) & 0xFF;
      $crch = $temp1h ^ $CRCTableh[$tableindex];
      $crcl = $temp1l ^ $CRCTablel[$tableindex];
    }
    return wantarray ? ( $crch, $crcl ) : sprintf( "%08X%08X", $crch, $crcl );
  }
}

1;
__END__

=head1 NAME



=head1 SYNOPSIS

    use Bio::Gonzales::Seq::Util qw(
        pairwise_identity_l
        pairwise_identity_s
        pairwise_identity_gaps_l
        pairwise_identity_gaps_s
        pairwise_identities
        map_seqids
        seqid_mapper
        overlaps
        cluster_overlapping_ranges
    );

=head1 DESCRIPTION

=head1 SUBROUTINES

=over 4

=item B<< $map = map_seqids($seqs, I<$pattern>) >>

Maps all sequence ids of C<$seqs> in situ. If C<$pattern> is not given, C<s%9d> is taken as default. 


=item B<< $clustered_ranges = cluster_overlapping_ranges(\@ranges) >>

This function takes some ranges and clusters them by overlap. 

    @ranges = (
        [ $start, $stop, $some, $custom, $elements ],
        [ ... ],
        ...
    );

    $clustered_ranges = [
        # first cluster
        [
            [ $start, $stop, $some, $custom, $elements ],
            ...
        ],
        # next cluster
        [
            [ $start, $stop, $some, $custom, $elements ],
            ...
        ],
        ...
    ];


=item B<< $map = map_seqids(\@seqs!, $pattern) >>

Wrapper around C<seqid_mapper()>, maps the ids of @seqs and returns the map.
This function works directly on the sequences.

=item B<< $mapper = seqid_mapper(\%idmap) >>

Create a mapper that maps given sequences to new ids generated by the argument
given. A hash as argument will be used as mapping base, taking the key as old and the
value as new id. In case the sequence id is non-existent in the hash, an artificial id
following the pattern C<unknown_$i> with C<$i> running from 0
onwards will be generated..

=item B<< $mapper = seqid_mapper(\&handler) >>

Create a mapper that maps given sequences to new ids generated by successive
calls to the handler. The handler will get the existing/original id as
argument and shall return a new id. A simple mapper would be:


    my $i = 1;
    my $mapper = seqid_mapper(sub { sprintf "id%d", $i++ });
    or
    my $mapper = seqid_mapper(sub { my $id = shift; $id =~ s/pep/cds/; return $id});

    my ($old_id, $new_id) = $mapper->($sequence_object);

The sequence object WILL BE ALTERED IN SITU.

=item B<< $mapper = seqid_mapper($pattern) >>

Use pattern as basis for sequence id mapping, "%s" or "%d" must be included
ONLY ONCE and will be substituted by a couter, running from 0 to INF.

=item B<< $mapper = seqid_mapper() >>

Same as C<$mapper = seqid_mapper("s%9d")>

=item B<< overlaps([$a_begin, $a_end], [$b_begin, $b_end]) >>

Returns true if a overlaps with b, false otherwise.

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
