package Catalyst::ActionRole::MatchRequestMethod;
BEGIN {
  $Catalyst::ActionRole::MatchRequestMethod::VERSION = '0.03';
}
# ABSTRACT: Dispatch actions based on HTTP request methods

use Moose::Role;
use Perl6::Junction 'none';
use namespace::autoclean;


requires 'attributes';

around match => sub {
    my ($orig, $self, $ctx) = @_;
    my @methods = @{ $self->attributes->{Method} || [] };

    # if no request methods have been specified, we still match normally. that
    # doesn't feel very correcy, but dwims very well, especially if you're
    # applying the role to all actions using the controller config. this might
    # be subject to change.
    return 0 if @methods && $ctx->request->method eq none @methods;

    return $self->$orig($ctx);
};


1;

__END__
=pod

=head1 NAME

Catalyst::ActionRole::MatchRequestMethod - Dispatch actions based on HTTP request methods

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use Moose;
    use namespace::autoclean;

    BEGIN {
        extends 'Catalyst::Controller::ActionRole';
    }

    __PACKAGE__->config(
        action_roles => ['MatchRequestMethod'],
    );

    sub get_foo    : Path Method('GET')                { ... }
    sub update_foo : Path Method('POST')               { ... }
    sub create_foo : Path Method('PUT')                { ... }
    sub delete_foo : Path Method('DELETE')             { ... }
    sub foo        : Path Method('GET') Method('POST') { ... }

=head1 DESCRIPTION

This module allows you to write L<Catalyst> actions which only match certain
HTTP request methods. Actions which would normally be dispatched to will not
match if the request method is incorrect, allowing less specific actions to
match the path instead.

=head1 SEE ALSO

L<Catalyst::Controller::ActionRole>

L<Catalyst::Action::REST>

inspired by: L<http://dev.catalystframework.org/wiki/gettingstarted/howtos/HTTP_method_matching_for_actions>

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

