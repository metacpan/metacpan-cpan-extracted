#!perl
use Test::Most;
use Test::DBIx::Class::Schema;

use lib qw(t/lib);
use ZapziTestDatabase;
use ZapziTestSchema;
use App::Zapzi;
use Path::Tiny;

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_schema($app);
test_upgrade();

done_testing();

sub test_schema
{
    my $app = shift;

    my $schema = $app->database->schema;
    isa_ok( $schema, 'App::Zapzi::Database::Schema' );

    # ZapziSchemaTest is a wrapper for Test::DBIx::Class::Schema
    subtest 'Article' => sub
    {
        ZapziTestSchema->test($schema, 'Article',
                              [ qw(id title folder created source) ],
                              [ qw(folder article_text) ]);
    };

    subtest 'ArticleText' => sub
    {
        ZapziTestSchema->test($schema, 'ArticleText',
                              [ qw(id text) ],
                              [ qw(article) ]);
    };

    subtest 'Folder' => sub
    {
        ZapziTestSchema->test($schema, 'Folder',
                              [ qw(id name) ],
                              [ qw(articles) ]);
    };

    subtest 'Config' => sub
    {
        ZapziTestSchema->test($schema, 'Config',
                              [ qw(name value) ],
                              [ ]);
    };
}

sub test_upgrade
{
    my $ddl = path('t/ddl/create-version-0-db.sql')->slurp;
    ok( length($ddl) > 100, 'Read pre-upgrade DDL OK' );

    my ($test_dir, $app) = ZapziTestDatabase::get_test_app($ddl);
    is( $app->database->get_version, 0, 'Create version 0 database' );
    ok( ! $app->database->check_version(), 'Version 0 is not up to date' );

    $app->database->upgrade();

    is( $app->database->get_version, $app->database->schema->schema_version,
        'Upgraded database to latest version' );

    note("Now testing the upgraded database against the current schema");
    test_schema($app);
}
