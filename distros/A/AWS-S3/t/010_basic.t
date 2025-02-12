#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More;
use Data::Dumper;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

use Carp 'confess';
$SIG{__DIE__} = \&confess;

plan skip_all => '$ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY} must both be defined to run this test'
	unless( $ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY} );

use_ok('AWS::S3');

my $s3 = AWS::S3->new(
  access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
  secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
  session_token     => $ENV{AWS_SESSION_TOKEN},
  region            => $ENV{AWS_REGION},
);

isa_ok $s3->ua, 'LWP::UserAgent';

cleanup();

ok my $owner = $s3->owner(), "s3.owner returns a value";
isa_ok $owner, 'AWS::S3::Owner';
ok $owner->id, 'owner.id';
ok $owner->display_name, 'owner.display_name';

my $bucket_name = $ENV{AWS_TEST_BUCKET} || "aws-s3-test-" . int(rand() * 1_000_000) . '-' . time() . "-foo";
ok my $bucket = $s3->add_bucket( name => $bucket_name, location => 'us-east-1' ), "created bucket '$bucket_name'";

#exit;
if( $bucket )
{

if(0) {
  # Try cloudfront integration if we've got it:
  eval { require AWS::CloudFront; require AWS::CloudFront::S3Origin; };
  die $@ if $@;
  unless( $@ )
  {
    my $cf = AWS::CloudFront->new(
      access_key_id     => $s3->access_key_id,
      secret_access_key => $s3->secret_access_key,
    );
    my $dist = $cf->add_distribution(
      Origin  => AWS::CloudFront::S3Origin->new(
        DNSName => $bucket->name . '.s3.amazonaws.com',
      )
    );
    $bucket->enable_cloudfront_distribution( $dist );
  }# end unless()
}

#  my $acl = $bucket->acl;
#  ok $bucket->acl( 'private' ), 'set bucket.acl to private';
#  is $acl, $bucket->acl, 'get bucket.acl returns private';

#  ok $bucket->location_constraint( 'us-east-1' ), 'set bucket.location_constraint to us-east-1';
#  is $bucket->location_constraint, 'us-east-1', 'get bucket.location returns us-east-1';
#  is $s3->bucket($bucket->name)->location_constraint, 'us-east-1', 'get bucket.location returns us-east-1 second time';

#  is $bucket->policy, '', 'get bucket.policy returns empty string';

  my $test_str = "This is the original value right here!"x20;
  my $filename = 'foo/bar.txt';
  ADD_FILE: {
    my $file = $bucket->add_file(
      key       => $filename,
      contents  => \$test_str
    );
    ok( $file, 'bucket.add_file() works' );
    unlike $file->etag, qr("), 'file.etag does not contain any double-quotes (")';
  };
  
  GET_FILE: {
    ok my $file = $bucket->file($filename), 'bucket.file(filename) works';
    is ${ $file->contents }, $test_str, 'file.contents is correct';
  };
  
  ADD_FILE_WITH_CODE: {
    my $text = "This is the content"x4;
    ok $bucket->add_file(
      key => 'code/test.txt',
      contents  => sub { return \$text }
    ), 'add file with code contents worked';
    ok my $file = $bucket->file('code/test.txt'), "got file back from bucket";
    is ${$file->contents}, $text, "file.contents on code is correct";
    $file->contents( sub { return \uc($text) } );
    is ${$file->contents}, uc($text), "file.contents on code is correct after update";
    
    $file->delete;
  };
  
  # Set contents:
  SET_CONTENTS: {
    my $new_contents = "This is the updated value"x10;
    ok my $file = $bucket->file($filename), 'bucket.file(filename) works';
    $file->contents( \$new_contents );
    
    # Now check it:
    is ${$bucket->file($filename)->contents}, $new_contents, "set file.contents works";
    
    # use alternative update method
    $new_contents = 'More new content';
    $file->update( contents => \$new_contents );
    is ${$bucket->file($filename)->contents}, $new_contents, "set file.update works";
  };
  
  DELETE_FILE: {
    eval { $bucket->delete };
    ok $@, 'bucket.delete fails when bucket is not empty.';
    like $@, qr/BucketNotEmpty/, 'error looks like BucketNotEmpty';
    ok $bucket->file($filename)->delete, 'file.delete';
    ok ! $bucket->file($filename), 'file no longer exists in bucket';
  };
  
  ADD_MANY_FILES: {
    my %info = ( );
    
    # Add the files:
    for( 0..25 )
    {
      my $contents  = "Contents of file $_\n"x4;
      my $key       = "bar/baz/foo." . sprintf("%03d", $_) . ".txt";
      $info{$key} = $contents;
      ok $bucket->add_file(
        key       => $key,
        contents  => \$contents,
      ), "Added file $_";
    }# end for()
    
    # Make sure they all worked:
    my $counted = 0;
    foreach my $key ( sort keys %info )
    {
      my $contents = $info{$key};
      ok my $file = $bucket->file($key), "bucket.file($key) returned a file";
      is $file->size, length($contents), 'file.size is correct';
      is ${$file->contents}, $contents, 'file.contents is correct';
      my $expiration_date = time() + 3600;
      my $url = $file->signed_url( $expiration_date );
      is( $file->signed_url( $expiration_date ),$url,'signed_url same' ) for 1 .. 10;
warn "--->$url";
      my $res = $s3->ua->get( $url );
      ok( $res->is_success,'get signed_url' );
      isnt( $res->code,403,'not forbidden' );
      last if $counted++ > 4;
    }# end for()
    
    # Try iterating through the files:
    my $iter = $bucket->files( page_size => 2, page_number => 1 );
    $counted = 0;
    while( my @files = $iter->next_page )
    {
      foreach my $file ( @files )
      {
        is ${$file->contents}, $info{$file->key}, "file(@{[$file->key]}).contents works on iterated files";
        last if $counted++ > 4;
      }# end foreach()
      last;
    }# end while()
    
    # Make sure that if we say we want to start on page 11, we *start* on page 11:
    $iter = $bucket->files( page_size => 1, page_number => 18 );
    SMALL_ITER: {
      for( 18..25 )
      {
        my ($file) = $iter->next_page;
        my $number = sprintf('%03d', $_);
        is $file->key, "bar/baz/foo.$number.txt", "file $number is what we expected";
      }# end for()
    };
    
    # How about when our page size is larger than what we get back from S3?:
#    $iter = $bucket->files( page_size => 105, page_number => 2 );
#    BIG_ITER: {
#      my @files = $iter->next_page;
#      for( 106..116 )
#      {
#        my $file = shift(@files);
#        is $file->key, "bar/baz/foo.$_.txt", "file $_ is what we expected";
#      }# end for()
#    };
    
    # Delete the files:
    ok($bucket->delete_multi( map { $_ } sort keys %info ), 'bucket.delete_multi(@keys)' );
    
    # Now make sure that not a single one still exists:
    foreach( sort keys %info )
    {
      ok ! eval {$bucket->file($_)}, "bucket(@{[ $bucket->name ]}).file($_) doesn't exist";
    }# end foreach()
#    map {
#      ok $bucket->file($_)->delete && ! $bucket->file($_), "bucket.file($_).delete worked"
#    } sort keys %info;
  };
  
  
  # proof content type reading and writing
  CONTENT_TYPE: {
    
    foreach my $ct( qw( text/plain image/jpeg application/zip ) ) {
      
      # write file with specific content type
      ( my $ct_name = $ct ) =~ s#/#-#;
      ok( $bucket->add_file(
        key         => "$ct_name.dat",
        contents    => \( 'This is '. $ct ),
        contenttype => $ct
      ), "Put file with content type $ct" );
      
      # read file
      my $ct_file = $bucket->file( "$ct_name.dat" );
      ok( $ct_file && $ct_file->contenttype eq $ct, 'Content type '. $ct. ' read' );
      
      # change content type
      $ct_file->update( contenttype => 'text/csv' );
      $ct_file = $bucket->file( "$ct_name.dat" );
      ok( $ct_file && $ct_file->contenttype eq 'text/csv', 'Content type '. $ct. ' changed to text/csv' );
      
      # remove file
      $ct_file->delete();
    }
  };
  
  # Cleanup:
  ok $bucket->delete, 'bucket.delete succeeds when bucket IS empty.';
}# end if()

cleanup();
done_testing();

sub cleanup
{
  warn "\nCleaning Up...\n";
  foreach my $bucket ( grep { $_->name =~ m{^(aws-s3-test\-\d+).+?foo$} } $s3->buckets )
  {
    warn "Bucket: ", $bucket->name, "\n";
    my $iter = $bucket->files( page_size => 100, page_number => 1 );
    while( my @files = $iter->next_page )
    {
$bucket->delete_multi( map { $_->key } @files );
#      foreach my $file ( @files )
#      {
#        warn "\tdelete: ", $file->key, "\n";
#        eval { $file->delete };
#      }# end foreach()
      $iter->page_number( 1 );
    }# end while()
    eval { $bucket->delete };
    $@ && do { warn $@ };
    warn "\n";
  }# end foreach()
}# end cleanup()


