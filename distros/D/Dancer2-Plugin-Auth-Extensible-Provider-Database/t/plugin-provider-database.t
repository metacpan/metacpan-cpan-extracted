use strict;
use warnings;

use Test::More;
use Dancer2::Plugin::Auth::Extensible::Test 0.620;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'provider-database';
}

{

    package TestApp;
    use Path::Tiny;
    use Dancer2;
    use Dancer2::Plugin::Database;
    use Dancer2::Plugin::Auth::Extensible;

    BEGIN {
        my $dbh1 = database('database1');
        my $dbh2 = database('database2');
        my $dbh3 = database('database3');
        my $ddl  = path('t/database/testapp.ddl');

        $dbh1->do($_)
          for split( /;/,
            join( ';', $ddl->slurp, path('t/database/config1.sql')->slurp ) );

        $dbh2->do($_)
          for split( /;/,
            join( ';', $ddl->slurp, path('t/database/config2.sql')->slurp ) );

        $dbh3->do($_)
          for split( /;/,
            join( ';', $ddl->slurp, path('t/database/config3.sql')->slurp ) );
    }
    use Dancer2::Plugin::Auth::Extensible::Test::App;
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

Dancer2::Plugin::Auth::Extensible::Test::runtests($app);

done_testing;
