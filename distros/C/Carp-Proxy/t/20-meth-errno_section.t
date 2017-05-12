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
    # Our goal here is to override Carp::Proxy's errno_section() method
    # by sub-classing.
    #-----

    sub errno_section {
        my( $self, $title ) = @_;

        $self->filled( 'errno: ' . $self->string_errno );
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

    $cp->errno_section( $title );
    return;
}

sub cheater {
    my( $cp, $poke ) = @_;

    $cp->{string_errno} = $poke;

    $cp->errno_section;

    return;
}

sub main {

    #-----
    # You cannot assign a string to $ERRNO.  However, you can assign a number
    # to $ERRNO and Perl will map this to an OS-specific message.  We try the
    # first 100 numbers looking for anything that yields some kind of string
    #-----
    my $msg;
    my $num = 0;
    while( $num < 100 ) {

        $ERRNO = $num;
        $msg = "" . $ERRNO;
        last
            if length $msg;

        ++$num;
    }

    #-----
    # Of course it is possible that some platforms don't work like Unix.
    # If, after trying the first 100 number there is no joy then we give
    # up.
    #-----
    SKIP: {

        skip 'Nonconforming ERRNO implementation', 3
            if not length $msg;

        #-----
        # Use whatever message string-context $ERRNO gave us to construct
        # a regular expression that will match the diagnostic produced
        # by the body of the error_section() output.
        #-----
        $msg =~ s/ / [ ] /g;

        $ERRNO = $num;
        throws_ok{ fatal 'handler'; }
            qr{
                  ^
                  (?:
                      \Q  *** System Diagnostic ***\E  \r? \n
                      [ ]{4} $msg \s+
                  )?
                  \Q  *** Stacktrace ***\E  \r? \n
              }xm,
            'errno_section without title';

        $ERRNO = $num;
        throws_ok{ fatal 'handler', 'Optional Title'; }
            qr{
                  ^
                  (?:
                      \Q  *** Optional Title ***\E  \r? \n
                      [ ]{4} $msg \s+
                  )?
                  \Q  *** Stacktrace ***\E  \r? \n
              }xm,
            'errno_section with title';

        $ERRNO = $num;
        throws_ok{ fatal1 'handler'; }
            qr{
                  ^
                  (?:
                      \Q  *** Description ***\E  \r? \n
                      [ ]{4} errno: [ ] $msg \s+
                  )?
                  \Q  *** Stacktrace ***\E  \r? \n
              }xm,
            'Sub-class errno_section() override';
    }

    foreach my $cheat ( '', undef ) {

        throws_ok{ fatal 'cheater', $cheat }
            qr{
                  \A
                  ~+ \r? \n
                  \QFatal << cheater >>\E \r? \n
                  ~+ \r? \n
                  \Q  *** Stacktrace ***\E
              }x,
            'Empty or undef string_errno omit section';
    }

    return;
}
