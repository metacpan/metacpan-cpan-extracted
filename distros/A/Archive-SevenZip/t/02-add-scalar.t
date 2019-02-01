#!perl -w
use strict;
use Archive::SevenZip;
use File::Basename;
use Test::More tests => 2;
use File::Temp 'tempfile';

my $version = Archive::SevenZip->find_7z_executable();
if( ! $version ) {
    SKIP: { skip "7z binary not found (not installed?)", 2; }
    exit;
};
diag "7-zip version $version";
if( $version <= 9.20) {
  SKIP: {
    skip "7z version $version does not support renaming", 2;
  }
    exit
};

my $base = dirname($0) . '/data';
my $ar = Archive::SevenZip->new(
    #archivename => $archivename,
    #type => '7z',
);

#(my $tempname, undef) = tempfile;

my $content = "This is\x{0d}\x{0a}the content";
$ar->add_scalar('some-member.txt',$content);
#$ar->writeToFileNamed($tempname);

my @contents = map { $_->fileName } $ar->list();
is_deeply \@contents, ["some-member.txt"], "Contents of created archive are OK";

my $written = $ar->content( membername => 'some-member.txt', binmode => ':raw');
is $written, $content, "Reading back the same data as we wrote";

