package Bio::Gonzales::Matrix::Util;

use warnings;
use strict;
use Carp;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(uniq_rows uniq_rows_secure as_matrix);

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

1;
