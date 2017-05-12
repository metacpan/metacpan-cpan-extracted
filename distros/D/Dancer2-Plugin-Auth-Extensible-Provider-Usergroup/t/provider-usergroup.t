use strict;
use warnings;

use Test::More;
use Dancer2::Plugin::Auth::Extensible::Test;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't/lib';
}

{

    package TestApp;
    use Path::Tiny;
    use Dancer2;
    use Dancer2::Plugin::DBIC;
    use Dancer2::Plugin::Auth::Extensible 0.620;

    BEGIN {
        my $schema1 = schema('schema1');
        my $schema2 = schema('schema2');
        my $schema3 = schema('schema3');

        $schema1->storage->dbh_do(
            sub {
                my ( $storage, $dbh ) = @_;
                $dbh->do($_) for split( /;/, path('t/ddl/schema1.ddl')->slurp );
            }
        );
        $schema2->storage->dbh_do(
            sub {
                my ( $storage, $dbh ) = @_;
                $dbh->do($_) for split( /;/, path('t/ddl/schema2.ddl')->slurp );
            }
        );
        $schema3->storage->dbh_do(
            sub {
                my ( $storage, $dbh ) = @_;
                $dbh->do($_) for split( /;/, path('t/ddl/schema3.ddl')->slurp );
            }
        );
    }
    use Dancer2::Plugin::Auth::Extensible::Test::App;
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

Dancer2::Plugin::Auth::Extensible::Test::runtests($app);

done_testing;
