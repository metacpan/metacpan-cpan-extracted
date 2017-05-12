use strict;
use warnings;
use Test::More tests => 3;

use ok 'App::TemplateServer::Provider::Null';
use App::TemplateServer::Context;


my $ctx = App::TemplateServer::Context->new( data => { foo => 'bar' } );
my $provider = App::TemplateServer::Provider::Null->new(docroot => [qw/random crap/]);

is_deeply [$provider->list_templates], [qw/this is a test/];
like $provider->render_template('some thing', $ctx), 
  qr/This is a template called some thing.*(?:random.*crap|crap.*random)/s;
