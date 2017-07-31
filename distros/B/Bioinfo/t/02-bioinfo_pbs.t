use Modern::Perl;
use Test::More;
use IO::All;

my $module;
BEGIN {
  $module = 'Bioinfo::PBS';
  use_ok($module);
}
my @attrs = qw(cpu name cmd path job_id);
my @methods = qw(get_sh qsub wait job_stat);
can_ok($module, $_) for @attrs;
can_ok($module, $_) for @methods;

done_testing
