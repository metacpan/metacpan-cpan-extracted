use Test2::V0 -no_srand => 1;
use Alien::Base::ModuleBuild::Repository::Local;
use File::Basename qw/fileparse/;
use File::Temp;
use File::chdir;

is(
  Alien::Base::ModuleBuild::Repository::Local->is_network_fetch,
  0
);

is(
  Alien::Base::ModuleBuild::Repository::Local->is_secure_fetch,
  1
);

my $repo = Alien::Base::ModuleBuild::Repository::Local->new({ location => 't' });

my @files = $repo->list_files;
my $this_file = fileparse __FILE__;

ok( grep { $_ eq $this_file } @files, "found this file" );

{
  my $tempdir = File::Temp->newdir;
  local $CWD = "$tempdir";

  $repo->get_file($this_file);
  ok( -e $this_file, "copied this file to temp dir" );
}

done_testing;

