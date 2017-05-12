use strict;
use warnings;
use AE;
use AnyEvent::MessagePack;
use AnyEvent::Handle;
use AnyEvent::Util;
use Test::More;

my($read_fh, $write_fh) = portable_pipe;
my @data = ( [ 1, 2, 3 ], [ 4, 5, 6 ] );

my $cv = AE::cv;

{
    my $hdl = AnyEvent::Handle->new(fh => $write_fh, on_error  => sub { die 'wtf' });
    for my $d (@data) {
        $hdl->push_write(msgpack => $d);
    }
}

sub read_handler;
sub read_handler
{
    my ($hdl, $data) = @_;

    my $e = shift @data;
    is_deeply $data, $e;
    $cv->send() unless @data;

    $hdl->push_read(msgpack => \&read_handler) if @data;
}

my $hdl = do {
    my $hdl = AnyEvent::Handle->new(fh => $read_fh, on_error  => sub { die 'wtf' });
    $hdl->push_read(msgpack => \&read_handler);
    $hdl;
};

$cv->recv();

done_testing;
