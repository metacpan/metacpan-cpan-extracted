# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 8;
BEGIN
{
    use_ok('AnyEvent::POE_Reference');
}

use AnyEvent::Util;

sub set_and_run_loop
{
    my($test_desc, $ref_push_write, $match_error_code) = @_;

    my($fh1, $fh2) = portable_socketpair;

    $match_error_code ||= Errno::EBADMSG;

    my $condvar = AnyEvent->condvar;

    my $final_error_code;

    my $recv = AnyEvent::Handle->new(
	fh => $fh1,
	timeout => 5,
	on_error => sub
	{
	    my($hdl, $fatal, $msg) = @_;
	    $final_error_code ||= 0+$!;
	    $condvar->send;
	});
    $recv->push_read(poe_reference => sub
		     {
			 $final_error_code ||= 0;
			 $condvar->send;
		     });

    my $send = AnyEvent::Handle->new(
	fh => $fh2,
	timeout => 5,
	on_error => sub { });

    $send->push_write(@$ref_push_write);

    $condvar->recv;

    ok($final_error_code == $match_error_code, $test_desc);
}

set_and_run_loop("Badly formatted, not a number", [ "aaaaaaaa" ]);

set_and_run_loop("Badly formatted, \\0 not found", [ "123aaa" ]);

SKIP: {
    if (eval { require YAML })
    {
	set_and_run_loop("Wrong serializer",
			 [ poe_reference => 'YAML', [ 1, 2, 3 ] ]);
    }
    else
    {
	skip 'YAML not installed', 1;
    }
};

set_and_run_loop("No compression", [ poe_reference => undef, 1, [ 1, 2, 3 ] ]);

set_and_run_loop("No data", [ "0\0" ]);

$AnyEvent::POE_Reference::SERIALIZED_MAX_SIZE = 100;
set_and_run_loop("Too much numbers in length", [ "1234\0..." ], Errno::E2BIG);

set_and_run_loop("Too big", [ poe_reference => [ (1, 2, 3, 4, 5) x 100 ] ],
		 Errno::E2BIG);
