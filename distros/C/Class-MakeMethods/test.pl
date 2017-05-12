#!/usr/bin/perl

use Test::Harness;
use File::Find;

@ARGV or @ARGV = '.';

# Use both glob() and find() to locate all target .t files across platforms

warn "$0: Searching for test scripts in @ARGV\n";

@tdirs = map ( glob(), @ARGV ) 
	or die "$0: Can't find any tests matching @ARGV\n";

find( sub { /\.t\z/ and push @tests, $File::Find::name }, @tdirs );

@tests = sort { lc $a cmp lc $b } @tests 
	or die "$0: Can't find any tests in @tdirs\n";

# Run the tests, using code from ExtUtils::testlib and ExtUtils::Command::MM

warn "$0: Found " . scalar(@tests) . " .t files for test harness.\n";

unshift @INC, qw( blib/arch blib/lib );
$Test::Harness::verbose = $ENV{TEST_VERBOSE} || 0;
Test::Harness::runtests( @tests );

__END__

=head1 NAME

test.pl - Test harness with recursive directory search

=head1 SUMMARY

  make test

  perl test.pl

  perl test.pl [DIRECTORY|FILENAME|FILEGLOB]*

=head1 DESCRIPTION

Performs a recursive directory search for files ending in C<.t>,
starting from the current directory or from the paths specified on
the command line, and then runs them using Test::Harness.

=head1 CAUTION

This is a test harness, not a test script.

MakeMaker checks for the presence of a test harness named test.pl
and if present adds code to the test target to run it. Do NOT add
this to the test scripts used by a Makefile.PL (using C<test => {
TESTS => 'test.pl' }>). Do NOT create a directory named C<t/> or
else MakeMaker will also attempt to run those test scripts itself.

=head1 CREDITS AND COPYRIGHT

=head2 Author

Developed by Matthew Simon Cavalletto at Evolution Softworks. 
More free Perl software is available at C<www.evoscript.org>.

You may contact the author directly at C<evo@cpan.org> or C<simonm@cavalletto.org>. 

=head2 Thanks To

Developed with the assistance of the Perl Monks community; my thanks 
in particular to PodMaster, chromatic, BrowserUk, and Murat.

=head2 Copyright

Copyright 2004 Matthew Simon Cavalletto. 

=head2 License

You may use, modify, and distribute this software under the same terms as Perl.

=cut