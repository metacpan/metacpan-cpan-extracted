#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use B;
use Scalar::Util    qw/blessed/;
use Clone::Closure  qw/clone/;

BEGIN { *b = \&B::svref_2object }

my $tests;

{
    BEGIN { $tests += 3 }

    my %hash;
    my $hv = clone \%hash;

    isa_ok  b($hv),             'B::HV',        'empty HV cloned';
    isnt    $hv,                \%hash,         '...not copied';
    is      scalar(keys %$hv),  0,              '...correctly';
}

{
    BEGIN { $tests += 4 }

    my %hash = qw/a b c d/;
    my $hv   = clone \%hash;

    is      scalar(keys %$hv),  2,              'HV size cloned';
    is      join(':', sort keys %$hv),
                                'a:c',          'HV keys cloned';
    is      $hv->{a},           'b',            'HV values cloned';
    isnt    \$hv->{a},          \$hash{a},      '...not copied';
}

SKIP: {
    my $skip;
    eval 'require utf8';
    defined &utf8::is_utf8 or skip 'no utf8 support', $skip;

    BEGIN { $skip += 3 }

    my %hash  = ("\x{FFF}" => 4);
    my $hv    = clone \%hash;
    my ($key) = keys %$hv;

    ok      utf8::is_utf8($key),                'utf8 keys cloned';
    is      $key,               "\x{FFF}",      '...correctly';
    is      $hv->{"\x{FFF}"},   4,              '...and can be used';

    BEGIN { $tests += $skip }
}

{
    BEGIN { $tests += 5 }

    my $href      = { a => { b => 'c', d => undef } };
    $href->{a}{d} = $href;
    my $hv        = clone $href;

    isa_ok  b($hv->{a}),        'B::HV',        'nested HV cloned';
    isnt    $hv->{a},           $href->{a},     '...not copied';
    is      $hv->{a}{b},        'c',            '...correctly';

    is      $hv->{a}{d},        $hv,            'recusive hrefs cloned';
    isnt    $hv->{a}{d},        $href,          '...not copied';
}

{
    BEGIN { $tests += 2 }

    my $href = bless {}, 'Splodge';
    my $hv   = clone $href;

    isa_ok  b($hv),             'B::HV',        'blessed HV cloned';
    is      blessed($hv),       'Splodge',      '...preserving class';
}

SKIP: {
    my $skip;
    BEGIN {
        eval q{
            use Hash::Util qw{
                lock_keys   unlock_keys
                lock_value  unlock_value
            };
        };
    }
    defined &lock_keys or skip 'no restricted hashes', $skip;

    {
        BEGIN { $skip += 8 }

        my %hash = qw/a b c d/;
        lock_keys(%hash, qw/a c e/);
        my $hv   = clone \%hash;

        is  join(':', sort keys %$hv),
                                    'a:c',  'locked HV retains keys';
        ok  !exists( $hv->{e} ),            'exists still works';
        ok  eval { $hv->{e} = 1 },          'permitted key';
        ok  !eval { $hv->{f} = 1 },         'forbidden key';
        
        delete $hv->{a};
        ok  !exists( $hv->{a} ),            'delete still works';

        unlock_keys(%$hv);
        ok  eval { $hv->{f} = 1 },          'can be unlocked';
        ok  exists( $hv->{f} ),             '...and insert now works';
        ok  !eval { $hash{f} = 1 },         '...but parent is still locked';
    }

    {
        BEGIN { $skip += 5 }

        my %hash = qw/a b c d/;
        lock_keys(%hash);
        lock_value(%hash, 'a');
        my $hv   = clone \%hash;

        is  $hv->{a},       'b',            'locked value is retained';
        ok  !eval { $hv->{a} = 1 },         '...but cannot be changed';

        unlock_value(%$hv, 'a');
        ok  eval { $hv->{a} = 1 },          'can be unlocked';
        is  $hv->{a},       1,              '...and can now be changed';
        ok  !eval { $hash{a} = 1 },         '...but parent is still locked';
    }

    BEGIN { $tests += $skip }
}

BEGIN { plan tests => $tests }
