use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::Buffer::Shared::I64;

BEGIN {
    eval { require Socket::MsgHdr; 1 }
        or plan skip_all => "Socket::MsgHdr required";
    Socket::MsgHdr->import;
    require Socket;
    Socket->import(qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SCM_RIGHTS));
}

socketpair(my $p, my $c, AF_UNIX(), SOCK_STREAM(), PF_UNSPEC())
    or die "socketpair: $!";

my $buf = Data::Buffer::Shared::I64->new_memfd("scm-test", 8);
$buf->set(0, 42);
my $memfd = $buf->memfd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    close $p;
    my $hdr = Socket::MsgHdr->new(buflen => 64, controllen => 256);
    recvmsg($c, $hdr, 0) // die "recvmsg: $!";
    my (undef, undef, $data) = $hdr->cmsghdr;
    my ($fd) = unpack('i', $data);
    my $b = Data::Buffer::Shared::I64->new_from_fd($fd);
    $b->set(0, 9999);
    close $c;
    _exit(0);
}

close $c;
my $hdr = Socket::MsgHdr->new(buf => "fd");
$hdr->cmsghdr(SOL_SOCKET(), SCM_RIGHTS(), pack('i', $memfd));
sendmsg($p, $hdr, 0) // die "sendmsg: $!";
close $p;

waitpid $pid, 0;

is $buf->get(0), 9999, 'child wrote via SCM_RIGHTS-passed fd — visible in parent';

done_testing;
