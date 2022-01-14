#!perl

use strict;
use warnings;

use Test::More;
Test::More->builder->no_ending( 1 );
use Config;
use File::Spec;
use CGI::Simple;

$| = 1;

plan skip_all => "fork not available on this platform"
 unless $Config{d_fork};

eval { require HTTP::Request::Common; };

plan skip_all => 'HTTP::Request::Common not available' if $@;

plan tests => 1;

my $req = HTTP::Request::Common::POST(
  '/dummy_location',
  Content_Type => 'form-data',
  Content      => [
    test_file =>
     [ File::Spec->catfile( split /\//, "t/test_file.txt" ) ],
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

my $q = CGI::Simple->new;
is( $q->cgi_error, undef, "CGI::Simple can handle this" );

