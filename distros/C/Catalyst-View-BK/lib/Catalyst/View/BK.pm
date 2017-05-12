package Catalyst::View::BK;
use strict;
use warnings;
use Bricklayer::Templater;
use base qw/Catalyst::View/;
use Carp;
use NEXT;

__PACKAGE__->mk_accessors('engine');
__PACKAGE__->mk_accessors('context');

=head1 NAME

Catalyst::View::BK - Catalyst View for Bricklayer::Templater

=head1 DESCRIPTION

Catalyst View. Implements the Bricklayer Templating engine for Catalyst

=head1 AUTHOR

Jeremy Wall <Zaphar> (Jeremy@marzhillstudios.com)


=head1 Catalyst::View::BK Configuration

Bricklayer attempts to use sane defaults so in reality you don't 
need to specify anything here if you don't want to.

If you do want to override the defaults then there are two
configuration values you can override. The Tag Identifier and the
Template Extension.

    APP->config(
        name     => 'APP',
        root     => APP->path_to('root');,
        'View::BK' => {
            # any BK configurations items go here
           'bk_ext' => 'txml',
	   'bk_tag_id' => 'BK'
	},
    );
 
=cut

=head1 Methods

=cut

my $VERSION = '0.2';

sub new { #initialize view here
	#Use next to overload the base classes new method?
	my ($class, $c, $args) = @_;
	my $self = $class->NEXT::new($c);
    
    #BK expects a Context, WD, and Tag Identifier
    my $template = Bricklayer::Templater->new($self, $c->config->{root});
    
	$c->log->debug('our BK::config: '. ref($self->config()))
		if $c->debug;
	$c->log->debug('our BK: '. ref($template))
		if $c->debug;
	
    $template->ext($c->config->{'View::BK'}{bk_ext});
	$template->identifier($c->config->{'View::BK'}{bk_tag_id});
	
    $self->context($c);
    $c->log->debug('context: '. ref($c))
		if $c->debug;
    $self->engine($template);
	return $self;	
}

sub process { #Process our templates;
	my ($self, $c) = @_;
	my $template = $c->stash->{template}
		|| $c->action;
	unless ($c->response->content_type) {
		$c->response->content_type('text/html');
	}
	my $result = $self->render($c, $template);
}

=head2 render

Allows you to render a template and retrieve the result. It also allows you
to specify the arguments passed to the template engine and to override the
tag id by setting the $c->stash->{bk_tag_id} parameter before calling it.

=cut

sub render { # actually render our template 
	my ($self, $c, $template, $args) = @_;
	
    $c->log->debug('processing template: '. $template)
		if $c->debug;
	#TODO convert the args to use $c instead ala Template Toolkit
	my $params = $args || $c;
    $self->engine()->run_templater($template, $params);
    my $current = $c->response->body();
    $c->response->body($current.$self->engine->_page());
	$self->engine->clear();
    return;
}

1;

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

