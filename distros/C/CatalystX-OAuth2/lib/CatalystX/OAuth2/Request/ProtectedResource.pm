package CatalystX::OAuth2::Request::ProtectedResource;
use Moose::Util::TypeConstraints;
use Moose;
with 'CatalystX::OAuth2';

# ABSTRACT: An oauth2 protected resource request implementation

has token =>
  ( isa => duck_type( [qw(as_string owner)] ), is => 'ro', required => 1 );

sub _build_query_parameters {{}}

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Request::ProtectedResource - An oauth2 protected resource request implementation

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
