use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.7.0';

use Test::Command::Simple;

use Path::Tiny 0.053;

plan 4;

my @CMD
	= ( $ENV{'LICENSECHECK'} )
	|| path('blib')->exists
	? ('blib/script/licensecheck')
	: ( $^X, 'bin/licensecheck' );
diag "executable: @CMD";

subtest '--help, ignoring earlier --list-licenses' => sub {
	run_ok 1, @CMD, qw(--list-licenses --help);
	like stdout,   qr/\Q[OPTION...\E/, 'stdout contains [options...]';
	unlike stdout, qr/^WTFPL-1\.0$/m,  'stdout does not contain WTFPL-1.0';
	is stderr,     '',                 'No stderr';
};

subtest '--help, ignoring later --list-licenses' => sub {
	run_ok 1, @CMD, qw(--help --list-licenses);
	like stdout,   qr/\Q[OPTION...\E/, 'stdout contains [options...]';
	unlike stdout, qr/^WTFPL-1\.0$/m,  'stdout does not contain WTFPL-1.0';
	is stderr,     '',                 'No stderr';
};

subtest '--list-licenses' => sub {
	run_ok @CMD, qw(--list-licenses foobar.txt);
	like stdout, qr/^WTFPL-1\.0$/m, 'stdout contains WTFPL-1.0';
	is stderr,   '',                'No stderr';
};

subtest '--list-licenses, ignoring paths' => sub {
	run_ok @CMD, qw(--list-licenses foobar.txt my/baz.xml);
	like stdout, qr/^WTFPL-1\.0$/m, 'stdout contains WTFPL-1.0';
	is stderr,   '',                'No stderr';
};

done_testing;
