#!/usr/bin/perl
use strict;
use warnings;
use File::Find::Rule;
use IO::Zlib;

my $out = IO::Zlib->new("/vhosts/www.astray.com/site/manatee/root/tmp/backpan.txt.gz", "wb9") || die $!;

chdir "BACKPAN";
foreach my $filename (sort File::Find::Rule->new->file->in(".")) {
  my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks)
    = stat($filename);
  print $out "$filename $mtime $size\n";
}
chdir "..";
$out->close;
