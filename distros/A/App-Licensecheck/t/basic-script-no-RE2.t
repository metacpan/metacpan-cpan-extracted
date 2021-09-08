use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.2';

use Test::Without::Module qw( re::engine::RE2 );
use Test::Command::Simple;

use Path::Tiny 0.053;

plan 1;

my @CMD
	= ( $ENV{'LICENSECHECK'} )
	|| path('blib')->exists
	? ('blib/script/licensecheck')
	: ( $^X, 'bin/licensecheck' );
diag "executable: @CMD";

subtest 'copyright declared on 3 lines' => sub {
	run_ok @CMD, qw(-m --copyright t/devscripts/texinfo.tex);
	like stdout,
		qr{GNU General Public License v3.0 or later	1985.*2012 Free Software Foundation, Inc.},
		'Testing stdout';
	is stderr, '', 'No stderr';
};

done_testing;
