#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common;
use Test::More tests => 3;

use Dancer2::Core::Hook;

use File::Spec::Functions qw(rel2abs catfile splitdir);
use Dancer2::Template::Xslate;

my $views = rel2abs(catfile((splitdir(__FILE__, 1))[0], "views"));

my $txs = Dancer2::Template::Xslate->new(
    views  => $views,
    layout => "main.tx",
    config => { cache => 0 },
);

isa_ok $txs, "Dancer2::Template::Xslate";
ok(
    $txs->does("Dancer2::Core::Role::Template"),
    'The object does template processing.'
);

$txs->add_hook(
    Dancer2::Core::Hook->new(
        name => "engine.template.before_render",
        code => sub {
            my ($tokens) = @_;
            $tokens->{before_template_render} = 1;
        },
    )
);

$txs->add_hook(
    Dancer2::Core::Hook->new(
        name => "engine.template.before_layout_render",
        code => sub {
            my ($tokens, $content) = @_;

            $tokens->{before_layout_render} = 1;
            $$content .= "\ncontent added in before_layout_render";
        },
    )
);

$txs->add_hook(
    Dancer2::Core::Hook->new(
        name => "engine.template.after_layout_render",
        code => sub {
            my ($content) = @_;
            $$content .= "\ncontent added in after_layout_render\n";
        },
    )
);

$txs->add_hook(
    Dancer2::Core::Hook->new(
        name => "engine.template.after_render",
        code => sub {
            my ($content) = @_;
            $$content .= "content added in after_template_render";
        }
    )
);

{
    package Bar;
    use Dancer2;

    # set template engine for first app
    Dancer2->runner->apps->[0]->set_template_engine($txs);
    #app->default_config->{'template'} = 'Xslate';
    #setting template => 'Xslate';

    get '/' => sub { template index => { var => 42 } };
}

my $app    = Dancer2->psgi_app;
my $result = '[top]
var = 42
before_layout_render = 1
---
[index]
var = 42

before_layout_render =
before_template_render = 1
content added in after_template_render
content added in before_layout_render
---
[bottom]

content added in after_layout_render
';

test_psgi $app, sub {
    my $cb = shift;

    is(
        $cb->( GET '/' )->content,
        $result,
        '[GET /] Correct content with template hooks',
    );
};

