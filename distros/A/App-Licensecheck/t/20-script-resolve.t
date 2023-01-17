use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';
use Test2::Tools::Command;

use Path::Tiny 0.053;

plan 4;

my @CMD = ( $^X, 'bin/licensecheck' );
if ( $ENV{'LICENSECHECK'} ) {
	@CMD = ( $ENV{'LICENSECHECK'} );
}
elsif ( path('blib')->exists ) {
	@CMD = ('blib/script/licensecheck');
}
local @Test2::Tools::Command::command = @CMD;

subtest '--help, ignoring earlier --list-licenses' => sub {
	my ( $result, $exit_status, $stdout_ref, $stderr_ref ) = command {
		args   => [qw(--list-licenses --help)],
		stdout => qr/\Q[OPTION...\E/,
		stderr => '',
		status => 1,
	};
	unlike $stdout_ref, qr/^WTFPL-1\.0$/m,
		'stdout does not contain WTFPL-1.0';
};

subtest '--help, ignoring later --list-licenses' => sub {
	my ( $result, $exit_status, $stdout_ref, $stderr_ref ) = command {
		args   => [qw(--help --list-licenses)],
		stdout => qr/\Q[OPTION...\E/,
		stderr => '',
		status => 1,
	};
	unlike $stdout_ref, qr/^WTFPL-1\.0$/m,
		'stdout does not contain WTFPL-1.0';
};

subtest '--list-licenses' => sub {
	command {
		args   => [qw(--list-licenses foobar.txt)],
		stdout => qr/^WTFPL-1\.0$/m,
		stderr => '',
	};
};

subtest '--list-licenses, ignoring paths' => sub {
	command {
		args   => [qw(--list-licenses foobar.txt my/baz.xml)],
		stdout => qr/^WTFPL-1\.0$/m,
		stderr => '',
	};
};

done_testing;
