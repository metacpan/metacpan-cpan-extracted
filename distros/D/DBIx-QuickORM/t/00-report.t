#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{TABLE_TERM_SIZE} = 120 }

use Test2::V0;
use Test2::Util::Table qw/table/;
use IPC::Cmd qw/can_run/;

my $exit = 0;
END{ $? = $exit }

diag "\nDIAGNOSTICS INFO IN CASE OF FAILURE:\n";
diag(join "\n", table(rows => [[ 'perl', $] ]]));

print STDERR "\n";

{
    my @depends = qw{
        Class::Method::Modifiers
        Class::XSAccessor
        Cpanel::JSON::XS
        DBD::MariaDB
        DBD::Pg
        DBD::SQLite
        DBD::mysql
        DBI
        DateTime
        DateTime::Format::MySQL
        DateTime::Format::Pg
        DateTime::Format::SQLite
        ExtUtils::MakeMaker
        Hash::Util
        IO::Select
        Importer
        List::Util
        Module::Pluggable
        Role::Tiny
        SQL::Abstract
        Scalar::Util
        Scope::Guard
        Storable
        Sub::Util
        Test2::Require::Module
        Test2::Tools::QuickDB
        Test2::Tools::Subtest
        Test2::Util
        Test2::V0
        UUID
        overload
    };

    my @rows;
    for my $mod (sort @depends) {
        my $installed = eval "require $mod; $mod->VERSION";
        push @rows => [ $mod, $installed || "N/A" ];
    }

    my @table = table(
        header => [ 'MODULE', 'VERSION' ],
        rows => \@rows,
    );

    diag(join "\n", @table);
}

print STDERR "\n";

{
    my %cmds = (
        SQLite => {
            sqlite3 => '--version',
        },
        PostgreSQL => {
            initdb   => '-V',
            createdb => '-V',
            postgres => '-V',
            psql     => '-V',
        },
        MySQL => {
            mysqld           => '-V',
            mysql            => '-V',
            mysql_install_db => undef,
        },
        MariaDB => {
           'mariadbd'           => '-V',
           'mariadb'            => '-V',
           'mariadb-install-db' => undef,
        },
    );

    open(my $STDERR, '>&', *STDERR) or die "Could not clone STDERR: $!";
    close(STDERR);
    open(STDERR, '>&=', $STDERR) or do {
        print $STDERR "Could not re-open STDERR: $!\n";
        exit(1);
    };

    for my $prog (sort keys %cmds) {
        my $set = $cmds{$prog};

        my $provs = 0;

        my @rows;
        for my $cmd (sort keys %$set) {
            my $found = can_run($cmd);

            my $prov = '--';
            my $ver = '--';
            if ($found) {
                chomp($ver = $set->{$cmd} ? `$found $set->{$cmd}` : '--');

                if ($ver =~ m/(percona|mariadb|oracle|postgresql|sqlite)/i) {
                    $provs++;
                    $prov = $1;
                }

                if ($ver =~ m/\b(\d+[\.\d]+(?:-\d+)?)\b/) {
                    $ver = $1;
                }
            }

            push @rows => [$cmd, $found || '--', $ver, $prov];
        }

        my @table = table(
            header => ['COMMAND', 'AVAILABLE', 'VERSION', $provs ? 'PROVIDER' : ()],
            rows   => \@rows,
        );

        diag(join "\n", "$prog binaries:", @table);
        print STDERR "\n";
    }
}

print STDERR "\n";

pass;
done_testing;
