use strict;

use Test::More tests => 7;
use AnyEvent;
use AnyEvent::Util;

use_ok('AnyEvent::Process');

my ($my_out, $chld_out) = portable_pipe;
my ($my_err, $chld_err) = portable_pipe;

my $cv = AE::cv; my $counter = 1;
my $proc = new AnyEvent::Process(
	on_completion => sub { close $chld_err; close $chld_out; $cv->send(); },
	fh_table => [
		\*STDOUT => ['decorate', '>', 'CHLD OUT: ', $chld_out],
		\*STDERR => ['decorate', '>', sub {'CHLD ERR ' . $counter++ . ': ' . $_[0]}, $chld_err]
	],
	code => sub {
		print STDERR "Message on STDERR\n";
		print "Message on STDOUT\n";
		print STDERR "Second message on STDERR\n";
		print "Second message on STDOUT\n";
		exit 0;
	});


my ($flop_out, $flop_err) = (0, 0);
my $w_out; $w_out = AE::io $my_out, 0, sub {
	if ($flop_out == 0) {
		is(<$my_out>, "CHLD OUT: Message on STDOUT\n", 'First line of STDOUT'); 
	} elsif ($flop_out == 1) {
		is(<$my_out>, "CHLD OUT: Second message on STDOUT\n", 'Second line of STDOUT'); 
	} else {
		is(<$my_out>, undef, 'Nothing else printed on STDOUT'); 
		undef $w_out;
	}	
	$flop_out++;
};

my $w_err; $w_err = AE::io $my_err, 0, sub {
	if ($flop_err == 0) {
		is(<$my_err>, "CHLD ERR 1: Message on STDERR\n", 'First line of STDERR'); 
	} elsif ($flop_err == 1) {
		is(<$my_err>, "CHLD ERR 2: Second message on STDERR\n", 'Second line of STDERR'); 
	} else {
		is(<$my_err>, undef, 'Nothing else printed on STDERR'); 
		undef $w_err;
	}	
	$flop_err++;
};

$proc->run();

$cv->recv();
$cv = AE::cv;
my $w = AE::timer 2, 0, sub { $cv->send() };
$cv->recv();
