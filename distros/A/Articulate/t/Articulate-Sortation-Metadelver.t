use Test::More;
use Test::Exception;
use strict;
use warnings;

use Articulate::Item ();

use Articulate::Sortation::MetaDelver;
my $class = 'Articulate::Sortation::MetaDelver';

sub item {
  Articulate::Item->new( { meta => shift } );
}

my $test_suite = [
  {
    why    => 'Simple test',
    config => {
      field => 'foo'
    },
    input => [
      {
        foo   => 'baz',
        order => 2
      },
      {
        foo   => 'bar',
        order => 1
      }
    ]
  },
  {
    why    => 'Simple test - nested search',
    config => {
      field => 'foo/oof'
    },
    input => [
      {
        foo   => { oof => 'baz' },
        order => 2
      },
      {
        foo   => { oof => 'bar' },
        order => 1
      },
      {
        foo   => { oof => 'carp' },
        order => 3
      },
      {
        foo   => { oof => 'cluck' },
        order => 4
      },
    ]
  },
];

use YAML;

sub verify {
  my $array  = shift;
  my $reason = shift;
  my $expect = join( ',', ( 1 .. scalar @$array ) );
  my $got    = join( ',', map { $_->meta->{order} } @$array );
  is( $got, $expect, $reason ) or diag Dump $array;
}

foreach my $case (@$test_suite) {
  my $why = $case->{why} // '';
  my $items = [ map { item($_) } @{ $case->{input} } ];
  my $sorter = $class->new( { options => $case->{config} } );
  verify( $sorter->sort($items), $why . '(sort)' );
  $items = [ map { item($_) } @{ $case->{input} } ];
  verify( $sorter->schwartz($items), $why . '(schwartz)' );

}

done_testing();
