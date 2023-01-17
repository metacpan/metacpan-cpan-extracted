use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';
use Test2::Tools::Command;

use Path::Tiny 0.053;

plan 3;

my @CMD = ( $^X, 'bin/licensecheck' );
if ( $ENV{'LICENSECHECK'} ) {
	@CMD = ( $ENV{'LICENSECHECK'} );
}
elsif ( path('blib')->exists ) {
	@CMD = ('blib/script/licensecheck');
}
local @Test2::Tools::Command::command = @CMD;

subtest 'machine-readable output; short-form option' => sub {
	command {
		args   => [qw(-m t/devscripts/beerware.cpp)],
		stdout => qr{Beerware License},
		stderr => '',
	};
};

subtest 'machine-readable output; long-form option' => sub {
	command {
		args   => [qw(--machine t/devscripts/gpl-2)],
		stdout => qr{GNU General Public License, Version 2$},
		stderr => '',
	};
};

subtest 'machine-readable output w/ copyright' => sub {
	command {
		args   => [qw(-m --copyright t/devscripts/gpl-2)],
		stdout =>
			qr{GNU General Public License, Version 2\t2012 Devscripts developers\n$},
		stderr => '',
	};
};

done_testing;
