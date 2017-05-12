#!perl -T
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');

ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use Blog::User;
use Blog::Bookmark;
use MySQLDB;
use MySQLUser;
use Data::Dumper;

sub primary_keys : Tests {
    my $pk = Blog::User->primary_keys;
    ok $pk;
    is_deeply $pk, ['user_id'], 'user pri keys';
    $pk = Blog::Bookmark->primary_keys;
    ok $pk;
    is_deeply $pk, ['user_id', 'entry_id'], 'bookmark pri keys';
}

sub unique_keys : Tests {
    my $uk = Blog::User->unique_keys;
    ok $uk;
    is_deeply $uk, ['user_id', 'name'], 'user uniq keys';
}

sub columns : Tests {
    my $cols = Blog::User->columns or return;
    ok $cols;
    isa_ok ($cols, 'ARRAY', 'cols is a array');
    my %cols;
    $cols{$_}++ for @$cols;
    ok ($cols{name}, 'cols has name');
    ok ($cols{user_id}, 'cols has user_id');
    is_deeply [sort @$cols], ['name', 'user_id'], 'user columns';
}

sub param : Tests {
    my $schema = Blog::User->schema;
    $schema->param(test => 'schema_test');
    is $schema->param('test'), 'schema_test';
    my $validation = {name => ['NOT_BLANK', 'ASCII']};
    $schema->param(validation => $validation);
    is $schema->param('validation'), $validation;
}

sub mysql : Test(9) {
    MySQLDB->dbh or return('skipped mysql tests');
    my $pk = MySQLUser->primary_keys;
    ok $pk;

    is @$pk, 2, 'number of column in mysql user pri keys';
    is( grep({ m/(Host|User)/ } @$pk), 2, 'mysql user pri keys' );

    my $uk = MySQLUser->unique_keys;
    ok $uk;
    is @$uk, 2, 'number of column in mysql user uniq keys';
    is( grep({ m/(Host|User)/ } @$uk), 2, 'mysql user uniq keys' );

    my $cols = MySQLUser->columns;
    ok $cols;
    isa_ok $cols, 'ARRAY';
    ok (scalar(@$cols) > 3);
#     is_deeply [sort @$cols], [
#         'Alter_priv',
#         'Alter_routine_priv',
#         'Create_priv',
#         'Create_routine_priv',
#         'Create_tmp_table_priv',
#         'Create_user_priv',
#         'Create_view_priv',
#         'Delete_priv',
#         'Drop_priv',
#         'Execute_priv',
#         'File_priv',
#         'Grant_priv',
#         'Host',
#         'Index_priv',
#         'Insert_priv',
#         'Lock_tables_priv',
#         'Password',
#         'Process_priv',
#         'References_priv',
#         'Reload_priv',
#         'Repl_client_priv',
#         'Repl_slave_priv',
#         'Select_priv',
#         'Show_db_priv',
#         'Show_view_priv',
#         'Shutdown_priv',
#         'Super_priv',
#         'Update_priv',
#         'User',
#         'max_connections',
#         'max_questions',
#         'max_updates',
#         'max_user_connections',
#         'ssl_cipher',
#         'ssl_type',
#         'x509_issuer',
#         'x509_subject'
#     ], 'mysql user columns';
}

1;
