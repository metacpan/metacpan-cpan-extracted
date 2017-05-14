package Catalyst::View::Semantic;
# ABSTRACT: Catalyst View for Template::Semantic
use Moose;
use Template::Semantic;
use Data::Page::Pageset();
use namespace::autoclean;

extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

has path => (
    is => 'ro',
    default => sub { shift->_application->path_to('root','template') }
);

has engine => (
    is => 'ro',
    default => sub { shift->engine_class->new },
    lazy => 1
);

has engine_class => (
    is => 'ro',
    default => sub { "Template::Semantic" }
);

has template_extension => (
    is => 'ro',
    default => sub { 'html' }
);

has content_type => (
    is => 'ro',
    default => sub { 'text/html' }
);

has process_key => (
    is => 'ro',
    default => sub { 'view' }
);

has template_key => (
    is => 'ro',
    default => sub { 'template' }
);

has title_key => (
    is => 'ro',
    default => sub { 'title' }
);

has css_key => (
    is => 'ro',
    default => sub { 'css' }
);

has js_key => (
    is => 'ro',
    default => sub { 'js' }
);

has jscode_key => (
    is => 'ro',
    default => sub { 'jscode' }
);

has css_uri => (
    is => 'ro',
    default => sub { '/static/css' }
);

has js_uri => (
    is => 'ro',
    default => sub { '/static/js' }    
);

has wrapper => (
    is => 'ro',
    default => sub { sub { layout => { body => shift } } }
);

has pager_template => (
    is => 'ro',
    default => sub { 'pager' }
);

sub process {
    my ($self, $c, $code, $file) = @_;
    my $result = $self->render(
        $file || $c->stash->{$self->template_key} || $c->action,
        $code || $c->stash->{$self->process_key} || {}
    );
    $c->response->body( $self->wrapper ? $self->layout( $self->wrapper->($result), $c->stash )->as_string : $result->as_string );
    $c->response->content_type($self->content_type) unless $c->response->content_type;
}

sub render {
    my ($self, $file, $code) = @_;
    $self->engine->process( 
        $self->path.'/'.$file.'.'.$self->template_extension,
        $code 
    );
}

# layout wrapper
sub layout {
    my ($self, $file, $code, $meta) = @_;
    $self->render( $file, {
        '//head' => {
            'title' => $meta->{$self->title_key},
            './script[last()-1]' => @{$meta->{js}} ? [map { '@src' => $self->js_uri.'/'.$_.'.js' }, @{$meta->{$self->js_key}}] : undef,
            './link[last()]' => @{$meta->{css}} ? [map { '@href' => $self->css_uri.'/'.$_.'.css'}, @{$meta->{$self->css_key}}] : undef,
            $meta->{jscode} ? (
                './script[last()]' => sub { $_ =~ s/\/\*code\*\//$meta->{$self->jscode_key}/; \$_ }
            ) : ()
        },
        '//html' => $code
    } );
}

# pager
sub pager {
    my ($self, $c, $pager, $template) = @_;
    my $pageset = Data::Page::Pageset->new( $pager );
    $self->render( ( $template || $self->pager_template ) => {
        'a.next' => $pager->next_page ? { '@href' => $c->req->uri_with({ page => $pager->next_page }) } : sub {},
        'a.prev' => $pager->previous_page ? { '@href' => $c->req->uri_with({ page => $pager->previous_page }) } : sub {}, 
        'span a' => [ map {
            '.' => $_,
            '@href' => $c->req->uri_with({ page => $_ }),
            $_ eq ($c->req->params->{page} || 1) ? ('@class' => 'current' ) : ()
        }, ($pageset->current_pageset->first .. $pageset->current_pageset->last) ]
    } );
}

__PACKAGE__->meta->make_immutable;
1;
