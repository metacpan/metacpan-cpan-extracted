use Test::More;
use Test::Exception;
use strict;
use warnings;

use Articulate::Location;
use Articulate::LocationSpecification;
my $class = 'Articulate::LocationSpecification';

my $test_suite = [
  {
    new_location => 'zone/public/article/hello-world',
    spec         => 'zone/public/article/hello-world',
    expect       => 1,
  },
  {
    new_location => 'zone/public/article/hello-world',
    spec         => 'zone/*/article/hello-world',
    expect       => 1,
  },
  {
    new_location => 'zone/public/article/hello-world',
    spec         => '*/*/*/*',
    expect       => 1,
  },
  {
    new_location => 'zone/public/article/hello-world',
    spec         => 'zone/public',
    expect       => 'ancestor',
  },
  {
    new_location => 'zone/public/article/hello-world',
    spec         => 'zone/*',
    expect       => 'ancestor',
  },
  {
    new_location => 'zone/public',
    spec         => 'zone/public/article/hello-world',
    expect       => 'descendant',
  },
  {
    new_location => 'zone/public',
    spec         => 'zone/*/article/hello-world',
    expect       => 'descendant',
  },
];

foreach my $case (@$test_suite) {
  my $why = $case->{why}
    // "'" . $case->{new_location} . "' vs spec '" . $case->{spec} . "'";
  subtest $why => sub {
    my $location = new_location $case->{new_location};
    my $spec     = new_location_specification $case->{spec};
    my $expect   = { map { $_ => 0 }
        qw (matches matches_ancestor_of matches_descendant_of) };
    if ( $case->{expect} eq '1' ) { $expect->{$_} = 1 for keys %$expect }
    if ( $case->{expect} eq 'ancestor' ) {
      $expect->{$_} = 1 for qw(matches_ancestor_of);
    }
    if ( $case->{expect} eq 'descendant' ) {
      $expect->{$_} = 1 for qw(matches_descendant_of);
    }

    foreach my $method ( keys %$expect ) {
      if ( $expect->{$method} ) {
        ok( $spec->$method($location), $method );
      }
      else {
        ok( !$spec->$method($location), $method );
      }
    }
    }
}

done_testing();
