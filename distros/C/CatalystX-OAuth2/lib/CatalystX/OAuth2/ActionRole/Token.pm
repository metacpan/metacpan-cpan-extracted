package CatalystX::OAuth2::ActionRole::Token;
use Moose::Role;
use JSON::Any;

# ABSTRACT: A role for building token-building actions

with 'CatalystX::OAuth2::ActionRole::RequestInjector';

my $json = JSON::Any->new;

after execute => sub {
  my ( $self, $controller, $c ) = @_;
  $c->res->body( $json->objToJson( $c->req->oauth2->query_parameters ) );
};

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::ActionRole::Token - A role for building token-building actions

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
