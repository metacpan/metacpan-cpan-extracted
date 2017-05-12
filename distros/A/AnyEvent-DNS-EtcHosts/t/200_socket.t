#!/usr/bin/perl

use strict;
use warnings;

use Carp 'verbose';

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use AnyEvent;
BEGIN { require AnyEvent::Impl::Perl unless $ENV{PERL_ANYEVENT_MODEL} }

use Test::More tests => 14;

use Test::Deep;

use File::Temp 'tempfile';

my ($fh, $filename) = tempfile TMPDIR => 1, UNLINK => 1;
ok $filename;

print { $fh } << 'END';
1.2.3.4 example.com
5.6.7.8 example.com
fe00::1234 example.com
END
close $fh;

$ENV{PERL_ANYEVENT_HOSTS} = $filename;

require AnyEvent::DNS::EtcHosts;

my $guard = AnyEvent::DNS::EtcHosts->register;
ok $guard;

use AnyEvent::Socket;
use AnyEvent::Util 'AF_INET6';

{
    ok my $cv = AE::cv;

    AnyEvent::Socket::resolve_sockaddr 'example.com', 'http=80', 'tcp', 0, undef, sub {
        cmp_deeply [ map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_ ],
                   [ AF_INET6 ? qw(1.2.3.4 5.6.7.8 fe00::1234) : qw(1.2.3.4 5.6.7.8) ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}

{
    ok my $cv = AE::cv;

    AnyEvent::Socket::resolve_sockaddr 'example.com', 80, 'tcp', 0, undef, sub {
        cmp_deeply [ map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_ ],
                   [ AF_INET6 ? qw(1.2.3.4 5.6.7.8 fe00::1234) : qw(1.2.3.4 5.6.7.8) ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}

{
    ok my $cv = AE::cv;

    AnyEvent::Socket::resolve_sockaddr 'example.com', 'http=80', 'tcp', 4, undef, sub {
        cmp_deeply [ map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_ ],
                   [ qw(1.2.3.4 5.6.7.8) ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}

{
    ok my $cv = AE::cv;

    AnyEvent::Socket::resolve_sockaddr 'example.com', 'http=80', 'tcp', 6, undef, sub {
        cmp_deeply [ map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_ ],
                   [ AF_INET6 ? qw(fe00::1234) : qw() ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}
