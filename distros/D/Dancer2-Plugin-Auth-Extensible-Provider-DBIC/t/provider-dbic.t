use strict;
use warnings;

use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVDIR}      = 't/environments';
    $ENV{DANCER_ENVIRONMENT} = 'hashref';
}

use Dancer2::Plugin::Auth::Extensible::Test;
use DBICTest;

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::DBIC;
    use Dancer2::Plugin::Auth::Extensible 0.620;

    BEGIN {
        my $schema1 = schema('schema1');
        $schema1->deploy;
        my $schema2 = schema('schema2');
        $schema2->deploy;
        my $schema3 = schema('schema3');
        $schema3->deploy;
    }
    use Dancer2::Plugin::Auth::Extensible::Test::App;
    use DBICTestApp;
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

Dancer2::Plugin::Auth::Extensible::Test::runtests($app);
DBICTest::runtests($app);

done_testing;
