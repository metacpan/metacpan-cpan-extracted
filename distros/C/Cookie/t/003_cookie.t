#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use vars qw( $DEBUG $CRYPTX_REQUIRED_VERSION );
    # 2021-11-01T08:12:10
    use Test::Time time => 1635754330;
    use DateTime;
    use DateTime::Format::Strptime;
    use Module::Generic::HeaderValue;
    our $CRYPTX_REQUIRED_VERSION = '0.074';
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Cookie' );
    require( "./t/env.pl" ) if( -e( "t/env.pl" ) );
};

use strict;
use warnings;

subtest 'methods' => sub
{
    my $c = Cookie->new;
    isa_ok( $c, 'Cookie' );

    # To generate this list:
    # perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$c, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Cookie.pm
    can_ok( $c, "init" );
    can_ok( $c, "algo" );
    can_ok( $c, "apply" );
    can_ok( $c, "as_hash" );
    can_ok( $c, "as_string" );
    can_ok( $c, "comment" );
    can_ok( $c, "commentURL" );
    can_ok( $c, "decrypt" );
    can_ok( $c, "discard" );
    can_ok( $c, "domain" );
    can_ok( $c, "elapse" );
    can_ok( $c, "encrypt" );
    can_ok( $c, "expires" );
    can_ok( $c, "fields" );
    can_ok( $c, "host" );
    can_ok( $c, "http_only" );
    can_ok( $c, "httponly" );
    can_ok( $c, "implicit" );
    can_ok( $c, "initialisation_vector" );
    can_ok( $c, "is_expired" );
    can_ok( $c, "is_session" );
    can_ok( $c, "is_tainted" );
    can_ok( $c, "is_valid" );
    can_ok( $c, "iv" );
    can_ok( $c, "key" );
    can_ok( $c, "match_host" );
    can_ok( $c, "max_age" );
    can_ok( $c, "maxage" );
    can_ok( $c, "name" );
    can_ok( $c, "path" );
    can_ok( $c, "port" );
    can_ok( $c, "reset" );
    can_ok( $c, "same_as" );
    can_ok( $c, "same_site" );
    can_ok( $c, "samesite" );
    can_ok( $c, "secure" );
    can_ok( $c, "sign" );
    can_ok( $c, "uri" );
    can_ok( $c, "value" );
    can_ok( $c, "version" );
};

subtest 'cookie make' => sub
{
    my $now = time();
    my @tests = (
        [{ name => 'foo', value => 'val' }, 'foo=val' ],
        [{ name => 'foo', value => 'foo bar baz' }, 'foo=foo%20bar%20baz' ],
        [{ name => 'foo', value => 'val', expires => undef }, 'foo=val' ],
        [{ name => 'foo', value => 'val', path => '/' }, 'foo=val; Path=/' ],
        [{ name => 'foo', value => 'val', path => '/', secure => 1, http_only => 0 }, 'foo=val; Path=/; Secure' ],
        [{ name => 'foo', value => 'val', path => '/', secure => 0, http_only => 1 }, 'foo=val; Path=/; HttpOnly' ],
        [{ name => 'foo', value => 'val', expires => 'now' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 1, hour => 8, minute => 12, second => 10 } ],
        [{ name => 'foo', value => 'val', expires => $now + 24*60*60 }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 2, hour => 8, minute => 12, second => 10, time_zone => 'UTC' } ],
        [{ name => 'foo', value => 'val', expires => '1s' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 1, hour => 8, minute => 12, second => 11 } ],
        [{ name => 'foo', value => 'val', expires => '+10' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 1, hour => 8, minute => 12, second => 20 } ],
        [{ name => 'foo', value => 'val', expires => '+1m' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 1, hour => 8, minute => 13, second => 10 } ],
        [{ name => 'foo', value => 'val', expires => '+1h' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 1, hour => 9, minute => 12, second => 10 } ],
        [{ name => 'foo', value => 'val', expires => '+1d' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 2, hour => 8, minute => 12, second => 10 } ],
        [{ name => 'foo', value => 'val', expires => '-1d' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 10, day => 31, hour => 8, minute => 12, second => 10 } ],
        [{ name => 'foo', value => 'val', expires => '+1M' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 12, day => 1, hour => 8, minute => 12, second => 10 } ],
        [{ name => 'foo', value => 'val', expires => '+1y' }, 'foo=val; Expires=_DATETIME_', { year => 2022, month => 11, day => 1, hour => 8, minute => 12, second => 10 } ],
        [{ name => 'foo', value => 'val', expires => '0' }, 'foo=val; Expires=_DATETIME_', { year => 1970, month => 1, day => 1, hour => 0, minute => 0, second => 0 } ],
        [{ name => 'foo', value => 'val', expires => '-1' }, 'foo=val; Expires=_DATETIME_', { year => 2021, month => 11, day => 1, hour => 8, minute => 12, second => 9 } ],
        [{ name => 'foo', value => 'val', expires => 'foo' }, undef ],
        [{ name => 'foo', value => 'val', max_age => '1000' }, 'foo=val; Max-Age=1000' ],
        [{ name => 'foo', value => 'val', max_age => '0' }, 'foo=val; Max-Age=0' ],
        [{ name => 'foo', value => 'val', same_site => 'lax' }, 'foo=val; SameSite=Lax' ],
        [{ name => 'foo', value => 'val', same_site => 'strict' }, 'foo=val; SameSite=Strict' ],
        [{ name => 'foo', value => 'val', same_site => 'none' }, 'foo=val; SameSite=None' ],
        [{ name => 'foo', value => 'val', same_site => 'invalid value' }, 'foo=val' ],
    );

    my $fmt = DateTime::Format::Strptime->new(
        pattern => '%a, %d %b %Y %H:%M:%S GMT',
        locale  => 'en_GB',
        time_zone => 'GMT',
    );
    foreach my $test ( @tests )
    {
        # $test->[0]->{debug} = $DEBUG;
        my $c = Cookie->new( $test->[0] );
        if( !defined( $c ) )
        {
            diag( "Error create cookie object: ", Cookie->error );
            if( !defined( $test->[1] ) )
            {
                pass();
            }
            else
            {
                fail();
            }
            next;
        }
        if( scalar( @$test ) == 3 )
        {
            my $def = $test->[2];
            $def->{time_zone} = 'GMT' unless( $def->{time_zone} );
            my $d = DateTime->new( %$def );
            $d->set_time_zone( 'GMT' );
            $d->set_formatter( $fmt );
            my $datestr = "$d";
            $test->[1] =~ s/_DATETIME_/$datestr/g;
        }
        is( $c->as_string, $test->[1] );
    }
};

subtest 'encrypted cookie' => sub
{
    SKIP:
    {
        eval( "use Crypt::Cipher ${CRYPTX_REQUIRED_VERSION}" );
        my $algos = [qw( AES Anubis Blowfish CAST5 Camellia DES DES_EDE KASUMI Khazad MULTI2 Noekeon RC2 RC5 RC6 SAFERP SAFER_K128 SAFER_K64 SAFER_SK128 SAFER_SK64 SEED Skipjack Twofish XTEA IDEA Serpent )];
        if( $@ )
        {
            skip( "Crypt::Cipher is not installed on your system", ( scalar( @$algos ) * 4 ) );
        }
        
        eval( "use Bytes::Random::Secure" );
        if( $@ )
        {
            skip( "Bytes::Random::Secure is not installed on your system", ( scalar( @$algos ) * 4 ) );
        }
        
        my $secret_value = 'My big secret';
        foreach my $algo ( @$algos )
        {
            diag( "Testing cookie encryption with algorithm \"$algo\"." ) if( $DEBUG );
            my $class = "Crypt::Cipher::${algo}";
            my $c = Cookie->new(
                name      => 'session',
                value     => $secret_value,
                path      => '/',
                secure    => 1,
                http_only => 1,
                same_site => 'Lax',
                # key       => Bytes::Random::Secure::random_bytes(32),
                algo      => $algo,
                encrypt   => 1,
                debug     => $DEBUG,
            );
            isa_ok( $c, 'Cookie', 'cookie created' );
            SKIP:
            {
                if( !defined( $c ) )
                {
                    diag( "Error creating cookie: ", Cookie->error ) if( $DEBUG );
                    skip( "Cookie create failed for algorithm \"$algo\".", 1 );
                }
                if( !$c->_load_class( $class ) )
                {
                    fail( "Load class $class" );
                    skip( "Unable to load encryption class $class", 1 );
                }
                my $key_len = $class->keysize;
                $c->key( Bytes::Random::Secure::random_bytes( $key_len ) );
                my $c_str = $c->as_string;
                diag( "Cookie is: $c_str" ) if( $DEBUG );
                ok( defined( $c_str ) && length( $c_str ), 'as_string' );
                if( !defined( $c_str ) )
                {
                    diag( "Error stringifying cookie: ", $c->error ) if( $DEBUG );
                    skip( "Cookie as_string error", 1 );
                }
                my $hv = Module::Generic::HeaderValue->new_from_header( "$c", decode => 1, debug => $DEBUG );
                isa_ok( $hv, 'Module::Generic::HeaderValue', "parsing cookie" );
                if( !defined( $hv ) )
                {
                    diag( "Error with header value parsing: ", Module::Generic::HeaderValue->error ) if( $DEBUG );
                    skip( "Error parsing '$c'", 1 );
                }
                diag( "Encrypted value is '", $hv->value->second, "'" ) if( $DEBUG );
                my $c2 = $c->clone;
                $c2->value( $hv->value->second );
                my $value = $c2->decrypt;
                diag( "Error decrypting value: ", $c2->error ) if( !defined( $value ) && $DEBUG );
                diag( "Uncrypted value is '$value'" ) if( $DEBUG );
                is( "$value", $secret_value, "encrypted cookie with $algo" );
            };
        }
    };
    
    # Cookie signature
};

done_testing();

__END__

