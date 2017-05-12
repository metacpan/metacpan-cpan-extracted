package Chloro::Error::Field;
BEGIN {
  $Chloro::Error::Field::VERSION = '0.06';
}

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

use Chloro::Field;

with 'Chloro::Role::Error';

has field => (
    is       => 'ro',
    isa      => 'Chloro::Field',
    required => 1,
);

has result => (
    is       => 'rw',
    writer   => '_set_result',
    isa      => 'Chloro::Result::Field',
    weak_ref => 1,
);

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

Chloro::Error::Field - An error associated with a specific field

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $errors = $resultset->result_for('field')->errors();

    for my $message ( @{$errors} ) {
        print $message->field()->name();
        print ': ';
        print $message->error()->text();
    }

=head1 DESCRIPTION

This class represents an error associated with a field.

=head1 METHODS

This class has the following methods:

=head2 $error->field()

Returns the L<Chloro::Field> object associated with this error.

=head2 $error->result()

Returns the L<Chloro::Result::Field> object associated with this error. This
is a weak reference, so it could return C<undef>.

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

