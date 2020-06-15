use Test::More;
use App::cpanel qw(dir_walk_p);
use Mojo::Promise;

my (@mkdirs, @writes, @chmods);
my %dir2contents = (
  '.' => [
    { 'public_html' => [qw(0755 30)] },
    {},
  ],
  'public_html' => [
    { 'cgi-bin' => [qw(0755 30)], 'logs' => [qw(0755 30)] },
    { 'index.html' => [qw(0644 30)], 'other.html' => [qw(0644 30)] },
  ],
  'public_html/cgi-bin' => [
    {},
    { 'hello' => [qw(0755 30)] },
  ],
  'public_html/logs' => [ {}, {} ],
);
my %file2contents = (
  'public_html/index.html' => 'the index',
  'public_html/other.html' => 'other page',
  'public_html/cgi-bin/hello' => 'hello',
);
my %test_map = (
  ls => sub {
    $dir2contents{$_[0]}
      ? Mojo::Promise->resolve(@{$dir2contents{$_[0]}})
      : Mojo::Promise->reject("$_[0] does not exist");
  },
  mkdir => sub { push @mkdirs, $_[0]; Mojo::Promise->resolve(1); },
  read => sub { Mojo::Promise->resolve($file2contents{"$_[0]/$_[1]"});  },
  write => sub { push @writes, [ @_ ]; Mojo::Promise->resolve(1); },
  chmod => sub { push @chmods, [ @_ ]; Mojo::Promise->resolve(1); },
);
my @errors;

dir_walk_p(qw(public_html other), \%test_map, \%test_map)
  ->catch(sub { @errors = @_ })->wait;
ok !@errors, 'errors' or diag explain \@errors;
is_deeply \@mkdirs, [ qw(other other/cgi-bin other/logs) ], 'mkdirs'
  or diag explain \@mkdirs;
is_deeply \@writes, [
  [ qw(other index.html), 'the index' ],
  [ qw(other other.html), 'other page' ],
  [ qw(other/cgi-bin hello), 'hello' ],
], 'writes' or diag explain \@writes;
is_deeply \@chmods, [
  [ 'other', '0755' ],
  [ 'other/index.html', '0644' ],
  [ 'other/other.html', '0644' ],
  [ 'other/cgi-bin', '0755' ],
  [ 'other/logs', '0755' ],
  [ 'other/cgi-bin/hello', '0755' ],
], 'chmods' or diag explain \@chmods;

done_testing;
