#!/usr/bin/env perl
# No file or directory in lib/ or t/ may be named after a Windows device.
#
# Windows reserves CON, PRN, AUX, NUL, COM0-COM9 and LPT0-LPT9 in every
# directory, ignoring case and, on Windows 10, any extension: "Con" and
# "Con.pm" both open the console.  Source: Microsoft Learn, "Naming Files,
# Paths, and Namespaces" (learn.microsoft.com/windows/win32/fileio/naming-a-file),
# which also lists COM and LPT followed by a superscript digit, left out here
# because no Perl module path can contain them.
#
# The distribution was Util-Con for 0.01 and 0.02, and could not be built on
# Strawberry Perl: MakeMaker's mkdir of blib\lib\auto\Util\Con failed with
# "Invalid argument" before any test ran.  The module path is checked as well
# as the files, because that auto\ directory is named after the package, not
# taken from a file in the tarball.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Find;
use File::Spec;

my $reserved = qr/^(?:CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])(?:\..*)?$/i;

my @paths;
find( { no_chdir => 1, wanted => sub { push @paths, $File::Find::name } },
	grep { -d } 'lib', 't' );
ok( scalar @paths, 'found the files in lib/ and t/' );

foreach my $path (@paths) {
	my @bad = grep { /$reserved/ } File::Spec->splitdir($path);
	ok( !@bad, "$path has no segment named after a Windows device" )
		or diag("reserved on Windows: @bad");
}

require Cn::Util;
foreach my $segment (split /::/, 'Cn::Util') {
	unlike( $segment, $reserved, "package segment $segment is not a Windows device" );
}

# The check itself: the old name must fail it.
like( 'Con', $reserved, 'Con is recognised as reserved' );
like( 'con.pm', $reserved, 'con.pm is recognised as reserved' );
unlike( 'Condon', $reserved, 'Condon is not mistaken for CON' );

done_testing();
