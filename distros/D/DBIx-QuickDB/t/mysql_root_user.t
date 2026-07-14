use Test2::V0;
use Test2::Tools::QuickDB;
use DBIx::QuickDB;
# Load the driver up front: build_db lazy-requires it, and that require would
# clobber our _run_as_root override if the module were not already in memory.
use DBIx::QuickDB::Driver::MySQL;

# Regression for GH #13: modern mysqld/mariadbd refuse to start as root unless
# told 'user=root'. When QuickDB runs as root it must inject that into the
# generated defaults file so bootstrap/start work. We do NOT need to actually be
# root (or start a server): _run_as_root is a seam we override to simulate root,
# and we only inspect the config file write_config produces.

skipall_unless_can_db(driver => 'MySQL', bootstrap => 1);

sub cfg_body {
    my ($run_as_root) = @_;

    no warnings 'redefine';
    # Override the seam BEFORE build_db: the CONFIG hash is frozen in init(),
    # so _run_as_root must already report the simulated value when the object
    # is constructed.
    local *DBIx::QuickDB::Driver::MySQL::_run_as_root = sub { $run_as_root };

    my $db = DBIx::QuickDB->build_db({driver => 'MySQL', bootstrap => 0, autostart => 0});
    $db->write_config;

    open(my $fh, '<', $db->cfg_file) or die "Could not read config: $!";
    my $body = do { local $/; <$fh> };
    close($fh);

    return $body;
}

my $as_user = cfg_body(0);
unlike(
    $as_user,
    qr/^\s*user\s*=\s*root\s*$/m,
    "no 'user = root' in the config when not running as root",
);

my $as_root = cfg_body(1);
like(
    $as_root,
    qr/^\s*user\s*=\s*root\s*$/m,
    "'user = root' injected into the config when running as root (GH #13)",
);

# The override belongs to a server section, never the client sections.
my ($server_chunk) = $as_root =~ m/^\[(?:maria|mysq)ld\].*?(?=^\[|\z)/msg;
like($server_chunk // '', qr/^\s*user\s*=\s*root\s*$/m, "'user = root' lives in a server section");

done_testing;
