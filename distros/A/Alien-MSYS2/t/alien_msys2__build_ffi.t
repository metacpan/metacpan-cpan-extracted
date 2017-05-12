use strict;
use warnings;
use Test::Alien::CanPlatypus;
use Test2::Bundle::Extended;
use Alien::MSYS2;
use Test::Alien;
use lib 't/lib';
use MyTest;
use File::Spec;
use Env qw( @PATH );
use File::Glob qw( bsd_glob );

# dontpanic isn't producing a .dll on MSWin32
# whoknows why.  Would be good to fix later.
skip_all 'not even tested where it is tested';

skip_all 'only tested on MSWin32' unless $^O eq 'MSWin32';
unshift @PATH, Alien::MSYS2->bin_dir;

my_extract_dontpanic(qw( t tmp static ));

my $prefix = File::Spec->rel2abs(File::Spec->catdir(File::Spec->updir, 'prefix'));
$prefix =~ s{\\}{/}g;

run_ok(['sh', 'configure', '--enable-shared', '--disable-static', "--prefix=$prefix"])
  ->success
  ->note;

run_ok(['make'])
  ->success
  ->note;

run_ok(['make', 'check'])
  ->success
  ->note;

run_ok(['make', 'install'])
  ->success
  ->note;

chdir $prefix;
chdir 'bin';
my $dll = File::Spec->catfile($prefix, 'bin', scalar bsd_glob '*.dll');
$dll =~ s{\\}{/}g;
chdir $prefix;

my $alien = synthetic {
  dynamic_libs => [$dll],
};

alien_ok $alien;

ffi_ok { symbols => ['answer'] }, with_subtest {
  my($ffi) = @_;
  plan 1;
  my $answer = $ffi->function(answer=>[]=>'int')->call;
  is $answer, 42;
};

my_cleanup;

done_testing;
