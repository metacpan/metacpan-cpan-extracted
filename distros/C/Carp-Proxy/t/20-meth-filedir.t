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
    # Our goal here is to override Carp::Proxy's filename() and directory()
    # methods by sub-classing.
    #-----

    sub filename {
        my( $self, $file ) = @_;

        $self->filled( "FILE: $file", 'file' );
    }

    sub directory {
        my( $self, $dir ) = @_;

        $self->filled( "DIRECTORY: $dir", 'dir' );
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

sub fhandler {
    my( $cp, $entry, $title ) = @_;

    $cp->filename( $entry, $title );
    return;
}

sub dhandler {
    my( $cp, $entry, $title ) = @_;

    $cp->directory( $entry, $title );
    return;
}

sub main {

    #-----
    # filename() uses Cwd::abs_path() to give us a full path to the
    # file.  If abs_path() cannot resolve the absolute path we simply
    # echo the incoming filename.  This test depends on
    # /nonexistent/unique being a fictious path.
    #-----
    throws_ok{ fatal 'fhandler', '/nonexistent/unique' }
        qr{
              ^
              \Q  *** Filename ***\E       \r? \n
              \Q    /nonexistent/unique\E  \r? \n
          }xm,
        'filename() of a ficticious file';

    #-----
    # dirname, like filename(), uses Cwd::abs_path() to give us a full
    # path to the supplied directory.  If abs_path() cannot resolve the
    # absolute path we simply echo the incoming directory.  This test
    # depends on /nonexistent/unique being a fictious path.
    #-----
    throws_ok{ fatal 'dhandler', '/nonexistent/unique' }
        qr{
              \Q*** Directory ***\E        \r? \n
              \Q    /nonexistent/unique\E  \r? \n
          }xm,
        'directory() of a ficticious directory';

    #-----
    # ./Makefile.PL ought to be a real file, so filename()/abs_path()
    # ought to expand it.
    #-----
    throws_ok{ fatal 'fhandler', 'Makefile.PL', 'real' }
        qr{
              ^
              \Q  *** real ***\E              \r? \n
              [ ]{4} .* Carp-Proxy .* Makefile.PL \r? \n
          }xm,
        'filename() on ./Makefile.PL';

    #-----
    # ./t ought to be a real directory, so directory()/abs_path()
    # ought to expand it.
    #-----
    throws_ok{ fatal 'dhandler', 't', 'real' }
        qr{
              \Q  *** real ***\E   \r? \n
              [ ]{4} .* Carp-Proxy .* t \r? \n
          }xm,
        'directory() on ./t';

    #-----
    # This time, instead of invoking 'fatal' we invoke 'fatal1' which
    # is a Proxy from a sub-class that overrides header().
    #-----
    throws_ok{ fatal1 'fhandler', 'abc' }
        qr{
              ^
              \Q  *** file ***\E  \r? \n
              [ ]{4} FILE: .* abc \r? \n
          }xm,
        'subclassed filename()';

    throws_ok{ fatal1 'dhandler', 'abc' }
        qr{
              \Q  *** dir ***\E        \r? \n
              [ ]{4} DIRECTORY: .* abc \r? \n
          }xm,
        'subclassed directory()';
}
