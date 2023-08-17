use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;

use lib qw(t/lib);
use MyApp::Schema;

my ( $dsn, $user, $pass ) =
  @ENV{ map { "DBICTEST_MARIADB_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBICTEST_MARIADB_DSN}, _USER and _PASS to run tests'
  unless ( $dsn && $user );

my $schema = MyApp::Schema->connect( $dsn, $user, $pass );

subtest 'translator generates MariaDB compatible SQL' => sub {
    like( $schema->deployment_statements, qr/SET foreign_key_checks=0/ );
    like( $schema->deployment_statements, qr/CREATE TABLE artist/ );
    lives_ok {
        # drop all tables before deploy
        $schema->deploy( { add_drop_table => 1 } );
    }
    'deploy of the schema should work';

    # tables should exist
    isa_ok(
        $schema->source('MyApp::Schema::Artist'),
        'DBIx::Class::ResultSource::Table'
    );
};

subtest 'DBI module passes sane parameters to translator' => sub {
    my $sqltargs;
    {
        no warnings 'redefine';
        *DBIx::Class::Storage::DBI::deployment_statements = sub {
            $sqltargs = $_[5];
        };
    }
    my $ignore = $schema->deployment_statements;
    is($sqltargs->{producer_args}{mysql_version}, 
        $schema->storage->_server_info->{normalized_dbms_version});
};

done_testing();
