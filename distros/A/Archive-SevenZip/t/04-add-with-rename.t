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
    skip "7z version $version does not support reading archives from stdin", 2;
  }
    exit
};

my $base = dirname($0) . '/data';

my $archive = "$base/perl.zip";
open my $fh, '<', $archive
    or die "Couldn't open '$archive': $!";
binmode $fh;

my $ar = Archive::SevenZip->new(
    fh => $fh,
    #verbose => 1,
);
my $content = "This is\x{0d}\x{0a}the content";
my ($tempfh, $tempname) = tempfile();
binmode $tempfh;
print {$tempfh} $content;
close $tempfh;

# We check that both, absolute and relative names can be renamed
$ar->add( items => [ [$tempname => 'some-member.txt'],
                     [ "$base/fred" => 'foo/myfred' ]
                   ]);

my @contents = map { $_->fileName } $ar->list();
is_deeply \@contents, ["some-member.txt", 'foo/myfred' ], "Contents of created archive are OK";

my $written = $ar->content( membername => 'some-member.txt', binmode => ':raw');
is $written, $content, "Reading back the same data as we wrote";

