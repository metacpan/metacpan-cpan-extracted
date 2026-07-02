use Test2::Tools::Basic;
use Test2::Util::Table qw/table/;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;

# Nothing in the tables in this file should result in a table wider than 80
# characters, so this is an optimization.
BEGIN { $ENV{TABLE_TERM_SIZE} = 80 }

# Tidy a "<bin> -V"/"<bin> --version" line into a bare version string: drop the
# binary path, the "for <platform> ..." trailer, and any trailing build hash.
sub clean_version {
    my ($ver, $bin) = @_;
    $ver =~ s/\s*\Q$bin\E\s*//g;
    $ver =~ s/,?\s*for.*$//g;
    $ver =~ s/\s[0-9a-f]+$//gi;
    $ver =~ s/^\s+//;
    $ver =~ s/\s+$//;
    return $ver;
}

diag "\nDIAGNOSTICS INFO IN CASE OF FAILURE:\n";
diag(join "\n", table(rows => [[ 'perl', $] ]]));
print STDERR "\n";

{
    my %cmds = (
        SQLite => {
            sqlite3 => '--version',
        },
        DuckDB => {
            duckdb => '--version',
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

        my @rows;
        for my $cmd (sort keys %$set) {
            my $found = can_run($cmd);

            my $ver;
            if ($found) {
                chomp($ver = $set->{$cmd} ? `$found $set->{$cmd}` : 'N/A');
                $ver = clean_version($ver, $found);
            }

            push @rows => [$cmd, $found ? 'yes' : 'no', $ver || 'N/A'];
        }

        my @table = table(
            header => ['COMMAND', 'AVAILABLE', 'VERSION'],
            rows   => \@rows,
        );

        diag(join "\n", "$prog binaries:", @table);
        print STDERR "\n";
    }

}

# Inventory the versioned database installs the test suite can boot from ~/dbs.
# Each is a "<engine>-<version>" directory whose bin/ holds the server binary;
# the suite prepends that bin/ to PATH so QuickDB runs that exact build. This
# lists every such install, whether its server binary is present, and the
# version that binary reports.
{
    my $root = "$ENV{HOME}/dbs";

    # Engine prefix -> the server binary that must exist under bin/ and the
    # QuickDB driver that boots it. Mirrors %ENGINE in
    # t/lib/DBIx/QuickORM/Test.pm.
    my %engines = (
        postgresql => {server => 'postgres', driver => 'PostgreSQL'},
        mariadb    => {server => 'mariadbd', driver => 'MariaDB'},
        mysql      => {server => 'mysqld',   driver => 'MySQLCom'},
        percona    => {server => 'mysqld',   driver => 'Percona'},
    );

    my @found;
    if (opendir(my $dh, $root)) {
        for my $dir (readdir($dh)) {
            next unless $dir =~ m/^([a-z]+)-(\d+(?:\.\d+)*)$/;
            my ($engine, $version) = ($1, $2);
            my $meta = $engines{$engine} or next;

            my $server = "$root/$dir/bin/$meta->{server}";
            my $avail  = -x $server;

            my $ver = 'N/A';
            if ($avail) {
                chomp($ver = `$server -V 2>/dev/null`);
                $ver = clean_version($ver, $server);
                # Drop the engine's lead-in ("Ver ", "postgres (PostgreSQL) ")
                # so the column shows a bare version number.
                $ver =~ s/^\D+//;
                $ver = 'N/A' unless length $ver;
            }

            my ($major) = split /\./, $version;
            push @found => {
                dir    => $dir,
                engine => $engine,
                major  => $major,
                driver => $meta->{driver},
                avail  => $avail ? 'yes' : 'no',
                ver    => $ver,
            };
        }
        closedir($dh);
    }

    # Stable order: engine name, then numeric major, then full dir name.
    @found = sort {
        $a->{engine} cmp $b->{engine}
        || $a->{major} <=> $b->{major}
        || $a->{dir} cmp $b->{dir}
    } @found;

    if (@found) {
        my @rows = map { [$_->{dir}, $_->{driver}, $_->{avail}, $_->{ver}] } @found;
        my @table = table(
            header => ['INSTALL', 'DRIVER', 'AVAILABLE', 'VERSION'],
            rows   => \@rows,
        );
        diag(join "\n", 'Versioned database installs under ~/dbs:', @table);
    }
    else {
        diag('No versioned database installs found under ~/dbs.');
    }
    print STDERR "\n";
}

{
    my @mods = qw{
        Class::XSAccessor
        Cpanel::JSON::XS
        DBD::DuckDB
        DBD::MariaDB
        DBD::Pg
        DBD::SQLite
        DBD::mysql
        DBI
        DBIx::QuickDB
        DateTime
        DateTime::Format::MySQL
        DateTime::Format::Pg
        DateTime::Format::SQLite
        ExtUtils::MakeMaker
        Hash::Merge
        Importer
        Parallel::Runner
        Role::Tiny
        Role::Tiny::With
        SQL::Abstract
        Sub::Util
        Test2::V0
        UUID
    };

    my @rows;
    for my $mod (sort @mods) {
        my $installed = eval "require $mod; $mod->VERSION";
        push @rows => [$mod, $installed || "N/A"];
    }

    my @table = table(
        header => ['MODULE', 'VERSION'],
        rows   => \@rows,
    );

    diag(join "\n", @table);
}

pass('pass');
done_testing;
