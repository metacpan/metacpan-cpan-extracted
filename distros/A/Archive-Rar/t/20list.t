use strict;
use Test::More tests => 5+47+1;
use Cwd;
use File::Spec;

BEGIN {
  use_ok('Archive::Rar');
}

my $datadir = File::Spec->catdir("t", "data");
my $datafile = File::Spec->catfile($datadir, 'test.rar');
if (not -f $datafile) {
  $datadir = 'data';
  $datafile = File::Spec->catfile($datadir, 'test.rar');
}
ok(-f $datafile, "Test archive found");

my $rar = Archive::Rar->new(-archive => $datafile);
isa_ok($rar, 'Archive::Rar');

is($rar->List(), 0, "List() command succeeds");

# intrusive...
my $list = $rar->{list};
my @files = (
  {
    'packed' => '548',
    'ratio' => '61',
    'hour' => '12:03',
    'meth' => 'm3b',
    'date' => '03-01-08',
    'version' => '2.9',
    'name' => 'README',
    'crc' => '6E7ABCFE',
    'attr' => '-rw-r--r--',
    'size' => '890',
    'parts' => 1
  },
  {
    'packed' => '161',
    'ratio' => '87',
    'hour' => '12:03',
    'meth' => 'm3b',
    'date' => '03-01-08',
    'version' => '2.9',
    'name' => 'COPYRIGHT',
    'crc' => '5CDC2E66',
    'attr' => '-rw-r--r--',
    'size' => '183',
    'parts' => 1
  }
);

ok(ref($list) eq 'ARRAY', "list structure is an array ref");
ok(@$list == 2, "contains two files");

foreach my $fileno (0..$#files) {
  my $filespec = $files[$fileno];
  my $file = $list->[$fileno];
  ok(ref($file) eq 'HASH', "file structure $fileno is a hash");

  foreach my $key (keys %$filespec) {
    ok(exists($file->{$key}), "key '$key' exists in file struct $fileno");
    is($file->{$key}, $filespec->{$key}, "attribute '$key' in file struct $fileno matches");
  }
}

sub printlist { $rar->PrintList() } # I hate sub prototypes
SKIP: {
  eval "use Test::Output;";
  skip "Would need Test::Output for this test", 1 if $@;
  my $output = <<'HERE';

+-------------------------------------------------+----------+----------+------+
|                    File                         |   Size   |  Packed  | Gain |
+-------------------------------------------------+----------+----------+------+
| README                                          |      890 |      548 |  39% |
| COPYRIGHT                                       |      183 |      161 |  13% |
+-------------------------------------------------+----------+----------+------+
HERE
  stdout_is( \&printlist, $output, 'Test STDOUT' );
}


1;
