# -*- perl -*-

# t/11_dirs_and_files.t - Archive containing dir and files

use strict;
use Test::More tests => 11;

#01
BEGIN { use_ok( 'Archive::Tar::Streamed' ); }

my $fh;
open $fh,'+>','test/stream3.tar' or die "Couldn't open archive";
binmode $fh;

my $tar = Archive::Tar::Streamed->new($fh);

#02
isa_ok($tar,'Archive::Tar::Streamed','Return from new');

$tar->add('t');					# add directory
$tar->add(glob('t/0*.t')); 			# add multiple files
$tar->writeeof;

seek $fh,0,0;					# rewind

my $fil = $tar->next;

#03
isa_ok($fil,'Archive::Tar::File','Return from next');

#04
is($fil->name,'t','Directory name OK');

$fil = $tar->next;

#05
isa_ok($fil,'Archive::Tar::File','Return from next');

#06
is($fil->name,'01_stream.t','Second file name OK');

$fil = $tar->next;

#07
isa_ok($fil,'Archive::Tar::File','Return from next');

#08
is($fil->name,'02_check_tar.t','Second file name OK');

$fil = $tar->next;

#09
isa_ok($fil,'Archive::Tar::File','Return from next');

#10
is($fil->name,'03_read_tar.t','Second file name OK');

#11
ok(!$tar->next, 'EOF detected');
