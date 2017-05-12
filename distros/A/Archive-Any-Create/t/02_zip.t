use strict;
use Archive::Any::Create;
use Archive::Zip;

use Test::More 'no_plan';

my $archive = Archive::Any::Create->new;

$archive->container('foo');
$archive->add_file('t/01_tar.t', "foobar\n");
$archive->add_file('t/02_xxx.t', "bazbaz\n");
$archive->write_file('foo.zip');

open OUT, "> foo2.zip";
$archive->write_filehandle(\*OUT, "zip");
close OUT;

for my $file (qw( foo.zip foo2.zip )) {
    my $zip = Archive::Zip->new;
    $zip->read($file);
    ok $zip->memberNamed('foo/t/01_tar.t');
    is_deeply [ map $_->fileName, $zip->members ], [ 'foo/', 'foo/t/01_tar.t', 'foo/t/02_xxx.t' ];
    unlink $file;
}

