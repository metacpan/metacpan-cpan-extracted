use Test::More;
use App::git::ship::perl;

plan skip_all => "Cannot test on $^O" if $^O eq 'MSWin32';

my $app       = App::git::ship::perl->new;
my $dist_file = 'App-git-SHIP.tar.gz';
my $found     = 0;

ok $app->can_handle_project, 'App::git::ship::perl can handle this project';
is $app->config('project_name'), 'App::git::ship', 'project_name()';
ok !$app->_dist_files->[0], 'found no dist file';

open my $FH, '>', $dist_file or die "Write $dist_file: $!";
close $FH;
like $app->_dist_files->[0], qr{\b$dist_file$}, "found $dist_file";
unlink $dist_file;

like $app->_changes_to_commit_message, qr{Released version [\d\._]+\n\n\s+},
  '_changes_to_commit_message()';

TODO: {
  local $TODO = -e 'script/git-ship' ? undef : 'No idea how to test this on other platforms';
  is_deeply [$app->_exe_files], ['script/git-ship'], 'exe_files: git-ship';
}

SKIP: {
  skip '.git is not here', 1 unless -d '.git';

  my $author = $app->config('author');
  like $author, qr{^\S+[^<]+<[^\@]+\@[^\>]+>$}, 'got author and email';

  $author =~ s!\s<.*!!;
  is $app->_build_config_param_author('%an'), $author, 'got author';
}

done_testing;
