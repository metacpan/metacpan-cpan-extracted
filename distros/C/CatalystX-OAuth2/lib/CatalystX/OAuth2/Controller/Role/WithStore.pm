package CatalystX::OAuth2::Controller::Role::WithStore;
use Moose::Role;

# ABSTRACT: A role for providing oauth2 stores to controllers

has store => (
  does     => 'CatalystX::OAuth2::Store',
  is       => 'ro',
  required => 1
);

around BUILDARGS => sub {
  my $orig = shift;
  my $self = shift;
  my $args = $self->$orig(@_);
  return $args unless @_ == 2;
  my ($app) = @_;
  for ( $args->{store} ) {
    last unless defined and ref eq 'HASH';
    my $store_args = {%$_};
    my $class = delete $store_args->{class};
    $class = "CatalystX::OAuth2::Store::$class" unless $class =~ /^\+/;
    my ( $is_success, $error ) = Class::Load::try_load_class($class);
    die qq{Couldn't load OAuth2 store '$class': $error} unless $is_success;
    $args->{store} = $class->new( %$store_args, app => $app );
  }
  return $args;
};

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Controller::Role::WithStore - A role for providing oauth2 stores to controllers

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
