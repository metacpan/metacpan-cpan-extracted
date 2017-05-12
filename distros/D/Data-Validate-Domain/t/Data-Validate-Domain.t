use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8;

use Data::Validate::Domain;

{
    my @good = qw(
        www
        w-w
        neely
        com
        COM
        128
    );

    for my $l (@good) {
        my $disp = _display($l);
        is( is_domain_label($l), $l, qq{$disp is a valid domain label} );
    }

    my @bad = (
        undef,
        q{},
        '-bob',
        "bengali-\x{09ea}",
        ( 'x' x 70 ),
        "example\n",
    );

    for my $l (@bad) {
        my $disp = _display($l);
        ok( !is_domain_label($l), qq{$disp is not a valid domain label} );
    }
}

{
    my @good = qw(
        www.neely.cx
        www.neely.cx.
        neely.cx
        neely.cx.
        test-neely.cx
        aa.com
        A-A.com
        co.uk
        domain.com
        a.domain.co
        foo--bar.com
        xn--froschgrn-x9a.com
        rebecca.blackfriday
    );

    for my $d (@good) {
        my $disp = _display($d);
        is( is_domain($d), $d, qq{$disp is a valid domain} );
    }

    my @bad = (
        undef,
        q{},
        qw(
            www.neely.cx...
            www.neely.lkj
            216.17.184.1
            test_neely.cx
            .neely.cx
            -www.neely.cx
            abc
            256.0.0.0
            _.com
            *.some.com
            s!ome.com
            domain.com/
            /more.com
            a
            .
            com.
            com
            net
            uk
            neely
            ),
        "bengali-\x{09ea}.com",
    );

    for my $d (@bad) {
        my $disp = _display($d);
        ok( !is_domain($d), qq{$disp is not a valid domain} );
    }

    ok(
        !is_domain( ( 'x' x 280 ) . '.com' ),
        '280 characters is not a valid domain'
    );
}

{
    my @good = qw(
        aa.com
        aa.com.
        aa.bb
        aa
    );

    for my $h (@good) {
        my $disp = _display($h);
        is( is_hostname($h), $h, qq{$disp is a valid hostname} );
    }

    my @bad = (
        undef,
        q{},
        'x' x 256,
        '_foo.bar',
        "bengali-\x{09ea}.foo",
    );

    for my $h (@bad) {
        my $disp = _display($h);
        ok( !is_hostname($h), qq{$disp is not a valid hostname} );
    }
}

#Some additional tests for options
is(
    is_domain( 'domain.invalidtld', { domain_disable_tld_validation => 1 } ),
    'domain.invalidtld',
    'domain_disable_tld_validation disables TLD validation'
);

is(
    is_domain( 'myhost.neely', { domain_private_tld => { 'neely' => 1 } } ),
    'myhost.neely',
    'is_domain myhost.neely w/domain_private_tld option'
);
ok( !is_domain('myhost.neely'), 'is_domain myhost.neely' );
is(
    is_domain( 'com', { domain_allow_single_label => 1 } ),
    'com',
    'is_domain com w/domain_allow_single_label option'
);
is(
    is_domain(
        'neely',
        {
            domain_allow_single_label => 1,
            domain_private_tld        => { 'neely' => 1 }
        }
    ),
    'neely',
    'is_domain neely w/domain_private_tld  and domain_allow_single_label option'
);

is(
    is_hostname( '_spf', { domain_allow_underscore => 1 } ),
    '_spf',
    'is_hostname("_spf", {domain_allow_underscore = 1}'
);

#precompiled regex format
is(
    is_domain( 'myhost.neely', { domain_private_tld => qr/^neely$/ } ),
    'myhost.neely',
    'is_domain myhost.neely w/domain_private_tld option - precompiled regex'
);
ok(
    !is_domain( 'myhost.neely', { domain_private_tld => qr/^intra$/ } ),
    'is_domain myhost.neely w/domain_private_tld option - precompiled regex looking for intra'
);

my $obj = Data::Validate::Domain->new();
is( $obj->is_domain('co.uk'), 'co.uk', '$obj->is_domain co.uk' );

my $private_tld_obj = Data::Validate::Domain->new(
    domain_private_tld => {
        neely   => 1,
        neely72 => 1,
    },
);
is(
    $private_tld_obj->is_domain('myhost.neely'),
    'myhost.neely',
    '$private_tld_obj->is_domain myhost.neely'
);
is(
    $private_tld_obj->is_domain('myhost.neely72'),
    'myhost.neely72',
    '$private_tld_obj->is_domain myhost.neely72'
);
ok(
    !$private_tld_obj->is_domain('myhost.intra'),
    '$private_tld_obj->is_domain myhost.intra'
);
ok(
    !$private_tld_obj->is_domain('neely'),
    '$private_tld_obj->is_domain neely'
);

my $private_single_label_tld_obj = Data::Validate::Domain->new(
    domain_allow_single_label => 1,
    domain_private_tld        => {
        neely => 1,
    },
);

is(
    $private_single_label_tld_obj->is_domain('neely'),
    'neely',
    '$private_single_label_tld_obj->is_domain neely'
);
is(
    $private_single_label_tld_obj->is_domain('NEELY'),
    'NEELY',
    '$private_single_label_tld_obj->is_domain NEELY'
);
is(
    $private_single_label_tld_obj->is_domain('neely.cx'),
    'neely.cx',
    '$private_single_label_tld_obj->is_domain neely.cx'
);

#precompiled regex format
my $private_tld_obj2 = Data::Validate::Domain->new(
    domain_private_tld => qr/^(?:neely|neely72)$/,
);
is(
    $private_tld_obj2->is_domain('myhost.neely'),
    'myhost.neely',
    '$private_tld_obj2->is_domain myhost.neely'
);
is(
    $private_tld_obj2->is_domain('myhost.neely72'),
    'myhost.neely72',
    '$private_tld_obj2->is_domain myhost.neely72'
);
ok(
    !$private_tld_obj2->is_domain('myhost.intra'),
    '$private_tld_obj2->is_domain myhost.intra'
);
ok(
    !$private_tld_obj2->is_domain('neely'),
    '$private_tld_obj2->is_domain neely'
);

my $allow_underscore_obj = Data::Validate::Domain->new(
    domain_allow_underscore => 1,
);
is(
    $allow_underscore_obj->is_domain('_spf.neely.cx'),
    '_spf.neely.cx',
    '$allow_underscore_obj->is_domain _spf.neely.cx'
);
is(
    $allow_underscore_obj->is_domain('_sip._tcp.neely.cx'),
    '_sip._tcp.neely.cx',
    '$allow_underscore_obj->is_domain _sip._tcp.neely.cx'
);
is(
    $allow_underscore_obj->is_hostname('_spf'),
    '_spf',
    '$allow_underscore_obj->is_domain _spf'
);

done_testing();

sub _display {
    my $v = shift;

    return '<undef>' unless defined $v;
    return q{""} unless length $v;

    if ( length $v > 30 ) {
        return
              q{"}
            . substr( $v, 0, 30 )
            . q{ ... (}
            . ( length $v )
            . q{ chars)"};
    }

    $v =~ s/\n/\\n/;

    return qq{"$v"};
}
