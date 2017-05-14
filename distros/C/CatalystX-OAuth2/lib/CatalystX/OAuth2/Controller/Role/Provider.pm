package CatalystX::OAuth2::Controller::Role::Provider;
use Moose::Role;
use MooseX::SetOnce;
use Moose::Util;
use Class::Load;

# ABSTRACT: A role for writing oauth2 provider controllers

with 'CatalystX::OAuth2::Controller::Role::WithStore';

has $_ => (
  isa       => 'Catalyst::Action',
  is        => 'rw',
  traits    => [qw(SetOnce)],
  predicate => "_has_$_"
) for qw(_request_auth_action _get_auth_token_via_auth_grant_action);

around create_action => sub {
  my $orig   = shift;
  my $self   = shift;
  my $action = $self->$orig(@_);
  if (
    Moose::Util::does_role(
      $action, 'Catalyst::ActionRole::OAuth2::RequestAuth'
    )
    )
  {
    $self->_request_auth_action($action);
  } elsif (
    Moose::Util::does_role(
      $action, 'Catalyst::ActionRole::OAuth2::GrantAuth'
    )
    )
  {
    $self->_get_auth_token_via_auth_grant_action($action);
  }

  return $action;
};

sub check_provider_actions {
  my ($self) = @_;
  die
    q{You need at least an auth action and a grant action for this controller to work}
    unless $self->_has__request_auth_action
      && $self->_has__get_auth_token_via_auth_grant_action;
}

after register_actions => sub {
  shift->check_provider_actions;
};

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Controller::Role::Provider - A role for writing oauth2 provider controllers

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
