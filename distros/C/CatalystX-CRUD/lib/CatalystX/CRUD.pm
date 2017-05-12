package CatalystX::CRUD;

use warnings;
use strict;
use Carp;

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD - CRUD framework for Catalyst applications

=head1 DESCRIPTION

This document is an overview of the CatalystX::CRUD framework and API.

CatalystX::CRUD provides a simple and generic API for Catalyst CRUD applications.
CatalystX::CRUD is agnostic with regard to data model and data input,
instead providing a common API that different projects can implement for
greater compatability with one another.

The project was born out of a desire to make Rose::HTML::Objects easy to use
with Rose::DB::Object and DBIx::Class ORMs, using the Catalyst::Controller::Rose
project. However, any ORM could implement the CatalystX::CRUD::Model API,
and any form management project could use the resulting CatalystX::CRUD::Model
subclass.

=head1 METHODS

This class provides some basic methods that Model and Object subclasses inherit.

=head2 has_errors( I<context> )

Returns true if I<context> error() method has any errors set or if the
C<error> value in stash() is set. Otherwise returns false (no errors).

=cut

sub has_errors {
    my $self = shift;
    my $c = shift or $self->throw_error("context object required");
    return
           scalar( @{ $c->error } )
        || $c->stash->{error}
        || 0;
}

=head2 throw_error( I<msg> )

Throws exception using Carp::croak (confess() if CATALYST_DEBUG env var
is set). Override to manage errors in some other way.

NOTE that if in your subclass throw_error() is not fatal and instead
returns a false a value, methods that call it will, be default, continue
processing instead of returning. See fetch() for an example.

=cut

sub throw_error {
    my $self = shift;
    my $msg = shift || 'unknown error';
    $ENV{CATALYST_DEBUG} ? Carp::confess($msg) : Carp::croak($msg);
}

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Zbigniew Lukasiak and Matt Trout for feedback and API ideas.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of CatalystX::CRUD
