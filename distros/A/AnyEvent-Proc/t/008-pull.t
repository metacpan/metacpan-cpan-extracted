#!perl

use Test::Most;
use AnyEvent;
use AnyEvent::Proc;
use IO::Pipe;
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

if ( AnyEvent::detect eq 'AnyEvent::Impl::Perl' ) {
    plan skip_all => "pipes are broken with AE's pure-perl implementation";
}
else {
    plan tests => 12;
}

my ( $proc, $R, $W, $out );

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('cat');
    skip "test, reason: executablec 'cat' not available", 12 unless $bin;

    ( $R, $W ) = AnyEvent::Proc::_wpipe;

    $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5, outstr => \$out );
    ok $proc->pull($R);
    print $W "$$\n";
    close $W;
    is $proc->wait() => 0,           'wait ok, status is 0';
    like $out        => qr{^$$\s*$}, 'rbuf contains my pid';

    ( $R, $W ) = AnyEvent::Proc::_rpipe;

    $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5, outstr => \$out );
    ok $proc->pull($R);
    $W->push_write("$$\n");
    $W->destroy;
    is $proc->wait() => 0,           'wait ok, status is 0';
    like $out        => qr{^$$\s*$}, 'buf contains my pid';

    ( $R, $W ) = @{ *{ IO::Pipe->new } };

    $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5, outstr => \$out );
    ok $proc->pull($R);
    print $W "$$\n";
    close $W;
    is $proc->wait() => 0,           'wait ok, status is 0';
    like $out        => qr{^$$\s*$}, 'buf contains my pid';

    $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5, outstr => \$out );
    my $in = 'pre';
    ok $proc->pull( \$in );
    $in .= 'post';
    $in = 'overwrite';
    $proc->finish;
    is $proc->wait() => 0, 'wait ok, status is 0';
    like $out => qr{^prepostoverwrite\s*$}, 'buf contains input string';
}

done_testing;
