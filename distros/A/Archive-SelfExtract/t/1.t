use Test::More tests => 4;
use strict;
use File::Temp 'tempdir';
use File::Spec::Functions; # catfile

BEGIN {
  use_ok( 'Archive::SelfExtract' );
}

my $zip = catfile("sample", "test.zip");
die "Missing required test files" unless -e $zip;

my $src = catfile("sample", "test-script.pl");
die "Missing required test files" unless -e $src;

# comment out the CLEANUP to dignose test problems:
my $td = tempdir( CLEANUP => 1 );
my $tscr = catfile($td,"test.pl");
open(my $out, "> $tscr") || die "Can't create test script $tscr ($!)";

Archive::SelfExtract::createExtractor( $src, $zip, output_fh => $out );

close($out);

ok( -e $tscr && -s $tscr, "Self-extracting script created" );

eval {
  do $tscr || die $!;
};
ok( ! $@, "Test script runs without dying" );

ok( ! -d $Archive::SelfExtract::Tempdir,
    "Test script cleaned up after itself" );

