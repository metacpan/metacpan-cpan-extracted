use 5.010_001;
use strict;
use warnings;

package T::Squirrel;

use Cwd qw/realpath/;
use DBD::Mock;
use Test::More;
use DBD::SQLite ();
use namespace::clean;

BEGIN {
    require Exporter;
    @T::Squirrel::ISA         = qw/Exporter/;
    %T::Squirrel::EXPORT_TAGS = (
        var => [
            qw/
              $TEST_LIB_DIR
              $TEST_DATA_DIR
              $MOCK_DB_DSN
              $MOCK_DB_USERNAME
              $MOCK_DB_PASSWORD
              @MOCK_DB_CREDENTIALS
              @MOCK_DB_CONNECT_ARGS
              $TEST_DB_DSN
              $TEST_DB_USERNAME
              $TEST_DB_PASSWORD
              $TEST_DB_ATTR
              $TEST_DB_NAME
              @TEST_DB_CREDENTIALS
              @TEST_DB_CONNECT_ARGS
              $DBD_SQLite_VERSION
              $SKIP_SQLITE_PARAMVALUES_CHECKS
              /
        ],
        func => [
            qw/
              diagdump
              notedump
              /,
        ],
    );
    $T::Squirrel::EXPORT_TAGS{all} = [@{$T::Squirrel::EXPORT_TAGS{var}}, @{$T::Squirrel::EXPORT_TAGS{func}}];
    @T::Squirrel::EXPORT_OK        = (@{$T::Squirrel::EXPORT_TAGS{all}});
    @T::Squirrel::EXPORT           = (@{$T::Squirrel::EXPORT_TAGS{var}});
}

our $TEST_LIB_DIR = do {
    my $module = __PACKAGE__;
    $module =~ s/\::/\//g;
    my $path = __FILE__;
    $path =~ s/\/$module\.pm$//i;
    realpath("$path");
};
our $TEST_DATA_DIR = realpath("$TEST_LIB_DIR/../data");

our($MOCK_DB_DSN, $MOCK_DB_USERNAME, $MOCK_DB_PASSWORD) = ("dbi:Mock:", "", "");
our @MOCK_DB_CREDENTIALS  = ($MOCK_DB_USERNAME, $MOCK_DB_PASSWORD);
our @MOCK_DB_CONNECT_ARGS = ($MOCK_DB_DSN,      @MOCK_DB_CREDENTIALS);

our $TEST_DB_NAME = "$TEST_DATA_DIR/chinook.db";
our($TEST_DB_DSN, $TEST_DB_USERNAME, $TEST_DB_PASSWORD, $TEST_DB_ATTR) = (
    "dbi:SQLite:dbname=$TEST_DB_NAME",
    "",
    "",
    {   AutoCommit                 => !!0,
        PrintError                 => !!0,
        RaiseError                 => !!1,
        sqlite_unicode             => !!1,
        sqlite_see_if_its_a_number => !!1,
    },
);
our @TEST_DB_CREDENTIALS  = ($TEST_DB_USERNAME, $TEST_DB_PASSWORD);
our @TEST_DB_CONNECT_ARGS = ($TEST_DB_DSN, @TEST_DB_CREDENTIALS, $TEST_DB_ATTR);

our $DBD_SQLite_VERSION = do {
    (my $version = $DBD::SQLite::VERSION) =~ s/_(\d+)$/.$1/;
    my @maj_min_fix = split(/\./, "${version}.0", 3);
    @_ < 3 ? 0+sprintf('%d.%02d', @maj_min_fix[0,1]) : 0+sprintf('%d.%02d02d', @maj_min_fix);
};

our $SKIP_SQLITE_PARAMVALUES_CHECKS = $DBD_SQLite_VERSION < 1.056_000;

sub diagdump {diag(explain(@_))}

sub notedump {note(explain(@_))}

1;
