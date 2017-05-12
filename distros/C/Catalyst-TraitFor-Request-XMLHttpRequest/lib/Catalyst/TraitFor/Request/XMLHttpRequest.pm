package Catalyst::TraitFor::Request::XMLHttpRequest;
our $VERSION = '0.01';
# ABSTRACT: A request trait for XMLHttpRequest detection support

use Moose::Role;
use MooseX::Types::Moose qw(Bool);
use namespace::autoclean;


has is_xhr => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_xhr',
);

sub _build_is_xhr {
    my ($self) = @_;
    my $req_with = $self->header('X-Requested-With');

    return 0 unless defined $req_with;
    return 0 if $req_with ne 'XMLHttpRequest';
    return 1;
}

1;

__END__
=pod

=head1 NAME

Catalyst::TraitFor::Request::XMLHttpRequest - A request trait for XMLHttpRequest detection support

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Setting up the request trait for your application:

    package MyApp;

    use Moose;
    use CatalystX::RoleApplicator;
    use namespace::autoclean;

    extends 'Catalyst';

    __PACKAGE__->apply_request_class_roles(qw(
        Catalyst::TraitFor::Request::XMLHttpRequest
    ));

    __PACKAGE__->setup;

    1;

Using the trait in your controllers

    sub some_action : Path('foo') {
        my ($self, $ctx) = @_;

        # do something depending on the request being an XMLHttpRequest or not
        if ($ctx->request->is_xhr) {
            ...
        }
        else {
            ...
        }
    }

=head1 DESCRIPTION

This request trait adds support for detecting XMLHttpRequests to the Catalyst
request.

=head1 ATTRIBUTES

=head2 is_xhr

This attribute contains a boolean value indicating whether or not the request
is a XMLHttpRequest.

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

