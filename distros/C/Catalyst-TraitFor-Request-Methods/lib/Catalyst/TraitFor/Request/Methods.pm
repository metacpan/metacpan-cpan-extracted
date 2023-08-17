package Catalyst::TraitFor::Request::Methods;

# ABSTRACT: Add enumerated methods for HTTP requests

use v5.14;

use Moose::Role;
use List::Util 1.33 qw/ none /;

use namespace::autoclean;

requires 'method';

our $VERSION = 'v0.5.2';


my @METHODS = qw/ get head post put delete connect options trace patch /;

for my $method (@METHODS) {
    has my $name = "is_" . $method => (
        is => 'ro',
        lazy => 1,
        default => sub {
            my ($self) = @_;
            my $this = lc $self->method =~ s/\W/_/gr;
            return $this eq $method;
        },
    );
}


has is_unrecognized_method => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $this = lc $self->method =~ s/\W/_/gr;
        return none { $this eq $_ } @METHODS;
    },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::TraitFor::Request::Methods - Add enumerated methods for HTTP requests

=head1 VERSION

version v0.5.2

=head1 SYNOPSIS

In the L<Catalyst> class

  __PACKAGE__->config(
    request_class_traits => [
        'Methods'
    ]
  );

In any code that uses a L<Catalyst::Request>, e.g.

 if ($c->request->is_post) {
     ...
 }

=head1 DESCRIPTION

This trait adds enumerated methods from RFC 7231 and RFC 5789 for
checking the HTTP request method.

Using these methods is a less error-prone alternative to checking a
case-sensitive string with the method name.

In other words, you can use

  $c->request->is_get

instead of

  $c->request->method eq "GET"

The methods are implemented as lazy read-only attributes.

=head1 METHODS

=head2 is_get

The request method is C<GET>.

=head2 is_head

The request method is C<HEAD>.

=head2 is_post

The request method is C<POST>.

=head2 is_put

The request method is C<PUT>.

=head2 is_delete

The request method is C<DELETE>.

=head2 is_connect

The request method is C<CONNECT>.

=head2 is_options

The request method is C<OPTIONS>.

=head2 is_trace

The request method is C<TRACE>.

=head2 is_patch

The request method is C<PATCH>.

=head2 is_unrecognized_method

The request method is not recognized.

=head1 SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

=head1 SEE ALSO

L<Catalyst::Request>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Catalyst-TraitFor-Request-Methods->
and may be cloned from L<git://github.com/robrwo/Catalyst-TraitFor-Request-Methods-.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Catalyst-TraitFor-Request-Methods-/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2023 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
