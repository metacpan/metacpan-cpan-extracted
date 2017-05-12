package Business::Fixflo::Envelope;

=head1 NAME

Business::Fixflo::Envelope

=head1 DESCRIPTION

A class for a fixflo envelope, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;
use Business::Fixflo::Exception;

extends 'Business::Fixflo::Resource';

=head1 ATTRIBUTES

    Entity
    Errors
    HttpStatusCode
    HttpStatusCodeDesc
    Messages

There attributes are all required. When a Business::Fixflo::Envelope is
instantiated the Errors array will be checked and if it contains any data
a Business::Fixflo::Exception will be thrown.

=cut

has [ qw/
    Entity
    Errors
    HttpStatusCode
    HttpStatusCodeDesc
    Messages
/ ] => (
    is       => 'rw',
    required => 1,
);

sub BUILD {
    my ( $self ) = @_;

    if ( @{ $self->Errors // [] } ) {
        Business::Fixflo::Exception->throw({
            message  => join( ', ',@{ $self->Errors } ) ,
            code     => $self->HttpStatusCode,
            response => $self->HttpStatusCodeDesc,
        });
    }

    return $self;
}

=head1 SEE ALSO

L<http://www.fixflo.com/Tech/API/V2/DTO#Envelope-T>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo

=cut

1;

# vim: ts=4:sw=4:et
