use strict;
use Test::More tests => 4+8;
use Cwd;
use File::Spec;

BEGIN {
  use_ok('Archive::Rar::Passthrough');
}

my $datadir = File::Spec->catdir("t", "data");
my $datafile = File::Spec->catfile($datadir, 'test.rar');
if (not -f $datafile) {
  $datadir = 'data';
  $datafile = File::Spec->catfile($datadir, 'test.rar');
}
ok(-f $datafile, "Test archive found");

my $rar = Archive::Rar::Passthrough->new(-archive => $datafile);
is($rar->get_stdout(), '', 'get_stdout() return value is empty string before use');
is($rar->get_stderr(), '', 'get_stderr() return value is empty string before use');

SKIP: {
  skip "'rar' command not found.", 6 if not defined $rar;
  isa_ok($rar, 'Archive::Rar::Passthrough');

  my $errcode = $rar->run(
    command => 'vt',
    archive => $datafile,
  );
  ok(!$errcode, 'rar list succeeded');
  
  my $out = $rar->get_stdout();
  ok(defined $out, 'get_stdout() return value defined');
  
  my $err = $rar->get_stderr();
  ok(defined $err, 'get_stderr() return value defined');

  $rar->clear_buffers();
  is($rar->get_stdout(), '', 'clear_buffers() erased stdout');
  is($rar->get_stderr(), '', 'clear_buffers() erased stderr');

  ok($out =~ /README/, 'output contains mention of the "README" file');
  ok($out =~ /COPYRIGHT/, 'output contains mention of the "COPYRIGHT" file');
}

