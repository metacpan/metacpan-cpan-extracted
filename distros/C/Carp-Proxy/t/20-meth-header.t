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
    # Our goal here is to override Carp::Proxy's header() method by
    # sub-classing.  The override should produce a section header that
    # looks like
    #
    #    '>> ::: TITLE :::'     instead of      '  *** title ***'
    #
    # We will be throwing exceptions to verify the overridden format.
    #-----
    sub header {
        my( $self, $title ) = @_;

        my $line
            = ('>' x $self->header_indent)
            . '::: '
            . uc( $title )
            . " :::\n"
            ;

        return $line;
    }
    no Moose;
    __PACKAGE__->meta->make_immutable;
}

package main;

use Carp::Proxy;
BEGIN{
    Derived->import( fatal1 => {} );
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
    throws_ok{ fatal 'handler' }
        qr{
             ^
             \Q  *** Description ***\E  \r? \n
          }xm,
        'header() correctly incorporates (default) section_title';

    #-----
    # Now verify that when we provide our own title that it usurps the
    # default section title of 'Description'.
    #-----
    throws_ok{ fatal 'handler', 'my title' }
        qr{
             ^
             \Q  *** my title ***\E  \r? \n
          }xm,
        'header() correctly incorporates supplied title';

    #-----
    # Our final test of the builtin header() is that it should not issue
    # any header at all if the title is supplied (defined), but empty.
    #-----
    throws_ok{ fatal 'handler', '' }
        qr{
             \n [~]+  \r? \n                   # The last line in the banner
             \Q    section content\E  \r? \n
          }xm,
        'header() correctly incorporates supplied title';

    #-----
    # This time, instead of invoking 'fatal' we invoke 'fatal1' which
    # is a Proxy from a sub-class that overrides header().
    #-----
    throws_ok{ fatal1 'handler', 'Whatever' }
        qr{
              \Q>>::: WHATEVER :::\E  \r? \n
          }xm,
        'Subclassed header() overrides base';
}
