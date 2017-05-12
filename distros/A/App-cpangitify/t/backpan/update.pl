use strict;
use warnings;
use 5.010001;
use Path::Class qw( file dir );

my $root = file(__FILE__)->parent->subdir(qw( authors id L LO LOCAL ));
my $index = file(__FILE__)->parent->file('backpan-index.txt');
my $fh = $index->openw;

foreach my $file (sort { $a->basename cmp $b->basename } $root->children)
{
  say $fh join(' ', join('/', qw( authors id L LO LOCAL ), $file->basename), $file->stat->mtime, -s $file );
}

$root = file(__FILE__)->parent->subdir(qw( authors id P PL PLICEASE ));

foreach my $file (sort { $a->basename cmp $b->basename } $root->children)
{
  say $fh join(' ', join('/', qw( authors id P PL PLICEASE ), $file->basename), $file->stat->mtime, -s $file );
}

close $fh;

