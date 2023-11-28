use Test2::V0;

use Git::Wrapper;

my $git = Git::Wrapper->new('.');

my $status = $git->status;

# note: 'yath' might create .test_info and lastlog.jsonl files
ok !$status->is_dirty => "worktree is clean";

done_testing;
