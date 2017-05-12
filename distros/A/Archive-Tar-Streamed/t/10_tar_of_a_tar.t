# -*- perl -*-

# t/10_tar_of_a_tar.t - Archive within an archive
# t/01_stream.t needs to be run first
#
# This should work, and be a good test for arbitrary binary data

use strict;
use Test::More tests => 11;

#01
BEGIN { use_ok( 'Archive::Tar::Streamed' ); }

my $fh;
open $fh,'+>','test/stream2.tar' or die "Couldn't open archive";
binmode $fh;

my $tar = Archive::Tar::Streamed->new($fh);

#02
isa_ok($tar,'Archive::Tar::Streamed','Return from new');

$tar->add('test/stream.tar');		# add something that's already a tar
$tar->add(glob('t/0*.t')); 			# add multiple files
$tar->writeeof;

seek $fh,0,0;					# rewind

my $fil = $tar->next;

#03
isa_ok($fil,'Archive::Tar::File','Return from next');

#04
is($fil->name,'stream.tar','First file name OK');

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
