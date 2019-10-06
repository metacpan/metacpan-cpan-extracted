#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Author tests for the Perl distribution Algorithm-Odometer-Tiny.

=head1 Notes

How to run coverage tests (there is a custom target in F<Makefile.PL>):

 perl Makefile.PL && make authorcover
 firefox cover_db/coverage.html
 git clean -dxn  # change to -dxf to actually clean

Running tests on all Perl versions: Install the required Perl
versions with C<perlbrew>, then to set them up:

 curl -L https://cpanmin.us >/tmp/cpanm
 perlbrew exec perl /tmp/cpanm App::cpanminus Test::More App::Prove

I<Note:> cpanm doesn't work on Perls before 5.8.1. There, you'll have
to use something like this instead (there appears to currently be a
undeclared circular dependency between Storable and a newer
Test::More that has C<note>, hence the C<force> below):

 perlbrew use perl-5.6.2
 perl -MCPAN -e shell
 cpan> install ExtUtils::MakeMaker
 cpan> force install Storable
 cpan> install Test::More
 cpan> install App::Prove

Then, to run the tests:

 perlbrew exec prove -lQ

=head1 Author, Copyright, and License

Copyright (c) 2019 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use Algorithm_Odometer_Tiny_Testlib;
use File::Spec::Functions qw/ updir catfile abs2rel catdir /;
use File::Glob 'bsd_glob';

our ($BASEDIR,@PODFILES,@PERLFILES);
BEGIN {
	$BASEDIR = catdir($FindBin::Bin,updir);
	@PERLFILES = (
		catfile($BASEDIR,qw/ lib Algorithm Odometer Tiny.pm /),
		catfile($BASEDIR,qw/ lib Algorithm Odometer Gray.pm /),
		bsd_glob("$FindBin::Bin/*.t"),
		bsd_glob("$FindBin::Bin/*.pm"),
	);
	@PODFILES = @PERLFILES;
}

use Test::More $AUTHOR_TESTS ? ( tests => @PODFILES + 2*@PERLFILES + 2 )
	: (skip_all=>'author tests (set $ENV{ALGORITHM_ODOMETER_TINY_AUTHOR_TESTS} to enable)');

use Test::Perl::Critic -profile=>catfile($FindBin::Bin,'perlcriticrc');
use Test::MinimumVersion;
use Test::Pod;
use Test::DistManifest;
use Capture::Tiny qw/capture_merged/;

subtest 'MANIFEST' => sub { manifest_ok() };

for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
}

my @tasks;
for my $file (@PERLFILES) {
	critic_ok($file);
	minimum_version_ok($file, '5.006');
	open my $fh, '<', $file or die "$file: $!";  ## no critic (RequireCarping)
	while (<$fh>) {
		s/\A\s+|\s+\z//g;
		push @tasks, [abs2rel($file,$BASEDIR), $., $_] if /TO.?DO/i;
	}
	close $fh;
}

subtest 'verbatim code' => sub { plan tests=>6;
	{
		my $verb_tiny = getverbatim($PODFILES[0], qr/\b(?:synopsis)\b/i);
		is @$verb_tiny, 1, '::Tiny verbatim block count' or diag explain $verb_tiny;
		is capture_merged {
			ok eval("{ use warnings; use strict; $$verb_tiny[0]\n; } 1"), '::Tiny synopsis' or diag explain $@; ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
		}, "a1\n", 'output of ::Tiny synopsis correct';
	}
	{
		my $verb_gray = getverbatim($PODFILES[1], qr/\b(?:synopsis)\b/i);
		is @$verb_gray, 1, '::Gray verbatim block count' or diag explain $verb_gray;
		is capture_merged {
			ok eval("{ use warnings; use strict; $$verb_gray[0]\n; } 1"), '::Gray synopsis' or diag explain $@; ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
		}, "a1 b1 c1 c2 b2 a2 \n", 'output of ::Gray synopsis correct';
	}
};

diag "To-","Do Report: ", 0+@tasks, " To-","Dos found";
diag "### TO","DOs ###" if @tasks;
diag "$$_[0]:$$_[1]: $$_[2]" for @tasks;
diag "### ###" if @tasks;

