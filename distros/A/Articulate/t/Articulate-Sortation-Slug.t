use Test::More;
use Test::Exception;
use strict;
use warnings;

use Articulate::Item ();

use Articulate::Sortation::Slug;
my $class = 'Articulate::Sortation::Slug';

sub item {
  Articulate::Item->new( { meta => shift } );
}

my $test_suite = [
  {
    why   => 'Simple test',
    input => [
      qw(
        a-11
        a-12-a
        a-12a
        b
        ab
        a-12
        a-2
        a-1
        a-10
        ), ""
    ],
    output => [
      "", qw(
        a-1
        a-2
        a-10
        a-11
        a-12
        a-12-a
        a-12a
        ab
        b
        )
    ],
  },
];

sub verify {
  my $got    = join( ',', @{ $_[0] } );
  my $expect = join( ',', @{ $_[1] } );
  my $reason = $_[2];
  is( $got, $expect, $reason );
}

foreach my $case (@$test_suite) {
  my $why = $case->{why} // '';
  my $sorter = $class->new();
  verify( $sorter->sort( $case->{input} ), $case->{output}, $why . ' (sort)' );
}

done_testing();
