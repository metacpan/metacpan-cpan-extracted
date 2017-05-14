package CatalystX::OAuth2::Store;
use Moose::Role;

# ABSTRACT: The API for oauth2 stores

requires qw(
  find_client
  client_endpoint
  create_client_code
  client_code_is_active
  activate_client_code
  deactivate_client_code
  create_access_token
  find_client_code
  verify_client_secret
  verify_client_token
);

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Store - The API for oauth2 stores

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
