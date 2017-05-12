#!/usr/bin/perl

# Check that tracing can be applied lexically

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
my $file = catfile('t', 'lexical.pl');
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

ok( $rv,         "$file executes without error"   );
is( $stderr, '', "$file returns empty STDERR"     );
$stdout =~ s/\s+\(.+//g;
is( $stdout, <<'END_TEXT', 'STDOUT contains the expected output' );
1 trial of Foo::foo1
2 trials of Foo::foo2
2 trials of Foo::foo3
END_TEXT
