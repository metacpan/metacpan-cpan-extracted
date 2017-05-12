use strict;

use Test::More tests => 5;
use AnyEvent;

use_ok('AnyEvent::Process');

my @math = ("3+5", "4+12-7", "34*3");
my $proc;
my $cv = AE::cv;

sub reader;
sub reader {
	my ($handle, $line) = @_;

	my $expr = shift @math;
	my $result = eval $expr;
	is($line, $result, "Compute '$expr' in the child, communicate over pipes under AnyEvent::Handles");

	if (@math) {
		$handle->push_read(line => \&reader);
	} else {
		$proc->close();
	}
}

$proc = new AnyEvent::Process(
	on_completion => sub { $cv->send('DONE') },
	fh_table => [
		\*STDIN  => ['pipe', '<', handle => [push_write => [join "\n", @math, '']]],
		\*STDOUT => ['pipe', '>', handle => [push_read  => [line => \&reader]]]
	],
	code => sub {
		$| = 1;
		while (<>) {
			print eval $_, "\n";
		}
		exit 0;
	});

$proc->run();
my $rtn = $cv->recv;
is($rtn, 'DONE', "Closing handles");
