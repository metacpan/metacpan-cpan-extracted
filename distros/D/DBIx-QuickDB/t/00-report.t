use Test2::Tools::Basic;
use Test2::Util::Table qw/table/;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;

# Nothing in the tables in this file should result in a table wider than 80
# characters, so this is an optimization.
BEGIN { $ENV{TABLE_TERM_SIZE} = 80 }

diag "\nDIAGNOSTICS INFO IN CASE OF FAILURE:\n";
diag(join "\n", table(rows => [[ 'perl', $] ]]));
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
            mysqld => '-V',
            mysql  => '-V',
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

        diag(join "\n", "$prog binaries:", @table);
        print STDERR "\n";
    }

}

{
    my @mods = qw {
        Test2::API Test2::V0 Importer Module::Pluggable Carp Scalar::Util
        Time::HiRes parent File::Path File::Temp IPC::Cmd POSIX DBD::mysql
        DBD::Pg DBI DBD::SQLite
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
