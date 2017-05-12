use Test::More; 
Test::More->builder->no_ending(1);
use Config;
use Carp::Assert;
use lib 't/lib';
use strict;

use CGI::Uploader;
use DBI;
use CGI;
use HTTP::Request::Common;
use CGI::Uploader::Test;

$| = 1;

if (! $Config{d_fork} ) {
    plan skip_all => "fork not available on this platform";
}
else {
    plan tests => 12;

}

my ($DBH, $drv) = setup();

my $req = &HTTP::Request::Common::POST(
    '/dummy_location',
    Content_Type => 'form-data',
    Content      => [
        test_file => ["t/test_file.txt"],
    ]
);

# Useful in simulating an upload. 
$ENV{REQUEST_METHOD} = 'POST';
$ENV{CONTENT_TYPE}   = 'multipart/form-data';
$ENV{CONTENT_LENGTH} = $req->content_length;
if ( open( CHILD, "|-" ) ) {
    print CHILD $req->content;
    close CHILD;
    exit 0;
}

my $q = new CGI;

$DBH->do("ALTER TABLE uploads ADD COLUMN custom char(64)");

	 my %imgs = (
		'test_file' => {
            gen_files => {
                test_file_gen => {
                    transform_method => \&test_gen_transform
                },
            },
        },
	 );

	 my $u = 	CGI::Uploader->new(
		updir_path=>'t/uploads',
		updir_url=>'http://localhost/test',
		dbh => $DBH,
		query => $q,
		spec => \%imgs,
        up_table_map => {
            upload_id => 'upload_id',
            mime_type => 'mime_type',
            extension => 'extension',
            width     => 'width',
            height    => 'height',
            custom    => undef,
        }
	 );
	 ok($u, 'Uploader object creation');

     eval {
         my %entity_upload_extra = $u->store_upload(
             file_field  => 'test_file',
             src_file    => 't/test_file.txt',
             uploaded_mt => 'test/plain',
             file_name   => 'test_file.txt',
             shared_meta => { custom => 'custom_value' },
             );
         };
    is($@,'', 'store_upload() survives');

    my $imgs_with_custom_value =$DBH->selectrow_array(
        "SELECT count(*) 
            FROM uploads 
            WHERE custom = 'custom_value'");
    is($imgs_with_custom_value,2, 'both parent and generated file have shared_meta');

    # testing transform_meta
    my $img_href = $DBH->selectrow_hashref("SELECT * FROM uploads WHERE upload_id = 1");

    my %meta =  $u->transform_meta( 
        meta   => $img_href,
        prefix => 'test',
        prevent_browser_caching => 1,
        fields => [qw/id url width height/],
    );

    is($meta{test_id}, 1,      'meta_hashref id');
    ok((not exists $meta{test_extension}), 'meta_hashref extension');
    like($meta{test_url}, qr!http://localhost/test/1.txt\?!, 'meta_hashref url');




