
#  COPYRIGHT: © 2012 Peter Hallam
#    PODNAME: 50-properties.t
#    CREATED: Thu, 04 Oct 2012 05:37:57 UTC
#     AUTHOR: Peter Hallam <pragmatic@cpan.org>

use strict;
use warnings;
use v5.10;

use Test::More;
use Config::Any::Properties;

if ( !Config::Any::Properties->is_supported ) {
    plan skip_all => 'Properties format not supported';
}
else {
    plan tests => 4;
}

{
    my $config = Config::Any::Properties->load( 't/conf/conf.properties' );
    ok( $config );
    is( $config->{ name }, 'TestApp' );

}

# test invalid config
{
    my $file = 't/invalid/conf.properties';
    my $config = eval { Config::Any::Properties->load( $file ) };

    ok( !$config, 'config load failed' );
    ok( $@,       "error thrown ($@)" );
}

# vim:set ts=4 sw=4 et ft=perl:
