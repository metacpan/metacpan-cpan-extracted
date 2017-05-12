use strict;
use warnings;

use Test::More;
use Dancer2::Plugin::Auth::Extensible::Test;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'no-realms-configured';
}

{
    package TestApp;
    use Test::More;
    use Test::Deep qw/cmp_deeply re superbagof/;
    use Test::Warnings qw/warnings :no_end_test/;
    use Dancer2;
    cmp_deeply [
        warnings {
            require Dancer2::Plugin::Auth::Extensible;
            Dancer2::Plugin::Auth::Extensible->import;
        }
      ],
      superbagof(
        re(qr/No Auth::Extensible realms configured with which to authenticate user/)
      ),
      "got warning: No Auth::Extensible realms configured with which to authenticate user";
}

done_testing;
