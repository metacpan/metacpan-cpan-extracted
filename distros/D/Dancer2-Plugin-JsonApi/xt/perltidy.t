use 5.32.0;

use Test2::V0;

use Git::Wrapper;
use Test::PerlTidy qw( run_tests );

my $target_branch = $ENV{TARGET_BRANCH} // 'main';

my $git = Git::Wrapper->new('.');

my $on_target = grep { "* $target_branch" eq $_ } $git->branch;

if ($on_target) {
    run_tests();
}
else {
    my @files =
      $git->diff( { name_only => 1, diff_filter => 'ACMR' }, $target_branch );
    ok Test::PerlTidy::is_file_tidy($_), $_
      for grep { /\.(pl|pm|pod|t)$/ } @files;

}

done_testing;
