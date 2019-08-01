#!perl -w
use strict;
use Archive::7zip;
use File::Basename;
use Test::More tests => 2;
use File::Temp 'tempfile';

my $version = Archive::7zip->find_7z_executable();
if( ! $version ) {
    SKIP: { skip "7z binary not found (not installed?)", 2; }
    exit;
};
diag "7-zip version $version";

my $base = dirname($0) . '/data';
my $archivename = "$base/def.zip";
my $ar = Archive::7zip->new(
    archivename => $archivename,
);

# Check that extraction to scalar and extraction to file
# result in the same output

sub slurp {
    my( $fh ) = @_;
    binmode $fh;
    local $/;
    <$fh>
};

my $originalname = "$base/fred";
open my $fh, '<', $originalname
    or die "Couldn't read '$originalname': $!";
my $original= slurp($fh);

sub data_matches_ok {
    my( $memory, $name) = @_;
    if( length($memory) == -s $originalname) {
        cmp_ok $memory, 'eq', $original, "extracted data matches ($name)";
    } else {
        fail "extracted data matches ($name)";
        diag "Got      [$memory]";
        diag "expected [$original]";
    };
}

my $memory = slurp( $ar->openMemberFH("fred"));
data_matches_ok( $memory, "Memory extraction" );

( $fh, my $tempname)= tempfile();
close $fh;
$ar->extractMember("fred",$tempname);
open $fh, '<', $tempname
    or die "Couldn't read '$tempname': $!";
my $disk   = slurp($fh);
data_matches_ok( $disk, "Direct disk extraction" );

