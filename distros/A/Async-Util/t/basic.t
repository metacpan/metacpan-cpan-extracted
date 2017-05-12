use strict;
use warnings;
use Test::More;
use List::MoreUtils qw(any);
use AnyEvent;
use Carp;

use ok 'Async::Util', qw(amap azipmap achain);

{ # amap
    my $doubler = sub {
        my ($input, $cb) = @_;
        my $err = undef;
        $cb->($input*2, $err);
    };

    my $cv = AE::cv;

    amap(
        action => $doubler,
        inputs => [ 1..3 ],
        cb     => sub { $cv->send(@_) },
    );

    my ($doubled, $err) = $cv->recv;

    confess $err if $err;

    is_deeply $doubled, [ 2, 4, 6 ], 'inputs doubled';
}

{ # amap ( output = 0 )
    my @doubled;

    my $doubler = sub {
        my ($input, $cb) = @_;

        push @doubled, $input*2;

        my $err = undef;
        $cb->(undef, $err);
    };

    my $cv = AE::cv;

    amap(
        action => $doubler,
        inputs => [ 1..3 ],
        cb     => sub { $cv->send(@_) },
        output => 0,
    );

    my (undef, $err) = $cv->recv;

    confess $err if $err;

    ok any( sub { $_ == 2 }, @doubled ), '1 was doubled';
    ok any( sub { $_ == 4 }, @doubled ), '2 was doubled';
    ok any( sub { $_ == 6 }, @doubled ), '3 was doubled';
}

{ # azipmap
    my $cv = AE::cv;

    my $subs = [
        sub { $_[1]->( $_[0] * 2, undef ) },
        sub { $_[1]->( $_[0] * 3, undef ) },
        sub { $_[1]->( $_[0] * 4, undef ) },
    ];

    azipmap(
        actions => $subs,
        inputs  => [ 1..3 ],
        cb      => sub { $cv->send(@_) },
    );

    my ($results, $err) = $cv->recv;

    confess $err if $err;

    is_deeply $results, [ 2, 6, 12 ], 'outputs look right';
}

{ # achain
    my @timers;
    my $cv = AE::cv;

    achain(
        input => 2,
        steps => [
            sub {
                my ($input, $cb) = @_;

                push @timers, AnyEvent->timer(
                    after => 0,
                    cb    => sub { $cb->($input+1) },
                );
            },

            sub {
                my ($input, $cb) = @_;
                push @timers, AnyEvent->timer(
                    after => 0,
                    cb    => sub { $cb->($input * 2) },
                );
            },

        ],
        cb => sub { $cv->send(@_) },
    );

    my ($res) = $cv->recv;
    is $res, 6, 'achain result is 6';
}

done_testing;
