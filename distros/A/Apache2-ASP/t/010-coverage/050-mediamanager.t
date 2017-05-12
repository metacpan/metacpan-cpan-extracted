#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::API;
my $api; BEGIN { $api = Apache2::ASP::API->new }

can_ok( $api, 'config' );
ok( $api, 'got an API object' );
isa_ok( $api, 'Apache2::ASP::API' );




# Try out our 'yay' handler:
{
  $api->ua->get('/handlers/upload01?mode=yay&file=sdf.txt');
}


# Make the file to upload:
my $upload_filename = '/tmp/asp-upload-test.txt';


# Upload a file and then download it:
{
  open my $ofh, '>', $upload_filename
    or die "Cannot open '$upload_filename' for writing: $!";
  for( 1...10_000 )
  {
    print $ofh "$_: This is a line of text\n";
  }# end for()
  close($ofh);

  my $uploadID = int(rand() * 1000) . ':' . int(rand() * 1000);
  my $res = $api->ua->upload("/handlers/upload01?mode=create&uploadID=$uploadID", [
    uploaded_file => [ $upload_filename ]
  ]);


  my ($file) = 'asp-upload-test.txt';
  $res = $api->ua->get("/handlers/upload01?file=$file");
  is( length($res->content) => (stat($upload_filename))[7], "Uploaded/Downloaded filesizes match" );
}


# Now update that file:
{
  my $uploadID = int(rand() * 1000) . ':' . int(rand() * 1000);
  my $res = $api->ua->upload("/handlers/upload01?mode=edit&uploadID=$uploadID", [
    uploaded_file => [ $upload_filename ]
  ]);
}


# Try downloading, but fail:
{
  my $res = $api->ua->get('/handlers/upload01?file=sdf.txt&do_fail_before_download=1');
  is(
    length( $res->content ) => 0,
    'Fail before download causes zero length download'
  );
}


# Now update that file with one even larger > 1M:
{
  open my $ofh, '>', $upload_filename
    or die "Cannot open '$upload_filename' for writing: $!";
  for( 1...1025 )
  {
    print $ofh "."x1024, "\n";
  }# end for()
  close($ofh);
  my $uploadID = int(rand() * 1000) . ':' . int(rand() * 1000);
  my $res = $api->ua->upload("/handlers/upload01?mode=edit&uploadID=$uploadID", [
    uploaded_file => [ $upload_filename ]
  ]);
  
  my ($file) = 'asp-upload-test.txt';
  $res = $api->ua->get("/handlers/upload01?file=$file");
  is( length($res->content) => (stat($upload_filename))[7], "Uploaded/Downloaded filesizes match" );
}



# Try out a mode that doesn't exist:
{
  $api->ua->get('/handlers/upload01?mode=no-existo&file=sdf.txt');
}


# Now delete the file:
{
  my $res1 = $api->ua->get('/handlers/upload01?file=asp-upload-test.txt&mode=delete&do_fail_before_delete=1');
  
  my $res = $api->ua->get('/handlers/upload01?file=asp-upload-test.txt&mode=delete');
  is( $res->is_success => 1 );
}


# Now try downloading that file again...should fail:
{
  my $res = $api->ua->get('/handlers/upload01?file=asp-upload-test.txt');
  is( $res->status_line => '404 Not Found' );
}


# Upload a file and then download it:
{
  my $upload_filename = '/tmp/test-file.pdf';
  open my $ofh, '>', $upload_filename
    or die "Cannot open '$upload_filename' for writing: $!";
  for( 1...1000 )
  {
    print $ofh "$_: This is a line of text\n";
  }# end for()
  close($ofh);

  my $uploadID = int(rand() * 1000) . ':' . int(rand() * 1000);
  my $res = $api->ua->upload("/handlers/upload01?mode=create&uploadID=$uploadID", [
    uploaded_file => [ $upload_filename ]
  ]);


  my ($file) = 'test-file.pdf';
  $res = $api->ua->get("/handlers/upload01?file=$file");
  is( length($res->content) => (stat($upload_filename))[7], "Uploaded/Downloaded filesizes match" );
}



