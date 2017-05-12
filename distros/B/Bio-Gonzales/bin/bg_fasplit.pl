#!/usr/bin/env perl
# created on 2015-01-14

use warnings;
use strict;
use 5.010;

use Bio::Gonzales::Seq::IO;
use Data::Dumper;
use List::MoreUtils qw/indexes/;
use Bio::Gonzales::Seq;
use Bio::Gonzales::Seq::Filter qw/clean_dna_seq/;

use Bio::Gonzales::Feat::IO::GFF3;
use Bio::Gonzales::Feat;

use Pod::Usage;
use Getopt::Long;

my %opt = ();
GetOptions( \%opt, 'help', 'clean_seq', 'include_junk', 'seq_f=s' ) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 2 ) if ( $opt{help} );
pod2usage(2)
  unless ( @ARGV && @ARGV == 2 );

my ( $regex, $file ) = @ARGV;

pod2usage( { -msg => "regular expression or file argument missing", -exit_val => 2 } )
  unless ( $regex && $file );

my $gffo = Bio::Gonzales::Feat::IO::GFF3->new( fh => \*STDOUT, mode => '>', escape_whitespace => 1 );
my $seq_fh;

if ( $opt{seq_f} ) {
  open $seq_fh, '>', $opt{seq_f} or die "Can't open filehandle: $!";
}

my $fait = faiterate($file);

while ( my $so = $fait->() ) {
  if ( $opt{clean_seq} ) {
    clean_dna_seq($so);
  }
  repl( $regex, $so );
}

if ($seq_fh) {
  $seq_fh->close;
}

sub repl {
  my $regex = shift;
  my $so    = shift;
  my $id    = $so->id;

  my $full_seq  = $so->seq;
  my $last_pos  = 0;
  my $match_cnt = 0;
  while ( $full_seq =~ /$regex/g ) {
    $match_cnt++;
    # we found a "restriction site"
    if ( $-[0] != 0 ) {
      # omit strings starting with "restriction site"
      my $gap = $+[0] - $-[0];
      my $match_id = sprintf( "%s|nomatch:%d|%d..%d+%d", $id, $match_cnt, $last_pos + 1, $-[0], $gap );
      $gffo->write_feat(
        Bio::Gonzales::Feat->new(
          seq_id     => $id,
          source     => 'fasplit',
          type       => 'match',
          start      => $last_pos + 1,
          end        => $-[0],
          strand     => 0,
          attributes => { ID => [$match_id], followed_gap_size => [ $gap ] },
        )
      );

      if ($seq_fh) {
        my $seq = substr $full_seq, $last_pos, $-[0] - $last_pos;
        # output everything before it
        faspew(
          $seq_fh,
          Bio::Gonzales::Seq->new(
            id  => $match_id,
            seq => $seq
          )
        );
      }
    }
    if ( $opt{include_junk} ) {
      $match_cnt++;
      my $match_id = sprintf( "%s|match:%d|%d..%d", $id, $match_cnt, $-[0] + 1, $+[0] );
      $gffo->write_feat(
        Bio::Gonzales::Feat->new(
          seq_id     => $id,
          source     => 'fasplit',
          type       => 'gap',
          start      => $-[0] + 1,
          end        => $+[0],
          strand     => 0,
          attributes => { ID => [$match_id] },
        )
      );
      if ($seq_fh) {
        faspew(
          $seq_fh,
          Bio::Gonzales::Seq->new(
            id  => $match_id,
            seq => substr( $full_seq, $-[0], $+[0] - $-[0] ),
          )
        );
      }
    }
    $last_pos = $+[0];
  }
  if ( $last_pos < length($full_seq) ) {

    my $match_id
      = sprintf( "%s|nomatch:%d|%d..%d+%d", $id, $match_cnt + 1, $last_pos + 1, length($full_seq), 0 );
    $gffo->write_feat(
      Bio::Gonzales::Feat->new(
        seq_id     => $id,
        source     => 'fasplit',
        type       => 'match',
        start      => $last_pos + 1,
        end        => length($full_seq),
        strand     => 0,
        attributes => { ID => [$match_id], followed_gap_size => [0] },
      )
    );

    if ($seq_fh) {
      my $seq = substr $full_seq, $last_pos, length($full_seq) - $last_pos;
      faspew(
        $seq_fh,
        Bio::Gonzales::Seq->new(
          id  => $match_id,
          seq => $seq
        )
      );
    }
  }
}

=head1 NAME

bg_fasplit.pl - split sequences in fasta files by given regular expression

=head1 SYNOPSIS

bg_fasplit.pl [options] <regex> <file>

  <regex> the split pattern in form of a perl regular expression
  <file>  input sequence file in fata format

Options:

  --help            brief help message
  --clean_seq       clean DNA sequence (mask unknown characters with N)
  --include_junk    sequence matched by <regex> will be included in the output
  --seq_f <file>    write the split sequences into <file>
