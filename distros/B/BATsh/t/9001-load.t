######################################################################
#
# 9001-load.t  Module load and interface check
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use INA_CPAN_Check;

my @batsh_methods = qw(
    new run run_string run_lines repl
    classify_token setlocal endlocal
    call_sub source_file version sh_available
);
my @env_methods = qw(
    init get set unset exists_var sync_to_env
    snapshot restore expand_cmd expand_sh
    setlocal endlocal
);

plan_tests(3
    + scalar(@batsh_methods)
    + 1
    + scalar(@env_methods)
    + 1 + 1
    + 4);

eval { require BATsh };
ok(!$@, 'BATsh loads without error');
diag("load error: $@") if $@;
ok(defined $BATsh::VERSION,         'BATsh: $VERSION defined');
ok($BATsh::VERSION =~ /^\d+\.\d+/, 'BATsh: $VERSION looks like a version number');

for my $m (@batsh_methods) {
    ok(BATsh->can($m), "BATsh->can('$m')");
}

eval { require BATsh::Env };
ok(!$@, 'BATsh::Env loads without error');
for my $m (@env_methods) {
    ok(BATsh::Env->can($m), "BATsh::Env->can('$m')");
}

eval { require BATsh::CMD };
ok(!$@, 'BATsh::CMD loads without error');
diag("load error: $@") if $@;

eval { require BATsh::SH };
ok(!$@, 'BATsh::SH loads without error');
diag("load error: $@") if $@;

eval { require INA_CPAN_Check };
ok(!$@, 'INA_CPAN_Check loads without error');
ok(defined &INA_CPAN_Check::ok && defined &INA_CPAN_Check::plan_tests,
   'INA_CPAN_Check: helpers defined');
ok(defined &INA_CPAN_Check::check_A && defined &INA_CPAN_Check::check_K,
   'INA_CPAN_Check: check_A through check_K defined');
ok(defined &INA_CPAN_Check::count_A && defined &INA_CPAN_Check::count_K,
   'INA_CPAN_Check: count_A through count_K defined');

END { end_testing() }
