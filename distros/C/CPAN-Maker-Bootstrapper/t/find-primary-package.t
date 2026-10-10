#!/usr/bin/env perl

use strict;
use warnings;

use CPAN::Maker::Bootstrapper::Role::Installer;
use Role::Tiny;
use Test::More;

{

  package Local::Logger;

  sub debug { return; }
  sub info  { return; }
  sub warn  { return; }
  sub error { return; }
}

{

  package Local::Installer;

  Role::Tiny->apply_roles_to_package( __PACKAGE__, 'CPAN::Maker::Bootstrapper::Role::Installer', );

  sub get_logger {
    return bless {}, 'Local::Logger';
  }
}

my $installer = bless {}, 'Local::Installer';

my @tests = (
  { label    => 'happy path - single package',
    path     => 'lib/Foo/Bar.pm',
    packages => ['Foo::Bar'],
    expected => 'Foo::Bar',
  },
  { label    => 'multiple packages - primary wins',
    path     => 'lib/Foo/Bar.pm',
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
    path     => 'lib/Foo/Bar.pm.in',
    packages => ['Foo::Bar'],
    expected => 'Foo::Bar',
  },
  { label    => 'no matching package',
    path     => 'lib/Foo/Bar.pm',
    packages => ['Baz::Quux'],
    expected => undef,
  },
  { label    => 'deeply nested',
    path     => 'lib/Foo/Bar/Baz.pm',
    packages => [ 'Foo::Bar::Baz', 'Foo::Bar::Baz::Helpers' ],
    expected => 'Foo::Bar::Baz',
  },
);

for my $test (@tests) {
  my $result = $installer->_find_primary_package( $test->{path}, $test->{packages} );

  is $result, $test->{expected}, $test->{label};
}

done_testing;

1;
