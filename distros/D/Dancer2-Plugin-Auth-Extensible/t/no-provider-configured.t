use strict;
use warnings;

use Test::More;
use Dancer2::Plugin::Auth::Extensible::Test;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'no-provider-configured';
}

{
    package TestApp;
    use Test::More;
    use Test::Fatal;
    use Dancer2;
    like exception {
        require Dancer2::Plugin::Auth::Extensible;
        Dancer2::Plugin::Auth::Extensible->import;
    },
      qr/No provider configured - consult documentation/,
      "got exception No provider configured - consult documentation...";
}

done_testing;
