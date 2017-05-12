#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 68;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

use File::Temp;
use File::Basename;
BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

# test content name:
my $test_content1 = "content_test_content_1_$$";
my $test_content2 = "content_test_content_2_$$";
my $test_content3 = "content_test_content_3_$$";
# test properties:
my @test_properties;
# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );
# content object:
my $content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';

# Run tests:
ok( $content->add( $test_content1, \@test_properties ),
    "Content Test: Content \"$test_content1\" added successfully." );
ok( $content->check_exists( $test_content1 ),
    "Content Test: Content \"$test_content1\" exists." );
ok( ! $content->check_exists( "missing_$test_content1" ),
    "Content Test: Content \"missing_$test_content1\" should not exist." );

# Check copying:
ok( $content->copy( $test_content1, $test_content2 ),
    "Content Test: Content \"$test_content1\" copied to \"$test_content2\"." );
ok( $content->check_exists( $test_content2 ),
    "Content Test: Content \"$test_content2\" exists." );
ok( ! $content->copy( $test_content1, $test_content2 ),
    "Content Test: Can't copy content \"$test_content1\" to \"$test_content2\" without :replace." );
ok( $content->copy( $test_content1, $test_content2, 1 ),
    "Content Test: Can copy content \"$test_content1\" to \"$test_content2\" with :replace." );
ok( $content->check_exists( $test_content1 ),
    "Content Test: Content \"$test_content1\" exists." );
ok( $content->check_exists( $test_content2 ),
    "Content Test: Content \"$test_content2\" exists." );

# Check moving:
ok( $content->move( $test_content2, $test_content3 ),
    "Content Test: Content \"$test_content2\" moved to \"$test_content3\"." );
ok( $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" exists." );
ok( ! $content->check_exists( $test_content2 ),
    "Content Test: Content \"$test_content2\" no longer exists." );
ok( ! $content->move( $test_content1, $test_content3 ),
    "Content Test: Can't move content \"$test_content1\" to \"$test_content3\" without :replace." );
TODO: {
    local $TODO = "https://issues.apache.org/jira/browse/SLING-1648";
    ok( $content->move( $test_content1, $test_content3, 1 ),
        "Content Test: Can move content \"$test_content1\" to \"$test_content3\" with :replace." );
    ok( ! $content->check_exists( $test_content1 ),
        "Content Test: Content \"$test_content1\" no longer exists." );
}
ok( $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" exists." );

# Cleanup
# Remove this following delete when move with :replace starts working!
ok( $content->del( $test_content1 ),
    "Content Test: Content \"$test_content1\" deleted successfully." );
ok( $content->del( $test_content3 ),
    "Content Test: Content \"$test_content3\" deleted successfully." );
ok( ! $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" should no longer exist." );

# Recreate objects with user / pass set:
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;

# authn object:
$authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );
# content object:
$content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';

my ( $tmp_content_handle, $tmp_content_name ) = File::Temp::tempfile();
my $tmp_content_basename = basename $tmp_content_name;
print {$tmp_content_handle} "Test file\n";
# You need to flush the tmp content handle to actually write data
# out to the file on disk:
close $tmp_content_handle;
my $test_path = "content_test_path_$$";
ok( ! $content->upload_file($tmp_content_name,".."), 'Check upload_file function fails with remote path that is not allowed' );
ok( $content->upload_file($tmp_content_name,$test_path), 'Check upload_file function' );
ok( ! $content->view("$test_path/this_file_does_not_exist"), 'Check view function with non-existent file' );
ok( $content->view("$test_path/$tmp_content_basename"), 'Check view function' );
ok( $content->view_file("$test_path/$tmp_content_basename"), 'Check view file function' );
ok( ! $content->view_file("$test_path/this_file_does_not_exist"), 'Check view file function with non-existent file' );
throws_ok{ $content->view_file()} qr{No file to view specified!}, 'Check view_file function croaks with a missing remote path';
ok( $content->view_full_json("$test_path/$tmp_content_basename"), 'Check view_full_json function' );
ok( ! $content->view_full_json("$test_path/this_file_does_not_exist"), 'Check view_full_json function with non-existent file' );
throws_ok{ $content->view_full_json()} qr{No file to view specified!}, 'Check view_full_json function croaks with a missing remote path';
ok( $content->upload_file($tmp_content_name,$test_path,$test_content1), 'Check upload_file function with filename specified' );
ok( $content->view("$test_path/$test_content1"), 'Check view function on named file' );
ok( $content->view_file("$test_path/$test_content1"), 'Check view file function on named file' );

my $upload = "$tmp_content_name\n";
throws_ok{ $content->upload_from_file(\$upload)} qr{Problem parsing content to add}, 'Check upload_file function croaks with a missing remote path';
$upload = "$tmp_content_name,$test_content1\n";
ok( $content->upload_from_file(\$upload,0,1), 'Check upload_from_file function' );
my ( $tmp_content2_handle, $tmp_content2_name ) = File::Temp::tempfile();
$upload .= "$tmp_content2_name,$test_content2\n";
ok( $content->upload_from_file(\$upload,1,2), 'Check upload_from_file function with two forks' );
unlink($tmp_content_name);
unlink($tmp_content2_name);
throws_ok{ $content->upload_from_file($tmp_content_name,0,1)} qr{Problem opening file: '$tmp_content_name'}, 'Check upload_file function croaks with a missing file';

# Add content item to manipulate:
ok( my $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'add'} = \$test_content1;
$content_config->{'remote'} = \$test_content1;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function adding content $test_content1} );

# Test content additions from file:
my ( $tmp_content_additions_handle, $tmp_content_additions_name ) = File::Temp::tempfile();
ok( $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'additions'} = \$tmp_content_additions_name;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function additions} );
unlink( $tmp_content_additions_name ); 

# Test viewing content:
ok( $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'view'} = \1;
$content_config->{'remote'} = \$test_content1;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function viewing content $test_content1} );

# Test copying and moving content:
ok( $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'copy'} = \1;
$content_config->{'remote-source'} = \$test_content1;
$content_config->{'remote'} = \$test_content2;
ok( ! Apache::Sling::Content->run($sling,$content_config), q{check content_run function copying content $test_content1 to $test_content2} );

ok( $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'move'} = \1;
$content_config->{'remote-source'} = \$test_content2;
$content_config->{'remote'} = \$test_content3;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function moving content $test_content2 to $test_content1} );

# Test uploading file:
( $tmp_content_handle, $tmp_content_name ) = File::Temp::tempfile();
ok( $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'local'} = \$tmp_content_name;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function with only local defined} );
$content_config->{'remote'} = \$test_content2;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function uploading content $tmp_content_name to $test_content2} );

# Cleanup content:
unlink($tmp_content_name);
ok( $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'delete'} = \1;
$content_config->{'remote'} = \$test_content1;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function deleting content $test_content1} );
$content_config->{'remote'} = \$test_content2;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function deleting content $test_content2} );
$content_config->{'remote'} = \$test_content3;
ok( Apache::Sling::Content->run($sling,$content_config), q{check content_run function deleting content $test_content3} );

ok( $content_config = Apache::Sling::Content->config($sling), 'check content_config function' );
$content_config->{'exists'} = \1;
$content_config->{'remote'} = \$test_content1;
ok( ! Apache::Sling::Content->run($sling,$content_config), q{check content_run function exists test for $test_content1} );

ok( ! $content->check_exists( $test_content1 ),
    "Sling Test: Content \"$test_content1\" should no longer exist." );
ok( ! $content->check_exists( $test_content2 ),
    "Sling Test: Content \"$test_content2\" should no longer exist." );
ok( ! $content->check_exists( $test_content3 ),
    "Sling Test: Content \"$test_content3\" should no longer exist." );
