use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';

use Test::Command::Simple;

use Path::Tiny 0.053;

plan 3;

my @CMD = ( $^X, 'bin/licensecheck' );
if ( $ENV{'LICENSECHECK'} ) {
	@CMD = ( $ENV{'LICENSECHECK'} );
}
elsif ( path('blib')->exists ) {
	@CMD = ('blib/script/licensecheck');
}
diag "executable: @CMD";

subtest 'machine-readable output; short-form option' => sub {
	run_ok @CMD, qw(-m t/devscripts/beerware.cpp);
	like stdout, qr{Beerware License}, 'Testing stdout';
	is stderr,   '',                   'No stderr';
};

subtest 'machine-readable output; long-form option' => sub {
	run_ok @CMD, qw(--machine t/devscripts/gpl-2);
	like stdout, qr{GNU General Public License, Version 2$}, 'Testing stdout';
	is stderr,   '',                                         'No stderr';
};

subtest 'machine-readable output w/ copyright' => sub {
	run_ok @CMD, qw(-m --copyright t/devscripts/gpl-2);
	like stdout,
		qr{GNU General Public License, Version 2\t2012 Devscripts developers\n$},
		'Testing stdout';
	is stderr, '', 'No stderr';
};

done_testing;
