use strict;
use warnings;

package Test::PgTAP;

our $VERSION = '0.001';

use parent qw( Test::Builder::Module );

use Test::Deep qw( bag deep_diag cmp_details );

our @EXPORT = qw( tables_are );
# the idea how to inject a database handle was borrowed from
# https://metacpan.org/pod/Test::DatabaseRow
our $Dbh;

sub tables_are($;$$) {
  my ( $schema, $expected_tables, $test_name );
  my $first_arg = shift;
  if ( 'ARRAY' eq ref( $first_arg ) ) {
    $expected_tables = $first_arg;
    ( $test_name ) = @_;
  } else {
    $schema = $first_arg;
    ( $expected_tables, $test_name ) = @_;
  }

  my @got_tables;
  if ( defined $schema ) {
    my $sth = $Dbh->table_info( '%', defined $schema ? $schema : '%', '%', 'TABLE' );
    while ( my $row = $sth->fetchrow_hashref ) {
      push @got_tables, $row->{ TABLE_NAME };
    }
  } else {
    @got_tables = map { s/\A[^.]+\.//; $_ } grep { !/\Ainformation_schema\./ } $Dbh->tables( '%', '%', '%', 'TABLE' );
  }

  my ( $ok, $stack ) = cmp_details( \@got_tables, bag( @$expected_tables ) );
  my $Test = __PACKAGE__->builder;
  unless ( defined $test_name ) {
    $test_name =
      defined $schema
      ? "Schema '$schema' should have the correct tables"
      : 'Non Pg schemas should have the correct tables';
  }
  unless ( $Test->ok( $ok, $test_name ) ) {
    my $diag = deep_diag( $stack );
    $Test->diag( $diag );
  }
}

1;
