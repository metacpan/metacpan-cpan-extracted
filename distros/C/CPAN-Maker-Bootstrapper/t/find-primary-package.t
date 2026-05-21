#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use CPAN::Maker::Bootstrapper;

my $bootstrapper = bless {}, 'CPAN::Maker::Bootstrapper';

my @tests = (
  { label    => 'happy path - single package',
    path     => '/home/rlauer/git/test/lib/Foo/Bar.pm',
    packages => ['Foo::Bar'],
    expected => 'Foo::Bar',
  },
  { label    => 'multiple packages - primary wins',
    path     => '/home/rlauer/git/test/lib/Foo/Bar.pm',
    packages => [ 'Foo::Bar', 'Foo::Bar::Helpers' ],
    expected => 'Foo::Bar',
  },
  { label    => 'no lib component in path',
    path     => '/tmp/Foo/Bar.pm',
    packages => ['Foo::Bar'],
    expected => 'Foo::Bar',
  },
  { label    => 'absolute path leading slash stripped',
    path     => '/Foo/Bar.pm',
    packages => ['Foo::Bar'],
    expected => 'Foo::Bar',
  },
  { label    => 'single component',
    path     => '/tmp/Foo.pm',
    packages => ['Foo'],
    expected => 'Foo',
  },
  { label    => 'pm.in extension',
    path     => '/home/rlauer/git/test/lib/Foo/Bar.pm.in',
    packages => ['Foo::Bar'],
    expected => 'Foo::Bar',
  },
  { label    => 'no matching package',
    path     => '/home/rlauer/git/test/lib/Foo/Bar.pm',
    packages => ['Baz::Quux'],
    expected => undef,
  },
  { label    => 'deeply nested',
    path     => '/home/rlauer/git/test/lib/Foo/Bar/Baz.pm',
    packages => [ 'Foo::Bar::Baz', 'Foo::Bar::Baz::Helpers' ],
    expected => 'Foo::Bar::Baz',
  },
);

plan tests => scalar @tests;

for my $test (@tests) {
  my $result = $bootstrapper->_find_primary_package( $test->{path}, $test->{packages} );

  is $result, $test->{expected}, $test->{label};
}
