package Catalyst::ControllerRole::View;

use Moose::Role;
use Scalar::Util;
use String::CamelCase;

requires 'ctx';

our %global_content_prefixes = (
  'HTML' => ['application/xhtml+xml', 'text/html'],
  'JSON' => ['application/json'],
  'XML' => ['application/xml', 'text/xml'],
  'JS' => ['application/javascript', 'text/javascript'],
);

sub view {
  my ($self, @args) = @_;
  return $self->ctx->stash->{current_view_instance} if exists($self->ctx->stash->{current_view_instance}) && !@args;
  return $self->view_for($self->ctx->action, @args);
}

sub view_at {
  my ($self, $view_name_proto, @args) = @_;
  my ($view_name, $view_fragment) = split(/\./, $view_name_proto);

  push @args, view_fragment => $view_fragment if $view_fragment;
  $view_name = "@{[$self->path_prefix]}/$view_name" if $self->path_prefix;
  my $namepart = String::CamelCase::camelize($view_name);
  $namepart =~s/\//::/g;

  my $view = $self->_build_view_name($namepart);
  $self->ctx->log->debug("Initializing View: $view") if $self->ctx->debug;
  return $self->ctx->view($view, @args);
}

sub view_for {
  my ($self, $proto, @args) = @_;
  my ($action_proto, $view_fragment) = split(/\./, $proto);
  
  push @args, view_fragment => $view_fragment if $view_fragment;
  my $action = Scalar::Util::blessed($action_proto) ?
    $action_proto :
      $self->action_for($action_proto);

  return $self->view_at($proto, @args) unless $action; # Not sure if this is right

  my $action_namepart = $self->_action_namepart_from_action($action);
  my $view = $self->_build_view_name($action_namepart);

  $self->ctx->log->debug("Initializing View: $view") if $self->ctx->debug;
  return $self->ctx->view($view, @args);
}

sub _action_namepart_from_action {
  my ($self, $action) = @_;
  my $action_namepart = String::CamelCase::camelize($action->reverse);
  $action_namepart =~s/\//::/g;
  return $action_namepart;
}

sub _build_view_name {
  my ($self, $action_namepart) = @_;

  my $accept = $self->ctx->request->headers->header('Accept');
  my $available_content_types = $self->_content_negotiation->{content_types};
  my $content_type = $self->_content_negotiation->{negotiator}->choose_media_type($available_content_types, $accept);
  my $matched_content_type = $self->_content_negotiation->{content_types_to_prefixes}->{$content_type};

  $self->ctx->log->warn("no matching type for $accept") unless $matched_content_type;
  $self->ctx->detach_error(406, +{error=>"Requested not acceptable."}) unless $matched_content_type;
  $self->ctx->log->debug( "Content-Type: $content_type, Matched: $matched_content_type") if $self->ctx->debug;

  my $view = $self->_view_from_parts($matched_content_type, $action_namepart);
  return $view;
}

sub _view_from_parts {
  my ($self, @view_parts) = @_;
  my $view = join('::', @view_parts);
  $self->ctx->log->debug("Negotiated View: $view") if $self->ctx->debug;
  return $view;
}

has '_content_negotiation' => (is => 'ro', required=>1);

sub process_component_args {
  my ($class, $app, $args) = @_;

  my $n = HTTP::Headers::ActionPack->new->get_content_negotiator;
  my %content_prefixes = (
    %global_content_prefixes,
    %{ delete($args->{content_prefixes}) || +{} },
  );
  my @content_types = map { @$_ } values %content_prefixes;
  my %content_types_to_prefixes = map {
    my $prefix = $_; 
    map {
      $_ => $prefix
    } @{$content_prefixes{$prefix}}
  } keys %content_prefixes;

  return +{
    %$args,
    _content_negotiation => +{
      content_prefixes => \%content_prefixes,
      content_types_to_prefixes => \%content_types_to_prefixes,
      content_types => \@content_types,
      negotiator => $n,
    },
  };
}

1;

=head1 NAME
 
Catalyst::ControllerRole::View - Call Views from your Controller

=head1 SYNOPSIS

    package Example::Controller::Register;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::ControllerPerRequest';
    with 'Catalyst::ControllerRole::View';


=head1 DESCRIPTION

Experimental role for L<Catalyst::ControllerPerRequest> that calls a view based on the
the namespace.  This is a work in progress and may change in the future.

I'm not documenting this more, if you can't follow the source you shouldn't be
using this.   I may trash it eventually.

=head1 ALSO SEE
 
L<Catalyst::Runtime>, L<Catalyst::Controller>

=head1 AUTHOR

    John Napiorkowski <jjnapiork@cpan.org>

=head1 COPYRIGHT
 
    2023

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
