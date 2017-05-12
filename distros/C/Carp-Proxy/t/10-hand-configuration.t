# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English;
use Test::More;
use Test::Exception;

use Carp::Proxy;

main();

#----------------------------------------------------------------------
# Our intent here is to verify functionality of the closure hash that is
# created when the proxy is defined.
#
# The hash created by 'use Carp::Proxy' should only contain things like
# the proxy_name (fatal), proxy_package (main, as that is the active
# package in this file) and proxy_filename (t/01-configuration.t -
# whatever the name of this test file is).
#
# Next we create additional proxies, each with unique combinations of
# pre-defined attributes.
#
# We then check that the various configuration hashes return the
# expected contents.
#
# Finally we test their ability to retain changes.
#----------------------------------------------------------------------

sub main {

    #----- Verifies the proxy built by 'use'
    verify_proxy_configuration( 'fatal', {} );

    my %pconfs =
        (
         fatal1          =>
         {
          as_yaml        => 1,
         },

         fatal2          =>
         {
          context        => 'die',
          disposition    => 'warn',
         },

         fatal3          =>
         {
          header_indent  => 3,
          body_indent    => 4,
          columns        => 88,
          maintainer     => 'whoever',
          handler_prefix => '_f_',
          exit_code      => 14,
          banner_title   => 'oops',
         },
        );

    #----- Build the extra proxies all at once
    Carp::Proxy->import( %pconfs );

    #----- verify the expected configurations
    while( my( $proxy, $settings ) = each %pconfs ) {

        verify_proxy_configuration( $proxy, $settings );
    }

    #-----
    # Change a few things.  These tests verify that the closure hashes
    # are malleable, and independent.
    #-----
    fatal1( '*configuration*' )->{as_yaml} = 0;
    verify_proxy_configuration( 'fatal1', { as_yaml => 0 });

    fatal3( '*configuration*' )->{columns} = 93;
    verify_proxy_configuration( 'fatal3', { %{ $pconfs{fatal3}},
                                            columns => 93 });
    done_testing();
}

sub verify_proxy_configuration {
    my( $proxy, $augmentation ) = @_;

    my $conf;

    #----- Invoke the proxy with a '*configuration*' handler
    lives_ok{

        eval "\$conf = $proxy '*configuration*'";

    } "The $proxy *configuration* handler returns without throwing";

    isa_ok $conf, 'HASH';

    my %expected =
        (
         proxy_filename => __FILE__,
         proxy_name     => $proxy,
         proxy_package  => __PACKAGE__,
         fq_proxy_name  => __PACKAGE__ . '::' . $proxy,
         %{ $augmentation },
        );

    while(my( $key, $value ) = each %expected ) {

        ok exists( $conf->{ $key }),
            "$proxy configuration hash has key '$key'";

        is $conf->{ $key }, $value,
            "$proxy configuration '$key' has expected value";
    }

    my @unexpected =
        grep{ not exists $expected{ $_ }}
        keys %{ $conf };

    ok not( @unexpected ), "$proxy configuration has no extraneous keys"
        or diag "Unexpected '$proxy' keys: @unexpected";

    return;
}
