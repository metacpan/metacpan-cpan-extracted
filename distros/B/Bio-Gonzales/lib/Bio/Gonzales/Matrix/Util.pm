package Bio::Gonzales::Matrix::Util;

use warnings;
use strict;
use Carp;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.062'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(uniq_rows uniq_rows_secure as_matrix preview combine_to_matrix xls_idx0_to_a1 xls_range0_to_a1);

sub uniq_rows {
  my $matrix = shift;

  # http://www.perlmonks.org/?node_id=489796

  # relaxed
  my %seen;
  my @umatrix = grep { not $seen{ join $;, @$_ }++ } @$matrix;

  return \@umatrix;
}

sub uniq_rows_secure {
  my $matrix = shift;

  # http://www.perlmonks.org/?node_id=489796

  my %seen;
  my @umatrix = grep { not $seen{ join " ", map quotemeta, @$_ }++ } @$matrix;

  return \@umatrix;
}

sub as_matrix {
  my $data = shift;
  my @m;
  if ( ref $data eq 'HASH' ) {
    while ( my ( $k, $v ) = each %$data ) {
      push @m, [ $k, ( ref $v eq 'ARRAY' ? @$v : $v ) ];
    }
  }
  return \@m;
}

sub combine_to_matrix {
  my ( $data, $keys ) = @_;

  if ( !( $keys && @$keys ) && @$data ) {
    $keys = [ sort keys %{ $data->[0] } ];
  }

  return unless ( $data && @$data );

  my @res;
  for my $d (@$data) {
    push @res, [ map { $d->{$_} } @$keys ];
  }
  return \@res;
}

sub preview {
  my ( $m, $c ) = @_;

  return unless ( $m && @$m > 0 );
  my @preview;
  if ( ref $m->[0] ) {
    if ( @$m >= 6 ) {
      push @preview, @{$m}[ 0 .. 2 ];
      push @preview, [ ("...") x scalar @{ $m->[0] } ] if ( ( $c->{dots} && @$m > 6 ) || $c->{force_dots} );
      push @preview, @{$m}[ -3, -2, -1 ];
    } else {
      @preview = @$m;
    }
  } else {
    if ( @$m >= 6 ) {
      push @preview, @{$m}[ 0 .. 2 ];

      push @preview, '...' if ( ( $c->{dots} && @$m > 6 ) || $c->{force_dots} );

      push @preview, @{$m}[ -3, -2, -1 ];
    } else {
      @preview = @$m;
    }
  }
  return \@preview;

}

sub xls_idx0_to_a1 {
  my $idx = shift;

  my @letters = 'A' .. 'Z';

  my $string_idx = '';

  do {
    $idx-- if ($string_idx);
    $string_idx .= $letters[ ( $idx % 26 ) ];
    $idx = int( $idx / 26 );
  } while ( $idx > 0 );

  return reverse $string_idx;
}

sub xls_range0_to_a1 {
  my $from = shift;
  my $to   = shift;
  if ( !defined($to) ) {
    return idx0_to_a1($from) . ":" . idx0_to_a1($from);
  }

  return idx0_to_a1($from) . ":" . idx0_to_a1($to);
}

1;
