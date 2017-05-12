package Bio::Gonzales::Stat::Util;
use warnings;
use strict;
use Carp;
use Statistics::Descriptive;
use Number::Format qw/format_number :vars/;
use POSIX qw/ceil/;
use List::Util qw/sum/;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.062'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(hist_text nstat);

my $nfmt_full = new Number::Format(
  -thousands_sep => ',',
  -decimal_point => '.',
  -decimal_fill  => 1
);

my $nfmt_nice = new Number::Format(
  -thousands_sep => ',',
  -decimal_point => '.',
  -decimal_fill  => 0
);

sub log10 {
  my $n = shift;
  return log($n) / log(10);
}

sub hist_text {
  my $v    = shift;
  my $c    = shift;
  my $stat = Statistics::Descriptive::Full->new();

  my $nf_nice = gen_number_formatter( $nfmt_nice, $c );
  my $nf_full = gen_number_formatter( $nfmt_full, $c );

  if ( $c->{log10} ) {
    $stat->add_data( map { log10($_) } @$v );
  } else {
    $stat->add_data(@$v);
  }
  my $nclass = $c->{breaks} || nclass_sturges($stat);

  my $fd = $stat->frequency_distribution_ref( $nclass + 1 );

  my $max_len = 60;
  my $count   = $stat->count;

  my @keys = sort { $a <=> $b } keys %$fd;

  my @res;
  my $longest_interval = -1;
  my $longest_cnt      = -1;
  for my $i ( 0 .. $#keys ) {
    my $last = $i == 0 ? "-inf" : $keys[ $i - 1 ];
    my $curr = $keys[$i];
    my $kcnt = $fd->{$curr};
    next if ( $kcnt == 0 && $c->{skip_empty} );
    my $len = sprintf( "%.0f", ( $kcnt * $max_len / $count ) );
    push @res, [ $nf_full->($curr), "$kcnt", "#" x $len ];
    $longest_interval = length( $res[-1][0] ) if ( length( $res[-1][0] ) > $longest_interval );
    $longest_cnt      = length( $res[-1][1] ) if ( length( $res[-1][1] ) > $longest_cnt );
  }

  my $res;
  $res .= "median: " . $nf_nice->( $stat->median, 2, 0 ) . "\n";
  $res .= "count: " . $nfmt_nice->format_number( $stat->count, 0, 0 ) . "\n";
  $res .= "5num: "
    . join( "  ",
    $nf_nice->( $stat->quantile(0) ),
    $nf_nice->( $stat->quantile(1) ),
    '>' . $nf_nice->( $stat->quantile(2) ) . '<',
    $nf_nice->( $stat->quantile(3) ),
    $nf_nice->( $stat->quantile(4) ),
    ) . "\n";
  $res .= "\n";
  for my $r (@res) {
    $res .= sprintf( "<= %${longest_interval}s (%${longest_cnt}s)  %s\n", @$r );
  }
  return $res;
}

sub gen_number_formatter {
  my $nf = shift;
  my $c  = shift;
  return sub {
    my ( $value, @rest ) = @_;

    $value = 10**$value if ( $c->{log10} );
    return $nf->format_number( $value, @rest );
  };
}

sub nclass_fd {
  my ($stat) = @_;
  my $iqr = $stat->quantile(3) - $stat->quantile(1);
  $iqr = 1 unless ($iqr);
  return ceil( $stat->sample_range / ( ( $stat->count()**( -1 / 3 ) ) * 2 * $iqr ) );
}

sub nclass_sturges {
  my ($stat) = @_;
  return ceil( log( $stat->count ) / log(2) + 1 );
}

sub nstat {
  my $frac     = shift;
  my $values   = shift;
  my $min_size = shift;

  my $total;
  if ($min_size) {
    $total = sum grep { $_ >= $min_size } @$values;
  } else {
    $total = sum @$values;
  }

  my $sum = 0;
  my $n = 0;
  for ( sort { $b <=> $a } @$values ) {
    $sum += $_;
    $n++;
    if ( $sum >= $total * $frac ) {
      return wantarray ? ( $_, $n, $total ) : $_;
    }
  }
  return;
}
