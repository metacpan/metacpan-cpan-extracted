use strict;
use warnings;

package T::Constants;

use DBD::SQLite::Constants qw/:file_open/;

BEGIN {
    require Exporter;
    @T::Constants::ISA         = ('Exporter');
    %T::Constants::EXPORT_TAGS = (all => [
        '$T_DATABASE', '$T_DB_ATTR', '$T_DB_DSN', '$T_DB_USER', '$T_DB_PASS', '$T_LIB', '$T_LIB_DATA', '@T_DB_CONNECT_ARGS',
    ]);
    @T::Constants::EXPORT_OK = @{$T::Constants::EXPORT_TAGS{all}};
}

use Test::Most;
use Cwd 'realpath';

our($T_LIB, $T_LIB_DATA, $T_DATABASE) = do {
    (my $module = __PACKAGE__)        =~ s/::/\//g;
    (my $lib    = realpath(__FILE__)) =~ s/\/$module\.pm$//i;
    ("$lib", "$lib/../data", "$lib/../data/chinook.db");
};

our @T_DB_CONNECT_ARGS = (
    our($T_DB_DSN, $T_DB_USER, $T_DB_PASS, $T_DB_ATTR) = (
        "dbi:SQLite:dbname=$T_DATABASE",
        "",
        "",
        {   AutoCommit                 => !!0,
            PrintError                 => !!0,
            RaiseError                 => !!1,
            sqlite_unicode             => !!1,
            sqlite_see_if_its_a_number => !!1,
            sqlite_open_flags          => SQLITE_OPEN_READONLY,
        },
    )
);

1;
