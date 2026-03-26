######################################################################
#
# 9001-load.t
#
# SYNOPSIS
#   prove -l t/9001-load.t
#   perl t/9001-load.t
#
# DESCRIPTION
#   Verifies two things:
#
#   1. DB::Handy module load and interface
#      - The module loads without error
#      - $VERSION is defined and looks like a version number
#      - All three packages are present: DB::Handy, DB::Handy::Connection,
#        DB::Handy::Statement
#      - Public methods exist on each package (can() check)
#
#   2. INA_CPAN_Check library load and export
#      - t/lib/INA_CPAN_Check.pm loads without error
#      - check_A through check_K and helpers are exported
#
# COMPATIBILITY
#   Perl 5.005_03 and later.  No non-core dependencies.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

######################################################################
# Minimal TAP harness (local -- not imported from INA_CPAN_Check
# so that the counter is not reset when INA_CPAN_Check is loaded)
######################################################################

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN" . ($name ? " - $name" : '') . "\n";
    return $ok;
}
sub diag { print "# $_[0]\n" }
END { exit 1 if $T_PLAN && $T_FAIL }

######################################################################
# Test plan
######################################################################

my @db_methods = qw(
    new connect
    create_database use_database drop_database list_databases
    create_table drop_table list_tables describe_table
    create_index drop_index list_indexes
    insert delete_rows vacuum select update
);
my @conn_methods = qw(
    new connect do prepare
    selectall_arrayref selectall_hashref
    selectrow_hashref selectrow_arrayref
    quote disconnect
    last_insert_id table_info
);
my @sth_methods = qw(
    new execute fetchrow_hashref fetchrow_arrayref
    fetchrow_array fetch fetchall_arrayref fetchall_hashref
    finish rows
);

my $total = 5                        # load + VERSION + packages
          + scalar(@db_methods)      # DB::Handy methods
          + scalar(@conn_methods)    # DB::Handy::Connection methods
          + scalar(@sth_methods)     # DB::Handy::Statement methods
          + 4;                       # INA_CPAN_Check section
plan_tests($total);

######################################################################
# Section 1: DB::Handy
######################################################################

# ok 1: module loads
eval { require DB::Handy };
ok(!$@, 'DB::Handy loads without error');
diag("load error: $@") if $@;

# ok 2-3: VERSION
ok(defined $DB::Handy::VERSION,           'DB::Handy: $VERSION defined');
ok($DB::Handy::VERSION =~ /^\d+\.\d+/,   'DB::Handy: $VERSION looks like a version number');

# ok 4-5: sub-packages present
ok(defined $DB::Handy::Connection::{new}, 'DB::Handy::Connection package present');
ok(defined $DB::Handy::Statement::{new},  'DB::Handy::Statement package present');

# ok 6+: DB::Handy public methods
for my $m (@db_methods) {
    ok(DB::Handy->can($m), "DB::Handy->can('$m')");
}

# DB::Handy::Connection public methods
for my $m (@conn_methods) {
    ok(DB::Handy::Connection->can($m), "DB::Handy::Connection->can('$m')");
}

# DB::Handy::Statement public methods
for my $m (@sth_methods) {
    ok(DB::Handy::Statement->can($m), "DB::Handy::Statement->can('$m')");
}

######################################################################
# Section 2: INA_CPAN_Check
# Load without importing (avoids overwriting the local ok() counter)
######################################################################

eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');
diag("load error: $@") if $@;

# key helpers defined in the package
ok( defined &INA_CPAN_Check::ok
 && defined &INA_CPAN_Check::plan_tests
 && defined &INA_CPAN_Check::_slurp
 && defined &INA_CPAN_Check::_slurp_lines
 && defined &INA_CPAN_Check::_scan_code,
   'INA_CPAN_Check: key helpers defined');

# check_A through check_K defined
ok( defined &INA_CPAN_Check::check_A && defined &INA_CPAN_Check::check_B
 && defined &INA_CPAN_Check::check_C && defined &INA_CPAN_Check::check_D
 && defined &INA_CPAN_Check::check_E && defined &INA_CPAN_Check::check_F
 && defined &INA_CPAN_Check::check_G && defined &INA_CPAN_Check::check_H
 && defined &INA_CPAN_Check::check_I && defined &INA_CPAN_Check::check_J
 && defined &INA_CPAN_Check::check_K,
   'INA_CPAN_Check: check_A through check_K defined');

# count_A through count_K defined
ok( defined &INA_CPAN_Check::count_A && defined &INA_CPAN_Check::count_B
 && defined &INA_CPAN_Check::count_C && defined &INA_CPAN_Check::count_D
 && defined &INA_CPAN_Check::count_E && defined &INA_CPAN_Check::count_F
 && defined &INA_CPAN_Check::count_G && defined &INA_CPAN_Check::count_H
 && defined &INA_CPAN_Check::count_I && defined &INA_CPAN_Check::count_J
 && defined &INA_CPAN_Check::count_K,
   'INA_CPAN_Check: count_A through count_K defined');
