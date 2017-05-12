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
    # Our goal here is to prove that we can override Carp::Proxy's
    # decipher_child_error() by sub-classing.
    #-----
    sub decipher_child_error {
        my( $self ) = @_;

        $self->fixed('decoded');
        return;
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

    $cp->decipher_child_error;
    return;
}

sub main {

    #-----
    # An exit code of 0 is documented to mean success
    #-----
    throws_ok{ $CHILD_ERROR = 0; fatal 'handler'; }
        qr{
             ^
             \Q  *** Process Succeeded ***\E                              \r? \n
             \Q    The child process completed normally (exit code 0).\E  \r? \n
          }xm,
        'decipher_child_error() correctly handles exit code 0';

    #-----
    # An exit code of 1..127 is documented to imply death by signal.
    # An exit code of 128 | (1 .. 127) is also documented to imply death
    # by signal, only this time it is accompanied with a core dump.
    #-----
    for my $sig ( 1 .. 127 ) {

        throws_ok{ $CHILD_ERROR = $sig; fatal 'handler'; }
            qr{
                  ^
                  \Q  *** Process terminated by signal ***\E        \r? \n
                  \Q    The child process was terminated by \E
                    (?:
                        \w+ [ ] \( signal [ ] $sig \)
                    |
                        signal [ ] $sig
                    )
                    \. \s* $
          }xm,
        "decipher_child_error() correctly handles exit code $sig";

        throws_ok{ $CHILD_ERROR = 128 | $sig; fatal 'handler'; }
            qr{
                  ^
                  \Q  *** Process terminated by signal ***\E  \r? \n
                  \Q    The child process was terminated by \E
                    (?:
                        \w+ [ ] \( signal [ ] $sig \)
                    |
                        signal [ ] $sig
                    )
                    \. \s+ There \s+ was \s+ a \s+ core \s+ dump [.] \s* $
              }xm,
              "decipher_child_error() correctly handles exit code $sig + 128";
    }

    #-----
    #-----
    throws_ok{ $CHILD_ERROR = 14<<8; fatal 'handler'; }
        qr{
             ^
             \Q  *** Process returns failing status ***\E             \r? \n
             \Q    The child process terminated with exit code 14.\E  \r? \n
          }xm,
        'decipher_child_error() correctly handles exit code 14';

    #-----
    # This time, instead of invoking 'fatal' we invoke 'fatal1' which
    # is a Proxy from a sub-class that overrides identifier_presentation().
    # The handler name 'dummy' should expand into ' d u m m y '.
    #-----
    throws_ok{ fatal1 'handler' }
        qr{
              ^
              \Q  *** Description ***\E  \r? \n
              \Q    decoded\E            \r? \n
          }xm,
        'Subclassed decipher_child_header() overrides base';
}
