use strict;

use Test::More tests => 5;
use AnyEvent;
use AnyEvent::Util;

use_ok('AnyEvent::Process');

open FIRST, '<', '/dev/zero';
open SECOND, '<', '/dev/zero';

my $cv = AE::cv;
my $proc = new AnyEvent::Process(
	fh_table => [
		\*STDOUT => ['decorate', '>', sub { $cv->send($_[0]); '' }, \*STDOUT],
		\*NONE   => ['open', '<', '/dev/null']
	],
	close_all_fds_except => [\*SECOND],
	code => sub {
		print fileno NONE, "\n";
		sleep 10 while 1;
		exit 0;
	});

$proc->run();

# Wait for start
my $noneno = $cv->recv;
chomp $noneno;

# Verify files
my %opened;
my $proc_path = '/proc/' . $proc->pid . '/fd';
opendir DIRHANDLE, $proc_path;
foreach (grep /^\d+$/, readdir DIRHANDLE) {
	$opened{$_} = readlink "$proc_path/$_";
}
closedir DIRHANDLE;

# Verify opened files
is(scalar keys %opened, 3, "Three file descriptors are opened");
is($opened{fileno SECOND}, '/dev/zero', "SECOND stays opened to the same file");
is($opened{$noneno}, '/dev/null', "NONE is opened to the specified file");

SKIP: {
	skip "Test evaluation is OS specific", 1 unless $^O eq 'linux';
	like($opened{fileno STDOUT}, qr/pipe/, "STDOUT is connected to pipe");
}

close FIRST;
close SECOND;

$proc->kill;
