use strict;
use Archive::Any::Create;
use Archive::Tar;

use Test::More 'no_plan';

my $archive = Archive::Any::Create->new;

$archive->container('foo');
$archive->add_file('t/01_tar.t', "foobar\n");
$archive->add_file('t/02_xxx.t', "bazbaz\n");
$archive->write_file('foo.tar.gz');

open OUT, "> foo2.tar.gz";
$archive->write_filehandle(\*OUT, "tar.gz");
close OUT;

for my $file (qw( foo.tar.gz foo2.tar.gz )) {
    my $tar = Archive::Tar->new;
    $tar->read($file, 1);
    ok $tar->contains_file('foo/t/01_tar.t');
    is_deeply [ $tar->list_files ], [ 'foo/t/01_tar.t', 'foo/t/02_xxx.t' ];
    unlink $file;
}



