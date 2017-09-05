use Test::More;
use Perl::Build::Git ':all';
use FindBin '$Bin';
ok (no_uncommited_changes ($Bin), "no uncommited changes");
ok (branch_is_master ($Bin), "branch is master");
ok (up_to_date ($Bin), "no unpushed changes");
done_testing ();
