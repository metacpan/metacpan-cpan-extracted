#!perl -w
use strict;
use Archive::7zip;
use File::Basename;
use Test::More tests => 1;
use File::Temp 'tempfile';

# Initialize 7z location
my $version = Archive::7zip->find_7z_executable();
if( ! $version ) {
    SKIP: { skip "7z binary not found (not installed?)", 1; }
    exit;
};
diag "7-zip version $version";

$ENV{PERL_ARCHIVE_SEVENZIP_BIN} = delete $Archive::SevenZip::class_defaults{"7zip"};
my $version_from_env = Archive::7zip->find_7z_executable();

is $version_from_env, $version, "We find the same 7z version when initialized from %ENV";
