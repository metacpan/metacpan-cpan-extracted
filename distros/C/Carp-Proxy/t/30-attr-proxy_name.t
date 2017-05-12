# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

BEGIN{
    package Derived;
    use Moose;
    extends 'Carp::Proxy';

    #-----
    # Our goal here is to override Carp::Proxy's _build_proxy_name()
    # builder method in a subclass.
    #-----
    sub _build_proxy_name { return 'error'; }

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

package main;

BEGIN{
    Derived->import();
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $title ) = @_;

    $cp->filled( 'section content', $title );
    return;
}

sub main {

    #-----
    # As a baseline, we verify that the builtin header() does what we
    # expect, i.e. a header_indent of two spaces, three stars, the default
    # section_title of 'Description', surrounded by spaces and three more
    # stars.
    #-----
    throws_ok{ error 'handler' }
        qr{
             ^
             \Q  *** Description ***\E  \r? \n
             \Q    section content\E
          }xm,
        'proxy_name builder overridable in subclass';
}
