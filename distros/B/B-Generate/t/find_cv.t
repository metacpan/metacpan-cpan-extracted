#!perl
# Improve test coverage
#   make gcov; grep -- '####' *.gcov

use Test::More tests => 2;
use B;
use B::Generate;

# find_cv_by_root: PL_compcv && SvTYPE(PL_compcv) == SVt_PVCV &&
#                  !PL_eval_root && SvROK(PL_compcv)
# called by: op->find_cv
my $start = B::main_start;
my $cv = B::main_cv;
my $x;
my $const = B::opnumber("const");

use constant d => 10;

ok(${$start->find_cv} == $$cv, "start->find_cv $cv");
for ( $x = $start;
      $x->type != $const;
      $x = $x->next
    ) {};
$const = $x->find_cv;
ok($$const == $$cv, "const->find_cv $const");

#my $cv_pad = B::cv_pad($cv);
#ok($cv_pad, "cv_pad $cv_pad");

