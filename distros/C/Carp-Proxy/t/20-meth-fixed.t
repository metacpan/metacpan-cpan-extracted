# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English qw( -no_match_vars );

use Test::More;
use Test::Exception;

use Carp::Proxy;

my $banner_rex =
    qr{
          ~{78}                                             \r? \n
          Fatal [ ] << [ ] handle (?: r | [ ] title) [ ] >> \r? \n
          ~{78}                                             \r? \n
      }x;

main();
done_testing();

#-----

sub handler {
    my( $cp, $paragraphs ) = @_;

    $cp->fixed( $paragraphs, '' );
    return;
}

sub handle_title {
    my( $cp, $title ) = @_;

    $cp->fixed( 'body', $title );
    return;
}

sub main {

    verify_leading_ws();
    verify_header();
    return;
}

sub verify_header {

    throws_ok{ fatal 'handle_title', undef }
        qr{
              \A
              $banner_rex
              \Q  *** Description ***\E  \r? \n
              \Q    body\E
          }x,
        'Undef title maps to section title (Description)';

    throws_ok{ fatal 'handle_title', '' }
        qr{
              \A
              $banner_rex
              \Q    body\E
          }x,
        'Empty title defeats header generation';

    throws_ok{ fatal 'handle_title', 'Alternate' }
        qr{
              \A
              $banner_rex
              \Q  *** Alternate ***\E  \r? \n
              \Q    body\E             \r? \n
          }x,
        'Explicit title is inserted in header';

    return;
}

sub verify_leading_ws {

    throws_ok{ fatal 'handler', <<"EOF" }
last\tfirst\tphone
---------------------------------------
Jones\tBo\t123-4567
Pez\tAlice\t890-1234
EOF
        qr{
              \A
              $banner_rex
              \Q    last    first   phone\E                    \r? \n
              \Q    ---------------------------------------\E  \r? \n
              \Q    Jones   Bo      123-4567\E                 \r? \n
              \Q    Pez     Alice   890-1234\E                 \r? \n
          }x,
        'Various amounts of space/tab indentations apply to each paragraph';

    throws_ok{ fatal 'handler', <<"EOF" }
Population Histogram
--------------------+
                   x| >5700
                    | 5201 - 5700
               xxxxx| 4701 - 5200
         xxxxxxxxxxx| 4201 - 4700
   xxxxxxxxxxxxxxxxx| 3701 - 4200
                 xxx| 3201 - 3700
                    | 2701 - 3200
                    | 2201 - 2700
--------------------+
EOF
        qr{
              \A
              $banner_rex
              \Q    Population Histogram\E              \r? \n
              \Q    --------------------+\E             \r? \n
              \Q                       x| >5700\E       \r? \n
              \Q                        | 5201 - 5700\E \r? \n
              \Q                   xxxxx| 4701 - 5200\E \r? \n
              \Q             xxxxxxxxxxx| 4201 - 4700\E \r? \n
              \Q       xxxxxxxxxxxxxxxxx| 3701 - 4200\E \r? \n
              \Q                     xxx| 3201 - 3700\E \r? \n
              \Q                        | 2701 - 3200\E \r? \n
              \Q                        | 2201 - 2700\E \r? \n
              \Q    --------------------+\E             \r? \n
          }x,
        'Various amounts of leading whitespace preserved';

    return;
}

