use Test::More;
use strict;
use warnings;

use Articulate::TestEnv;
use Articulate::Service::Simple;
use Articulate::Syntax qw(new_request);
use FindBin;
my $app = app_from_config();

my $service = Articulate::Service::Simple->new( { app => $app } );

sub req { new_request @_ }

my $creation_response = $service->handle_create(
  req create => {
    location => '/zone/public/article/hello-world',
    content  => 'foo',
  }
);

is( $creation_response->http_code, 200, 'Can create content' );

my $retrieval_response = $service->handle_read(
  req read => {
    location => '/zone/public/article/hello-world',
  }
);

is( $retrieval_response->http_code, 200, 'Can read content' );
like( $retrieval_response->data->{article}->{content},
  qr/foo/, 'Content reads ok' );

my $edit_response = $service->handle_update(
  req update => {
    location => '/zone/public/article/hello-world',
    content  => 'bar',
  }
);

is( $edit_response->http_code, 200, 'Can edit content' );
like( $edit_response->data->{article}->{content},
  qr/bar/, 'Edited content reads ok' );

my $deletion_response = $service->handle_delete(
  req delete => {
    location => '/zone/public/article/hello-world',
  }
);

is( $deletion_response->http_code, 200, 'Can delete content' );

done_testing;
