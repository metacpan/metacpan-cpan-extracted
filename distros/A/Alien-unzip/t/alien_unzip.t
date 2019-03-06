use Test2::V0 -no_srand => 1;
use Alien::unzip;
use Test::Alien;
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

alien_ok 'Alien::unzip';

subtest 'version' => sub {

  run_ok(['unzip', '-v'])
    ->success
    ->out_like(qr/UnZip.*Info-ZIP/)
    ->note;

};

subtest 'extract' => sub {

  # this tests store and deflate, which are probably the most
  # common.
  my $zipfile = path( 'corpus/foo-1.00.zip' )->absolute->stringify;

  local $CWD = tempdir( CLEANUP => 1 );

  run_ok(['unzip', $zipfile])
    ->success
    ->note;

  is(
    path('configure')->slurp,
    "#!/bin/sh\n" .
    "\n" .
    "echo \"hi there\";\n",
    './configure',
  );

  is(
    path('foo.c')->slurp,
    "#include <stdio.h>\n" .
    "\n" .
    "int\n" .
    "main(int argc, char *argv[])\n" .
    "{\n" .
    "  return 0;\n" .
    "}\n",
    './foo.c',
  );

};

done_testing
