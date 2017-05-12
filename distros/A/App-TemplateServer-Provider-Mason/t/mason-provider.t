use strict;
use warnings;
use Test::More tests => 3;

use ok 'App::TemplateServer::Provider::Mason';
use App::TemplateServer::Context;
use Directory::Scratch;

my $tmp = Directory::Scratch->new;
$tmp->mkdir('foo');
$tmp->touch('mason.html', 'Hello, <% $world %>!');

my $ctx = App::TemplateServer::Context->new( data => { world => 'world' } );
my $provider = App::TemplateServer::Provider::Mason->new(docroot => ["$tmp"]);
is_deeply [sort $provider->list_templates], [sort qw/mason.html/],
  'got all expected templates via list_templates';

sub is_rendered($$) { 
    my $out = $provider->render_template($_[0], $ctx);
    chomp $out;
    is $out,  $_[1],
      $_[2] || "$_[0] renders to $_[1]";
}

is_rendered 'mason.html', 'Hello, world!';
