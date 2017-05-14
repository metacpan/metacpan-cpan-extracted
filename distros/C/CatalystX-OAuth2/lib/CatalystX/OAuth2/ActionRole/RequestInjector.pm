package CatalystX::OAuth2::ActionRole::RequestInjector;
use Moose::Role;
use Moose::Util;

# ABSTRACT: A role for injecting oauth2 logic into a catalyst request object

use CatalystX::OAuth2::Request;

requires 'execute';
requires 'build_oauth2_request';

before execute => sub {
  my $self = shift;
  my ( $controller, $c ) = @_;
  my $req = $c->req;

  Moose::Util::ensure_all_roles( $req, 'CatalystX::OAuth2::Request',
    { rebless_params => { oauth2 => $self->build_oauth2_request(@_) } } );

};

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::ActionRole::RequestInjector - A role for injecting oauth2 logic into a catalyst request object

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
