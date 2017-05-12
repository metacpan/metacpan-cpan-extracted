
use Test::More;

BEGIN
{
    if ( $^O !~ /^freebsd$/i ) {
        plan skip_all => 'Module only usable under FreeBSD operating system';
    }
    else {
        if ( $< ) {
            plan skip_all => 'Must be root to run tests';
        }
        else {
            plan tests => 7;
            use_ok('BSD::Jail::Object');
        }
    }
}

# jail identifier we'll do our tests on
my $jid;

# all methods, public and private
can_ok( 'BSD::Jail::Object', qw/
    new _init 
    jid ip hostname path
    attach jids

    sysctl_len _find_jail
    _find_jids _attach _create
/);

# create
my $j = BSD::Jail::Object->new({
        path => '/tmp',
        hostname => 'bsd-jail-object-tester',
        ip => '127.0.0.1'
});

is( ref $j, 'BSD::Jail::Object', 'Object namespace' );
is( $j->path, '/tmp', "path verify" );
is( $j->ip, '127.0.0.1', "ip verify" );
is( $j->hostname, 'bsd-jail-object-tester', "hostname verify" );
like( $j->jid, qr/^\d+$/, 'jid is integer (' . $j->jid . ')' );

# can't easily test attach()
        
# end of tests




