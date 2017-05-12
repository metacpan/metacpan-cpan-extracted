# Test case for RT#74518: https://rt.cpan.org/Ticket/Display.html?id=74518
# Issue and test case reported by Adam Guthrie
# Test case written by Olivier Mengué (dolmen@cpan.org)
use strict;
use warnings;
use Test::More;
use AnyEvent;
use AnyEvent::MessagePack;
use AnyEvent::Util 'portable_socketpair';

my @input = ([1, "0", undef, "0"], [1, "1", undef, "1"]);

my $input_bytes = join('', map { Data::MessagePack->pack($_) } @input);
note sprintf("Input: %0*v2X", ' ', $input_bytes);


my $packet_size = 4;


my ($r, $w) = portable_socketpair;

my $output_index = 0;

my $cv = AE::cv;

my $hdl = AnyEvent::Handle->new(
    fh => $r,
    read_size => $packet_size,
    on_read => sub {
        note "read ".length($_[0]->rbuf);
        shift->unshift_read(msgpack => sub {
            is_deeply([ $_[1] ], [ $input[$output_index++] ], "read data $output_index");
            note explain $_[1];
            if ($output_index >= @input) {
                note "End";
                #$_[0]->destroy;
                $cv->send;
            }
        })
    },
    on_error => sub {
        my ($handle, $fatal, $message) = @_;
        fail "no error";
        diag "Error: $message";
        $cv->send;
    },
    on_eof => sub {
        $cv->send;
    },
);

syswrite $w, $input_bytes;
close $w;

$cv->recv;

is($output_index, scalar @input, "everything read");

done_testing;
