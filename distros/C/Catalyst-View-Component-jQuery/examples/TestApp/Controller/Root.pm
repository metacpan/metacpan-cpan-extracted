package TestApp::Controller::Root;

use strict;
use warnings;

use Catalyst;
use base 'Catalyst::Controller';

use CatalystX::Menu::Suckerfish;

__PACKAGE__->config(namespace => q{});

sub begin :Private {
    my ( $self, $c ) = @_;

    my $suckerfish = CatalystX::Menu::Suckerfish->new(
        context => $c,
        ul_id => 'navmenu',
        ul_class => 'sf-menu',
        menupath_attr => 'MenuPath',
        menutitle_attr => 'MenuTitle',
        text_container => {
            element => 'span',
            attrs => { class => 'sf-label' },
        },
        add_nodes => [
            {
                menupath => '/Other sites/Google',
                menutitle => 'Google',
                uri => 'http://google.com',
            },
            {
                menupath => '/Other sites/Yahoo',
                menutitle => 'Yahoo',
                uri => 'http://yahoo.com',
            },
        ],
    );

    $c->view('TT')->jquery->construct_plugin(
        name => 'Superfish',
        target_selector => 'ul.sf-menu',
        use_supersubs => 1,
        options =>
'delay : 500,
animation : { opacity : "show" },
dropShadows : true',
        supersubs_options =>
'minWidth : 12,
maxWidth : 13,
extraWidth : 1',
    );

    $c->stash(menu => $suckerfish->output);
}

sub end :Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::TT') unless $c->res->body;
}

sub index
    :Path
    :MenuPath('/Home')
    :MenuTitle('Home Page')
    {
    my ( $self, $c ) = @_;
}

sub dostuff
    :Local
    :MenuPath('/Stuff')
    :MenuTitle('Do Stuff')
    {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'index.tt2';
    $c->forward('index');
}

sub prettypix
    :Local
    :MenuPath('/Pretty/Pictures')
    :MenuTitle('See pretty pictures')
    {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'index.tt2';
    $c->forward('index');
}

sub printtemplate
    :Local
    :MenuPath('/How it works/The template')
    :MenuTitle('The template')
    {
    my ( $self, $c ) = @_;
    my $text;
    { local (@ARGV, $/) = 'TestApp/root/src/index.tt2'; $text = <> }
    $c->res->content_type('text/plain');
    $c->res->body($text);
}

1;

