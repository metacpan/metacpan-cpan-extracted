# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';

use Path::Class qw(file dir);
use File::Spec::Functions 'tmpdir';

use lib "$Bin/lib";

use Test::More;
use Test::Exception;

use_ok('Catalyst::Controller::SimpleCAS::Store::File');

# Create a CAS structure within the test directory here.

my $cas_dir = dir( $Bin, 'tmp', 'cas' );

$cas_dir->rmtree if -d $cas_dir;
$cas_dir->mkpath;
-d $cas_dir or die "Error creating tmpdir $cas_dir";

my $file_cas= new_ok 'Catalyst::Controller::SimpleCAS::Store::File',
	[ store_dir => "$cas_dir" ], "create CAS instance on $cas_dir";

# Write a dummy file to the system temp path to simulate what Catalyst would
# use for a file upload.
my $origin_file= file(tmpdir(), 'incoming.txt');
$origin_file->spew(iomode => '>:raw', "This file simulates a Catalyst upload to the temp directory\n");

my $cksum= $file_cas->add_content_file_mv($origin_file);
is( $cksum, '437c659b4c0fea1304edea50c2cdd420f8c0f6f6', 'file hashed correctly' );

ok( -e $file_cas->checksum_to_path($cksum), 'new file exists' );
ok( !-e $origin_file, 'old file removed' );

done_testing;
