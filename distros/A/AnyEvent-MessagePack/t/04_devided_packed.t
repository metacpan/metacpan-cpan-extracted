use Test::More 0.96;
use AnyEvent::Impl::Perl;
use AE;
use AnyEvent::MessagePack;
use AnyEvent::Handle;
use File::Temp qw(tempfile);

my $data = 'x' x 8193;
my ($fh, $fname) = tempfile(UNLINK => 0);
my $cv = AE::cv;

{
    my $hdl = AnyEvent::Handle->new(fh => $fh, on_error => sub { die 'wtf' });
    $hdl->push_write(msgpack => $data);
    close $fh;
}

my $hdl = do {
    open my $fh, '<', $fname or die $!;
    my $hdl = AnyEvent::Handle->new(fh => $fh, on_error => sub { die 'wtf' });
    $hdl->push_read(msgpack => sub {
        my ($hdl, $got) = @_;

        is_deeply $got, $data;
        $cv->send;
    });
    $hdl;
};

$cv->recv;
unlink $fname;

done_testing;
