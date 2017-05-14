package CatalystX::OAuth2::ActionRole::Grant;
use Moose::Role;

# ABSTRACT: Integrate an action with an oauth2 request

with 'CatalystX::OAuth2::ActionRole::RequestInjector';

after execute => sub {
  my($self, $controller, $c) = @_;
  return unless $c->req->oauth2->has_approval;
  my $uri = $c->req->oauth2->next_action_uri($controller, $c);
  $c->res->redirect($uri);
};

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::ActionRole::Grant - Integrate an action with an oauth2 request

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
