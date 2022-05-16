use Modern::Perl;
use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVDIR}      = 't/environments';
    $ENV{DANCER_ENVIRONMENT} = 'object';
}

use Dancer2::Plugin::Auth::Extensible::Test;
use DBICTest;

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::DBIx::Class;
    use Dancer2::Plugin::Auth::Extensible 0.620;

    BEGIN {
        my $first_schema = schema('schema1');
        $first_schema->deploy;
        my $second_schema = schema('schema2');
        $second_schema->deploy;
        my $third_schema = schema('schema3');
        $third_schema->deploy;
    }
    use Dancer2::Plugin::Auth::Extensible::Test::App;
    use DBICTestApp;
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

Dancer2::Plugin::Auth::Extensible::Test::runtests($app);
DBICTest::runtests($app);

done_testing;
