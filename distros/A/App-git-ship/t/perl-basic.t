use Test::More;
use App::git::ship::perl;

my $app = App::git::ship::perl->new;

{
  my $dist_file = 'App-git-SHIP.tar.gz';
  my $found = 0;

  ok $app->can_handle_project, 'App::git::ship::perl can handle this project';
  is $app->project_name, 'App::git::ship', 'project_name()';
  is $app->_dist_files(sub { $found++; return; }), undef, 'found no dist file';
  is $found, 0, '_dist_files callback was not called';

  open my $FH, '>', $dist_file or die "Write $dist_file: $!";
  close $FH;
  is $app->_dist_files(sub { ++$found; }), $dist_file, "found $dist_file";

  $app->_dist_files(sub { ++$found; return; });
  is $found, 2, '_dist_files callback was called once';

  like $app->_changes_to_commit_message, qr{Released version [\d\._]+\n\n\s+}, '_changes_to_commit_message()';

  unlink $dist_file;
}

TODO: {
  local $TODO = $^O eq 'linux' ? undef : 'No idea how to test this on other platforms';
  is_deeply [$app->exe_files], ['bin/git-ship'], 'exe_files: bin/git-ship';
}

SKIP: {
  skip '.git is not here', 1 unless -d '.git';

  my $author = $app->_author('%an, <%ae>');
  like $author, qr{^[^,]+, <[^\@]+\@[^\>]+>$}, 'got author and email';

  $author =~ s!,\s<.*!!;
  is $app->_author('%an'), $author, 'got author';
}

done_testing;
