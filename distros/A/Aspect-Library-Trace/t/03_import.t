#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use IPC::Run3 ();

# Find the test script
my $file = catfile('t', 'import.pl');
ok( -f $file, "Found $file test script" );

# Execute the test script
my $stdout = '';
my $stderr = '';
my $rv     = IPC::Run3::run3(
	[ $^X, (-d 'blib' ? '-Mblib' : ()), $file ],
	\undef,
	\$stdout,
	\$stderr,
);

ok( $rv,         "$file executes without error" );
is( $stdout, '', "$file returns empty STDOUT"   );
is( $stderr, <<'END_TRACE', "$file returns ok"  );
Foo::foo1
  Foo::foo2
    Foo::foo3
Foo::foo2
  Foo::foo3
Foo::foo2
  Foo::foo3
END_TRACE
