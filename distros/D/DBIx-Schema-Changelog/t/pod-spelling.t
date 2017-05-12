use strict;
use warnings FATAL => 'all';
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD coverage"
  if $@;

plan tests => 40;
add_stopwords(
    @{
        [
            'Zieschang', 'licensable', 'dbh', 'sql', 'Sql', 'Changeset',
            'changeset', 'postfix', 'AnnoCPAN', 'cpanminus', 'foreigns', 'uniques', 'Yaml'

        ]
    }
);

pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog.pm',                               'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Tutorial.pod',                     'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Exceptions.pm',                    'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Read.pm',                          'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Manual.pod',                       'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Changeset.pm',                     'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Cookbook.pod',                     'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Commands.pm',                      'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Actions.pm',                       'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Write.pm',                         'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Exception/NoDefaultValue.pm',      'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Driver/SQLite.pm',                 'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/File/Yaml.pm',                     'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Cookbook/Driver.pod',              'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Cookbook/File.pod',                'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Cookbook/Changeset.pod',           'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Role/Driver.pm',                   'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Role/Action.pm',                   'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Role/File.pm',                     'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Role/Command.pm',                  'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Indices.pm',                'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Constraints.pm',            'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Views.pm',                  'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Trigger.pm',                'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Sql.pm',                    'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Tables.pm',                 'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Columns.pm',                'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Entries.pm',                'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Sequences.pm',              'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Functions.pm',              'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Column/Defaults.pm',        'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Constraint/PrimaryKeys.pm', 'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Constraint/ForeignKeys.pm', 'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Action/Constraint/Uniques.pm',     'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Command/Driver.pm',                'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Command/Read.pm',                  'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Command/Base.pm',                  'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Command/File.pm',                  'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Command/Changeset.pm',             'POD file spelling OK' );
pod_file_spelling_ok( 'lib/DBIx/Schema/Changelog/Command/Write.pm',                 'POD file spelling OK' );

