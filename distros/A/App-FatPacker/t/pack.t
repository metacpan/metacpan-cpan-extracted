use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);
use File::Basename;
use File::Copy;
use File::Path;
use File::Temp qw/tempdir/;
use File::Spec;
use Cwd;

use App::FatPacker;

my $keep = $ENV{'FATPACKER_KEEP_TESTDIR'};

my $cwd = getcwd;
my $tempdir = tempdir('fatpacker-XXXXX', DIR => "$cwd/t", $keep ? (CLEANUP => 0) : (CLEANUP => 1));
mkpath([<$tempdir/{lib,fatlib}>]);

for (<t/mod/*.pm>) {
  copy $_, "$tempdir/lib/".basename($_) or die "copy failed: $!";
}

chdir $tempdir;

my $fp = App::FatPacker->new;
my $packed_file = "$tempdir/script";
open my $temp_fh, '>', $packed_file
  or die "can't write to $packed_file: $!";

select $temp_fh;
$fp->script_command_file;
print "1;\n";
select STDOUT;
close $temp_fh;

# make sure we don't pick up things from our created dir
chdir File::Spec->tmpdir;

# Packed, now try using it:
require $packed_file;

{
  require ModuleA;
  no warnings 'once';
  ok $ModuleA::foo eq 'bar', "packed script works";
}

{

    ok ref $INC[0], "\$INC[0] is a reference";
    ok $INC[0]->can( "files" ), "\$INC[0] has a files method";

    my @files = sort $INC[0]->files;

    is_deeply( \@files, [
        'ModuleA.pm',
        'ModuleB.pm',
        'ModuleC.pm',
        'ModuleCond.pm',
        'ModuleD.pm',
    ], "\$INC[0]->files returned the files" );

}


if (my $testwith = $ENV{'FATPACKER_TESTWITH'}) {
  for my $perl (split ' ', $testwith) {
    my $out = system $perl, '-e',
        q{alarm 5; require $ARGV[0]; require ModuleA; exit($ModuleA::foo eq 'bar' ? 0 : 1)}, $temp_fh;
    ok !$out, "packed script works with $perl";

    $out = system $perl, '-e',
        q{alarm 5; require $ARGV[0]; exit( (sort $INC[0]->files)[0] eq 'ModuleA.pm' ? 0 : 1 )}, $temp_fh;
    ok !$out, "\$INC[0]->files works with $perl";

  }
}

