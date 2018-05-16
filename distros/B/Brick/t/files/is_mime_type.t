#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use File::Spec;

use_ok( 'Brick' );
use_ok( 'Brick::Files' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

ok( defined &Brick::Bucket::is_mime_type, "is_mime_type sub is there");
#can_ok( $bucket, 'is_mime_type',  "can is_mime_type" );

ok( $bucket->can( 'is_mime_type' ), "can is_mime_type" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
my $sub = $bucket->is_mime_type(
	{
	file_field   => "filename",
	mime_types => [ 'application/vnd.ms-excel' ],
	}
	);

isa_ok( $sub, ref sub {}, "returns a code ref" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# this one should work
{
my $file = "t/files/files_to_test/excel.xls";
ok( -e $file, "Target file exists" );

my $result = eval { $sub->( { filename => $file } ) };
is( $result, 1, "Excel file is an excel file" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# this one should fail because it's not the right type
{
my $file = "t/files/files_to_test/word.doc";
ok( -e $file, "Target file exists" );

my $result = eval { $sub->( { filename => $file } ) };
my $at = $@;

ok( ! defined $result, "Word doc is not an Excel file" );
ok( defined $at, "\$\@ is defined" );
isa_ok( $at, ref {}, "\$\@ is a hash ref" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# this one should fail because the file is not there
{
my $file = "t/files/files_to_test/not_there.txt";
ok( ! -e $file, "Target file doesn't exist (good)" );

my $result = eval { $sub->( { filename => $file } ) };
my $at = $@;

ok( ! defined $result, "Non-existent file fails" );
ok( defined $at, "\$\@ is defined" );
isa_ok( $at, ref {}, "\$\@ is a hash ref" );
}

