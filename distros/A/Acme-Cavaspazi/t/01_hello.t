use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Temp qw/ tempfile tempdir /;
use File::Spec;

my $bin = File::Spec->catfile($RealBin, '..', 'bin', 'cavaspazi');

# skip under Windows
if ($^O eq 'MSWin32') {
    plan skip_all => 'Bioinformatics is not for Windows';
}

# Create a temporary directory
my $tempdir = tempdir( CLEANUP => 1 );

# Create a file called "this is a test" in the temporary directory
my $filename = "$tempdir/this is a test";
open my $fh, '>', $filename or die "Can't open $filename: $!";

# Create a directory "this is a dir" in the temporary directory
my $dirname = "$tempdir/this is a dir";
mkdir $dirname or die "Can't mkdir $dirname: $!";

my @cmd = ($^X, $bin, '-r', '--verbose', $dirname, $filename);
print STDERR "Running command: @cmd\n";
ok(-e $filename, "File $filename exists");
ok(-e $dirname, "Directory $dirname exists");

my $exit = system(@cmd);
ok($exit == 0, "Command @cmd exited with 0");

my @files = glob("$tempdir/*");
for my $file (@files) {
    ok(!($file =~ / /), "File $file does not contain spaces");
}

done_testing();