use strict;
use warnings;

BEGIN {
    # To avoid EV that catches exceptions...
    $ENV{PERL_ANYEVENT_MODEL} = 'Perl';
}

use AE;
use AnyEvent::MessagePack;
use AnyEvent::Handle; # will load Errno for us
use File::Temp qw(tempfile);
use Test::More tests => 1;

my ($fh, $fname) = tempfile(UNLINK => 0);

my $cv = AE::cv;

{
    my $hdl = AnyEvent::Handle->new(fh => $fh, on_error  => sub { die 'wtf' });
    $hdl->push_write(undef);
    close $fh;
}

my $hdl = do {
    open my $fh, '<', $fname or die $!;
    my $hdl = AnyEvent::Handle->new(fh => $fh,
                                    on_error => sub { $cv->send($_[2]) });
    $hdl->push_read(msgpack => sub {
        $cv->send(0);
    });
    $hdl;
};

my $err = $cv->recv();
ok(($err eq do { local $! = Errno::EBADMSG; "$!" }) || ($err eq do { local $! = Errno::EPIPE; "$!"} ), "$err");
unlink $fname;
