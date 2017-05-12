#########################
# This test is basically a copy of t/basic.t
# with CGI::Simple substituted for CGI.pm

use Test::More;
Test::More->builder->no_ending(1);
use Carp::Assert;
use Config;
use Data::Dumper;
use DBI;
use Test::DatabaseRow;
use HTTP::Request::Common;
use lib 't/lib';
use CGI::Uploader::Test; # provides setup() read_file(), etc
use strict;

$| = 1;

if (! $Config{d_fork} ) {
    plan skip_all => "fork not available on this platform";
}
else {
    eval {
           require CGI::Simple;
           import CGI::Simple qw(-upload);
    };
    if($@) {
        plan skip_all => 'CGI::Simple not available'
    }
    else {
        plan skip_all => 'CGI::Simple should work, but having these tests for it work is
            pending a bug fix: http://rt.cpan.org/NoAuth/Bug.html?id=14838';
        #plan tests => 23;
    }
}

my ($DBH,$drv) = setup();


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


use CGI::Uploader;

	 my %imgs = (
		'test_file' => { 
            gen_files => {
                'test_file_gen' => {
                    transform_method => \&test_gen_transform,
                }
            },
        },
	 );

     my $q = new CGI::Simple;
	 my $u = 	CGI::Uploader->new(
		updir_path=>'t/uploads',
		updir_url=>'http://localhost/test',
		dbh => $DBH,
		query => $q,
		spec => \%imgs,
	 );
	 ok($u, 'Uploader object creation');

     my $form_data = $q->Vars;
     use Data::Dumper;
     warn Dumper ($form_data);


 	 my ($entity);
	 eval { $entity = $u->store_uploads($form_data) };
	 is($@,'', 'calling store_uploads');


	ok(not(grep {m/^(test_file)$/} keys %$entity),
           'store_uploads entity removals work');

	my @files = <t/uploads/*>;	
	ok(scalar @files == 2, 'expected number of files created');

    my $id_of_test_file_parent = 1;
    my $id_of_test_file_gen    = 2;

    my $new_file_contents = read_file("t/uploads/$id_of_test_file_gen.asc"); 
    like($new_file_contents,qr/gen/, "generated file is as expected");

	$Test::DatabaseRow::dbh = $DBH;
	row_ok( sql   => "SELECT * FROM uploads ORDER BY upload_id LIMIT 1",
                tests => {
					'eq' => {
						mime_type => 'text/plain',
						extension => '.txt',
					},
					'=~' => {
						upload_id => qr/^\d+/,
					},
				} ,
                label => "reality checking a database row");

	my $row_cnt = $DBH->selectrow_array("SELECT count(*) FROM uploads ");
	is($row_cnt,2, 'number of rows in database');


# test fk_meta()
{
    # mysql has a funny way of quoting
    # my $qt = ($drv eq 'mysql') ? '`' : '"'; 
    ok($DBH->do(qq!INSERT INTO cgi_uploader_test (item_id,test_file_id,test_file_gen_id) 
        VALUES (1, $id_of_test_file_parent,
                 $id_of_test_file_gen)!), 'test data insert');

 	my $tmpl_vars_ref = $u->fk_meta(
         table   => 'cgi_uploader_test',
         where   => {item_id => 1},
         prefixes => [qw/test_file test_file_gen/]);
 
 	ok (eq_set(
 			[qw/
                test_file_url 
                test_file_id
 
                test_file_gen_url 
                test_file_gen_id
 			/],
 			[keys %$tmpl_vars_ref],
 		), 'fk_meta keys returned') || diag Dumper($tmpl_vars_ref);
 
     row_ok( sql   => "SELECT * FROM uploads  WHERE upload_id= $id_of_test_file_gen",
                 tests => [ 
 					mime_type        => 'text/plain',
 					extension        => '.asc',
 				    width	         => undef,		
 					height	         => undef,
 					gen_from_id      => $id_of_test_file_parent,
 					],
                 label => "upload for thumb of generated test file is all good");

}

    my $LoH = $DBH->selectall_arrayref("SELECt * FROM uploads",{Slice=>{}});

# # Simulate another upload, 
{
              my %entity_upload_extra = $u->store_upload(
                  file_field    => 'test_file',
                  src_file      => 't/200x200.gif',
                  uploaded_mt   => 'image/gif',
                  file_name     => '200x200.gif',
                  id_to_update  => $id_of_test_file_parent,
              );
 
          row_ok( sql   => "SELECT * FROM uploads  WHERE upload_id= $id_of_test_file_parent",
              tests => [ 
              mime_type       => 'image/gif',
              extension       => '.gif',
              width	          => 200,		
              height	      => 200,
              gen_from_id     => undef,
              ],
              label =>
              "image that had the ID of the test file should house a 200x200 image");
}

{
 	ok((!-e 't/uploads/1.txt'), 'after replacing a file, the extension changes') || diag read_file('t/uploads/1.txt');
}

{
 	my $found_old_thumbs = $DBH->selectcol_arrayref("
 			SELECT upload_id FROM uploads WHERE upload_id IN ($id_of_test_file_gen)");
 	is(scalar @$found_old_thumbs,0, 
 	  'The original generated files of the test file should be deleted');
}
 
{
   my $how_many_thumbs = $DBH->selectrow_array("SELECT 
 		count(upload_id) FROM uploads WHERE gen_from_id = $id_of_test_file_parent");
 	is($how_many_thumbs,1,	
 		'1 new thumbnail for this image should have been generated');
}


{
 	 $q->param('test_file_delete',1);
 	 $q->param('test_file_id',$id_of_test_file_parent);
 	 my @deleted_field_ids = $u->delete_checked_uploads;

    my @cmp_array = (\@deleted_field_ids,['test_file_id', 'test_file_gen_id']);
 	 ok(eq_set(@cmp_array), 
         'delete_checked_uploads returned field ids') || diag Dumper (@cmp_array);

 	 @files = <t/uploads/*>;	
 
 	ok(scalar @files == 0, 'expected number of files removed') || diag Dumper (\@files);
 	$row_cnt = $DBH->selectrow_array("SELECT count(*) FROM uploads ");
 	ok($row_cnt == 0, "Expected number of rows remaining:  ($row_cnt)");
}

 
