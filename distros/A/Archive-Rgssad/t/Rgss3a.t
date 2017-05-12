use strict;
use warnings;
use Archive::Rgss3a;
use Archive::Rgssad::Entry;
use Digest::MD5 'md5_hex';
use IO::String;
use List::Util 'first';
use Test::More tests => 8;

my $prefix = "t/sample";
my $rgss3a = Archive::Rgss3a->new;

sub readfile {
  my $file = shift;
  local $/ = undef;
  open FH, '<', $file;
  binmode FH;
  return <FH>;
  close FH;
}

while (my $path = <DATA>) {
  chomp($path);
  my $data = readfile("$prefix/$path");
  $rgss3a->add($path, $data);
}

my $buf;

my $out = IO::String->new(\$buf);
$rgss3a->save($out);
my @entries = $rgss3a->entries;
is(md5_hex($buf), 'd4162932d830d83ddce42ede23e8218b', 'save');

my $in = IO::String->new(\$buf);
$rgss3a->load($in);
my @entries2 = $rgss3a->entries;
cmp_ok(@entries2, '==', @entries, 'number of entries');

for my $entry (@entries) {
  my $entry2 = first { $_->path eq $entry->path } @entries2;
  is($entry2->path, $entry->path, 'path of ' . $entry->path);
  is($entry2->data, $entry->data, 'data of ' . $entry->path);
}

1;

__DATA__
Dummy
Data/Scripts.rvdata
Graphics/System/1x1.png
