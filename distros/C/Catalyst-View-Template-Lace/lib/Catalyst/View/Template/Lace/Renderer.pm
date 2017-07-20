package Catalyst::View::Template::Lace::Renderer;

use Moo;
use HTTP::Status ();
use Catalyst::Utils;

extends 'Template::Lace::Renderer';

around 'prepare_component_attrs', sub {
  my ($orig, $self, @args) = @_;
  my %attrs = $self->$orig(@args);
  $attrs{ctx} = $self->ctx;
  return %attrs;
};

sub inject_http_status_helpers {
  my ($class) = @_;
  foreach my $helper( grep { $_=~/^http/i} @HTTP::Status::EXPORT_OK) {
    my $subname = lc $helper;
    my $code = HTTP::Status->$helper;
    my $codename = "http_".$code;
    eval "sub ${\$class}::${\$subname} { return shift->respond(HTTP::Status::$helper,\@_) }";
    eval "sub ${\$class}::${\$codename} { return shift->respond(HTTP::Status::$helper,\@_) }";
  }
}

sub ctx { shift->model->ctx }

sub catalyst_component_name { shift->model->catalyst_component_name }

sub respond {
  my ($self, $status, $headers) = @_;
  $self->_profile(begin => "=> ".Catalyst::Utils::class2classsuffix($self->catalyst_component_name)."->respond($status)");
  for my $r ($self->ctx->res) {
    $r->status($status) if $r->status != 200; # Catalyst sets 200
    $r->content_type('text/html') if !$r->content_type;
    $r->headers->push_header(@{$headers}) if $headers;
    $r->body($self->render);
  }
  $self->_profile(end => "=> ".Catalyst::Utils::class2classsuffix($self->catalyst_component_name)."->respond($status)");
  return $self;
}

sub _profile {
  my $self = shift;
  $self->ctx->stats->profile(@_)
    if $self->ctx->debug;
}

# Support old school Catalyst::Action::RenderView for example (
# you probably also want the ::ArgsFromStash role).

sub process {
  my ($self, $c, @args) = @_;
  $self->response(200, @args);
}

# helper methods

sub overlay_view {
  my ($self, $view_name, $dom_proto, @args) = @_;
  if( (ref($dom_proto)||'') eq 'CODE') {
    local $_ = $self->dom;
    @args = ($dom_proto->($self->dom), @args);
    $self->dom->overlay(sub {
      my $new =  $self->view($view_name, @args, content=>$_)
        ->get_processed_dom;
      return $new;
    });
  } elsif($dom_proto->can('each')) {
    $dom_proto->each(sub {
      return $self->overlay_view($view_name, $_, @args);
    });
  } else {
    $dom_proto->overlay(sub {
      return $self->view($view_name, @args, content=>$_)
        ->get_processed_dom;
    });
  }
  return $self;
}

# proxy methods 

sub detach { shift->ctx->detach(@_) }

sub view { shift->ctx->view(@_) }

# Helpers

__PACKAGE__->inject_http_status_helpers;

1;

=head1 NAME

Catalyst::View::Template::Lace::Renderer - Adapt Template::Lace for Catalyst

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Subclass of L<Template::Lace:Renderer> with some useful, L<Catalyst> specific
methods.

=head1 METHODS

This class defines the following public methods

=head2 respond

    $view->respond($status);
    $view->respond($status, @headers);
    $view->respond(@headers);
 
 
Used to setup a response.  Calling this method will setup an http status, finalize
headers and set a body response for the HTML.  Content type will be set to
'text/html' automatically.  Status is 200 unless you specify otherwise.

=head2 overlay_view

Helper method to allow you to wrap or overlay the current view with another
view (like a master page view or some other transformation that you prefer
to have under the control of the controller).  Example:

  $c->view('User',
    name => 'John',
    age => 42,
    motto => 'Why Not?')
  ->overlay_view(
    'Master', sub {
      my $user_dom = shift; # also $_ is localised to this for ease of use
      title => $_->at('title')->content,
      css => $_->find('link'),
      meta => $_->find('meta'),
      body => $_->at('body')->content}, @more_args_for_MasterView)
  ->http_ok;

Although you can do this via the template with components there might be cases
where you want this under the controller.  For example you might use different
wrappers based on the logged in user (although again smart use of components could
solve that as well; the choice is yours).

=head2 detach

Proxy to '$c->detach'

=head2 view

Proxy to '$c->detach'

=head2 ctx

Proxy to '$c->ctx'

=head1 Reponse Helpers

We map status codes from L<HTTP::Status> into methods to make sending common
request types more simple and more descriptive.  The following are the same:
 
    $c->view->respond(200, @args);
    $c->view->http_ok(@args);
 
    do { $c->view->respond(200, @args); $c->detach };
    $c->view->http_ok(@args)->detach;
 
See L<HTTP::Status> for a full list of all the status code helpers.
 
=head1 AUTHOR
 

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Template::Lace>, L<Catalyst::View::Template::Lace>

=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
