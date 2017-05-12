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

    throws_ok
        {
            fatal '*assertion_failure*',
                'my excuse here',
                {
                 a => 1,
                 b => 2,
                }
        }
        qr{
              \QFatal << *assertion failure* >>\E   .+?
              \Qmy excuse here\E                    .+?
              \Q*** Salient State (YAML) ***\E      .+?
              \Qa: 1\E                              .+?
              \Qb: 2\E                              .+?
              \Q*** Stacktrace ***\E
          }xs,
        'Base *assertion_failure* with description and hashref';

    throws_ok{ fatal '*assertion_failure*' }
        qr{
              \Qprogram is corrupt.\E     (?: \r? \n)+
              \Q  *** Stacktrace ***\E
          }xs,
        '*assertion_failure* with undef description and no hashref';

    throws_ok{ fatal '*assertion_failure*', '' }
        qr{
              \Qprogram is corrupt.\E     (?: \r? \n)+
              \Q  *** Stacktrace ***\E
          }xs,
        '*assertion_failure* with empty description and no hashref';

    throws_ok{ fatal '*assertion_failure*', '', {} }
        qr{
              \Qprogram is corrupt.\E     (?: \r? \n)+
              \Q  *** Stacktrace ***\E
          }xs,
        '*assertion_failure* with empty description and empty hashref';

    return;
}
