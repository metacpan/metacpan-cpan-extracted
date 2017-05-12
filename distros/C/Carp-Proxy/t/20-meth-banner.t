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
    # Here we are overridding Carp::Proxy::banner() with our own version.
    # We use '=' instead of '~' for the standout line.  We also do not
    # use identifier_presentation() to process the handler_name, we use
    # handler_name directly.
    #-----
    sub banner {
        my( $self ) = @_;
        my $columns = $self->columns;
        my $title   = $self->banner_title;

        my $banner
            = ('=' x $columns) . "\n"
            . $title . ' << ' . $self->handler_name . ' >>' . "\n"
            . ('=' x $columns) . "\n";

        return $banner;
    }

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

package main;

use Carp::Proxy ( fatal  => {},
                  fatal1 => { columns => 60 },
                  fatal2 => { banner_title => 'Error' },
                );

BEGIN{
    Derived->import( fatal3 => {} );
}

main();
done_testing();

#----------------------------------------------------------------------

sub main {

    #-----
    # Verify that the default column setting is 78 and the default
    # banner_title is 'Fatal'.  Also check that identifier_presentation()
    # transliterates '_' to ' ' in the handler name of
    # '*identifier_presentation*'
    #-----
    throws_ok{ fatal '*internal_error*' }
        qr{
              \A
              [~]{78}                           \r? \n
              \QFatal << *internal error* >>\E  \r? \n
              [~]{78}                           \r? \n
          }x,
        'Default attribute settings are observed in banner()';

    #-----
    # Here we verify that changes to columns, as defined for 'fatal1', are
    # reflected in the generated banner.
    #-----
    throws_ok{ fatal1 '*internal_error*' }
        qr{
              \A
              [~]{60}                           \r? \n
              \QFatal << *internal error* >>\E  \r? \n
              [~]{60}                           \r? \n
          }x,
        'Banner respects columns setting';

    #-----
    # Here we verify that changes to banner_title, as defined for 'fatal1',
    # are reflected in the generated banner.
    #-----
    throws_ok{ fatal2 '*internal_error*' }
        qr{
              \A
              [~]{78}                           \r? \n
              \QError << *internal error* >>\E  \r? \n
              [~]{78}                           \r? \n
          }x,
        'Banner respects banner_title setting';

    #-----
    # Here we verify that a derived class is able to override banner()
    # by changing the '~' standout character to '=', and inserting the
    # handler name directly, rather than using identifier_presentation().
    #-----
    throws_ok{ fatal3 '*internal_error*' }
        qr{
              \A
              [=]{78}                           \r? \n
              \QFatal << *internal_error* >>\E  \r? \n
              [=]{78}                           \r? \n
          }x,
        'Derived class override for banner()';
}
