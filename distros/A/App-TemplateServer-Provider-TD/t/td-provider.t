package My::Template;
use base 'Template::Declare';
use Template::Declare::Tags;

template simple => sub {
    html {
        head {};
        body { "Hello, world!" };
    };
};

package main;
use strict;
use warnings;
use Test::More tests => 3;

use ok 'App::TemplateServer::Provider::TD';
use App::TemplateServer::Context;

my $provider = App::TemplateServer::Provider::TD->new(docroot => ['My::Template']);

is_deeply [$provider->list_templates], ['simple'];
like $provider->render_template('simple', {}), qr{<body>Hello, world.</body>};
