use strict;
use Test::More;
Test::More->builder->no_ending( 1 );
use Config;
use CGI::Simple;

$| = 1;

BEGIN {
  if ( !$Config{d_fork} ) {
    plan skip_all => "fork not available on this platform";
  }

  eval "use HTTP::Request::Common";
  plan skip_all => "HTTP::Request::Common not available"
   if $@;

  plan tests => 1;
}

my $req = HTTP::Request::Common::POST(
  '/dummy_location',
  Content_Type => 'form-data',
  Content      => [ test_file => ["t/090.14838.t"], ]
);

# Useful in simulating an upload.
$ENV{REQUEST_METHOD} = 'POST';
$ENV{CONTENT_TYPE}   = $req->header( 'Content-type' );
$ENV{CONTENT_LENGTH} = $req->content_length;
if ( open( CHILD, "|-" ) ) {
  print CHILD $req->content;
  close CHILD;
  exit 0;
}

$CGI::Simple::DISABLE_UPLOADS = 0;

my $q = CGI::Simple->new;
is $q->cgi_error, undef, "CGI::Simple can handle this";

