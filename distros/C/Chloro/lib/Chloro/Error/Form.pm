package Chloro::Error::Form;
BEGIN {
  $Chloro::Error::Form::VERSION = '0.06';
}

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

use Chloro::Field;

with 'Chloro::Role::Error';

has message => (
    is       => 'ro',
    isa      => 'Chloro::ErrorMessage',
    required => 1,
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An error associated with a specific field



=pod

=head1 NAME

Chloro::Error::Form - An error associated with a specific field

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    for my $error ( $resultset->form_errors() ) {
        print $error->error()->message();
    }

=head1 DESCRIPTION

This class represents an error associated with the form as a whole, not a
specific field.

=head1 METHODS

This class has the following methods:

=head2 $error->message()

Returns a L<Chloro::ErrorMessage> object.

=head1 ROLES

This object does the L<Chloro::Role::Error> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

