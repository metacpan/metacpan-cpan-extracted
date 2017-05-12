# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

use Carp::Proxy;

main();
done_testing();

#----------------------------------------------------------------------

sub main {

    throws_ok{ fatal '*internal_error*' }
        qr{
              \A
              [~]+                             \r? \n
              \QFatal << *internal error* >>\E \r? \n
              [~]+                             \r? \n
              \Q  *** Stacktrace ***\E         \r? \n
          }x,
        '*internal_error* with no args';

    throws_ok{ fatal '*internal_error*', 'Your message', 'here' }
        qr{
                                               \r? \n
              \Q  *** Description ***\E        \r? \n
              \Q    Your message here\E        \r? \n
                                               \r? \n
              \Q  *** Stacktrace ***\E         \r? \n
          }x,
        '*internal_error* with concatenated args';

    {
        local $SIG{__WARN__} = sub{ fatal '*internal_error*', @_ };

        throws_ok
            {
                my $abc = undef;
                my $def = 4 + $abc;
            }
            qr{
                  \Q  *** Description ***\E        \r? \n
                  \Q    Use of uninitialized\E     .+?
                  \Q  *** Stacktrace ***\E         \r? \n
              }xs,
            'Promoting warnings example from docs';
    }

    {
        local $SIG{__DIE__} = sub{ fatal '*internal_error*', @_ };

        throws_ok
            {
                my $abc = 0;
                my $def = sqrt( $abc - 1 );
            }
            qr{
                  \Q  *** Description ***\E        \r? \n
                  \Q    Can't take sqrt\E          .+?
                  \Q  *** Stacktrace ***\E         \r? \n
              }xs,
            'Promoting errors to exceptions example from docs';
    }
}
