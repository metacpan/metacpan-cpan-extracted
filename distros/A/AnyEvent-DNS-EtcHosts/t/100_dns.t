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

use AnyEvent::DNS;

{
    ok my $cv = AE::cv;

    AnyEvent::DNS::any 'example.com', sub {
        cmp_deeply [ map { $_->[4] } grep { $_->[1] =~ /^(a|aaaa)$/ } @_ ],
                   [ qw(1.2.3.4 5.6.7.8 fe00::1234) ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}

{
    ok my $cv = AE::cv;

    AnyEvent::DNS::a 'example.com', sub {
        cmp_deeply [ @_ ],
                   [ qw(1.2.3.4 5.6.7.8) ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}

{
    ok my $cv = AE::cv;

    AnyEvent::DNS::aaaa 'example.com', sub {
        cmp_deeply [ @_ ],
                   [ qw(fe00::1234) ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}

{
    ok my $cv = AE::cv;
    AnyEvent::DNS::srv 'http', 'tcp', 'example.com', sub {
        cmp_deeply [ map { $_->[3] } @_ ],
                   [ qw(example.com) ];
        $cv->send;
    };

    $cv->recv;
    ok 1;
}
