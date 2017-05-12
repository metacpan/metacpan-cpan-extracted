#!/usr/bin/env perl
# created on 2014-08-10

use warnings;
use strict;
use 5.010;
use Bio::Gonzales::Stat::Util qw/hist_text nstat/;

use Pod::Usage;
use Getopt::Long;
use Number::Format;

use Bio::Gonzales::Seq::IO qw/faiterate/;

my %opt = ();
GetOptions( \%opt, 'n=f','min_len=i', 'log10|l', 'breaks|b=i', 'help|h' ) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 2 ) if ( $opt{help} );

my $nfmt_nice = new Number::Format(
  -thousands_sep => ',',
  -decimal_point => '.',
  -decimal_fill  => 0
);

my @files = @ARGV;

if ( @files == 1 && $files[0] eq '-' ) {
  @files = ( \*STDIN );
}

for my $file (@files) {
  my @values;
  my @lengths;
  if ( $file && -f $file ) {
    say STDERR "FILE $file";
  }

  my $seqin = faiterate($file);
  while ( my $s = $seqin->() ) {
    push @values, $s->length if(!$opt{min_len} || ($opt{min_len} && $s->length>= $opt{min_len} ));
  }
  say "only sequences >= $opt{min_len} taken into account" if($opt{min_len});
  if ( $opt{n} && $opt{n} > 0 ) {
    my $frac = $opt{n};
    my ( $n, $count, $t ) = nstat( $frac , \@values);

    say "total sequence length: " . $nfmt_nice->format_number($t);

    say "N" . $nfmt_nice->format_number( $frac * 100, 3 ) . ": " . $nfmt_nice->format_number($n);
  }
  print hist_text( \@values, { skip_empty => 1, breaks => $opt{breaks}, 'log10' => $opt{'log10'} } );
}

=head1 NAME

  bg_fastat.pl - fasta file statistics

=head1 SYNOPSIS

  bg_fastat.pl [options] [<files>|-]

  Options:

   --help               Detailed help message
   --version            Show script version
   --n <float>          Calculate N-values 0.9 = N90, 0.5 = N50.
   --min_len <int>      Set minimum sequence length
                        (Everything lower will not be considered)
   -l, --log10          Apply log scale
   -b, --breaks <int>   Set the number of breaks


=head1 EXAMPLES



=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jw at bargsten dot org> >>

=cut
