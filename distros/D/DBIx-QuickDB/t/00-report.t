use Test2::Tools::Basic;
use Test2::Tools::Compare qw/like/;
use Test2::Util::Table qw/table/;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;
use Capture::Tiny qw/capture_stderr/;

# Nothing in the tables in this file should result in a table wider than 80
# characters, so this is an optimization.
BEGIN { $ENV{TABLE_TERM_SIZE} = 80 }

my $report_text = "\nDIAGNOSTICS INFO IN CASE OF FAILURE:\n";
my $perl_version = $];
$report_text .= join("\n", table(rows => [[ 'perl', $perl_version ]])) . "\n\n";

my $probe_stderr = capture_stderr {

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

    for my $prog (sort keys %cmds) {
        my $set = $cmds{$prog};

        my @rows;
        for my $cmd (sort keys %$set) {
            my $found = can_run($cmd);

            my $ver;
            if ($found) {
                chomp($ver = $set->{$cmd} ? `$found $set->{$cmd}` : 'N/A');
                $ver =~ s/\s*$found\s*//g;
                $ver =~ s/,?\s*for.*$//g;
                $ver =~ s/\s[0-9a-f]+$//gi;
            }

            push @rows => [$cmd, $found ? 'yes' : 'no', $ver || 'N/A'];
        }

        my @table = table(
            header => ['COMMAND', 'AVAILABLE', 'VERSION'],
            rows   => \@rows,
        );

        $report_text .= join("\n", "$prog binaries:", @table) . "\n\n";
    }

}

{
    my @mods = qw{
        Capture::Tiny
        Carp
        DBD::Pg
        DBD::SQLite
        DBD::mysql
        DBD::MariaDB
        DBI
        Digest::SHA
        Fcntl
        File::Path
        File::Temp
        IPC::Cmd
        Importer
        Module::Pluggable
        POSIX
        Scalar::Util
        Test2
        Test2::API
        Test2::V0
        Time::HiRes
        parent
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

    $report_text .= join("\n", @table) . "\n";
}
};

if (length $probe_stderr) {
    note("stderr from version probes:\n$probe_stderr");
}

like($report_text, qr/DIAGNOSTICS INFO IN CASE OF FAILURE/, 'report contains its heading');
like($report_text, qr/MariaDB binaries:.*mariadbd/s, 'report contains MariaDB diagnostics');
like($report_text, qr/MySQL binaries:.*mysqld/s, 'report contains MySQL diagnostics');
like($report_text, qr/PostgreSQL binaries:.*postgres/s, 'report contains PostgreSQL diagnostics');
like($report_text, qr/SQLite binaries:.*sqlite3/s, 'report contains SQLite diagnostics');
like($report_text, qr/MODULE.*Capture::Tiny/s, 'report contains module diagnostics');

print STDERR $report_text;

pass('pass');
done_testing;
