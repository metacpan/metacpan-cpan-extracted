# these tests require a specific /etc/hosts.allow file in order to work
# unless by some miracle you configure your /etc/hosts.allow just like
# mine, no tests will be executed by this script.

# if you really want to use these tests, copy t/hosts.allow to
# /etc/hosts.allow (or wherever your libwrap expects to find hosts.allow),
# change $hosts_allow if necessary and re-run the test suite.

BEGIN {

    my $hosts_allow  = '/etc/hosts.allow';
    my $expected_md5 = 'foo';
    
    eval {
        eval "use Digest::MD5";
        die if $@;

        die unless( -f $hosts_allow && -r _ );

        open(HOSTSALLOW, $hosts_allow);
        my $digest = Digest::MD5->new->addfile(*HOSTSALLOW);
        close(HOSTSALLOW);

        die unless(
            $digest->hexdigest eq '8bc3fb6dcb07f81c85a213a475b2f3f5'
        );
    };
    if( $@ ) {
        use Test::More skip_all => 'maintainer tests';
    }
}

use Test::More tests => 14;
use Test::Exception;

use_ok('Authen::Libwrap');
Authen::Libwrap->import(':all');

lives_and {
    is( hosts_ctl('foo', STRING_UNKNOWN(), '10.1.1.1'), 1);
} '10.1.1.1 can access foo';

lives_and {
    is( hosts_ctl('foo', STRING_UNKNOWN(), '10.1.1.2'), undef);
} '10.1.1.2 cannot access foo';

lives_and {
    is( hosts_ctl('foo', 'foo.com', STRING_UNKNOWN()), 1);
} 'foo.com can access foo';

lives_and {
    is( hosts_ctl('foo', 'bar.com', STRING_UNKNOWN()), undef);
} 'bar.com cannot access foo';

lives_and {
    is( hosts_ctl('bar', 'foo.com', STRING_UNKNOWN()), 1);
} 'foo.com can access bar';

lives_and {
    is( hosts_ctl('bar', 'bar.com', STRING_UNKNOWN()), undef);
} 'bar.com cannot access bar';

lives_and {
    is( hosts_ctl('baz', 'localhost', '127.0.0.1'), 1 );
} 'localhost can access baz';

lives_and {
    is( hosts_ctl('quux', STRING_UNKNOWN(), '10.1.1.1'), 1);
} '10.1.1.1 can access quux';

lives_and {
    is( hosts_ctl('quux', STRING_UNKNOWN(), '10.2.1.1'), undef);
} '10.2.1.1 cannot access quux';

lives_and {
    is( hosts_ctl('quux', STRING_UNKNOWN(), '10.3.1.1'), 1);
} '10.3.1.1 can access quux';

lives_and {
    is( hosts_ctl('gzonk', 'me', '1.1.1.1'), 1);
} 'known host can access gzonk';

SKIP: {

    skip "known/unknown doesn't seem be working", 2;
    
lives_and {
    is( hosts_ctl('gzonk', STRING_UNKNOWN(), STRING_UNKNOWN(), 'me'), 1);
} 'known user can access gzonk';

lives_and {
    is( hosts_ctl('wibble', 'me', '1.1.1.1', STRING_UNKNOWN()), undef);
} 'unknown user cannot access wibble';

};

#
# EOF

