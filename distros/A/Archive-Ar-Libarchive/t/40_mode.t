use strict;
use warnings;

use Test::More tests => 20;

use File::Temp qw(tempfile);
use Archive::Ar::Libarchive;

my ($fh, $file) = tempfile(UNLINK => 1);

my $content = do {local $/ = undef; <DATA>};
print $fh $content;
close $fh;

my $ar = Archive::Ar::Libarchive->new($file);
isa_ok $ar, 'Archive::Ar::Libarchive', 'object';
is_deeply [$ar->list_files], [qw(odd even)], 'list_files';

my $filedata = $ar->get_content('odd');
is $filedata->{name}, 'odd',            'file1, filedata/name';
is $filedata->{uid}, 2202,              'file1, filedata/uid';
is $filedata->{gid}, 2988,              'file1, filedata/gid';
is $filedata->{mode}, 0100644,          'file1, filedata/mode';
is $filedata->{date}, 1255532835,       'file1, filedata/date';
is $filedata->{size}, 11,               'file1, filedata/size';
is $filedata->{data}, "oddcontent\n",   'file1, filedata/data';

$filedata = $ar->get_content('even');
is $filedata->{name}, 'even',           'file2, filedata/name';
is $filedata->{uid}, 2202,              'file2, filedata/uid';
is $filedata->{gid}, 2988,              'file2, filedata/gid';
is $filedata->{mode}, 0100644,          'file2, filedata/mode';
is $filedata->{date}, 1255532831,       'file2, filedata/date';
is $filedata->{size}, 12,               'file2, filedata/size';
is $filedata->{data}, "evencontent\n",  'file2, filedata/data';

my ($nfh, $nfile) = tempfile(UNLINK => 1);

my $size = $ar->write($nfh);
is $size, 152, 'write size';
close $nfh;

my $nar = Archive::Ar::Libarchive->new($nfile);

is_deeply [$ar->list_files], [$nar->list_files], 'write/read, list_files';
is_deeply $ar->get_content('odd'), $nar->get_content('odd'),
                                                 'write/read, file1 compare';
is_deeply $ar->get_content('even'), $nar->get_content('even'),
                                                 'write/read, file2 compare';

__DATA__
!<arch>
odd             1255532835  2202  2988  100644  11        `
oddcontent

even            1255532831  2202  2988  100644  12        `
evencontent

