package Coat::Persistent::Object;
use Coat;
use Coat::Persistent;
use Coat::Persistent::Types;

has_p 'created_at' => (
    isa => 'Class::Date',
    store_as => 'DateTime',
);

has_p 'updated_at' => (
    isa => 'Class::Date',
    store_as => 'DateTime',
);

before 'save' => sub {
    my ($self) = @_;
    $self->created_at(time) unless $self->created_at;
    $self->updated_at(time);
};

'Coat::Persistent::Object';
__END__
=pod

=head1 NAME

Coat::Persistent::Object - root object for Coat::Persistent models

=head1 DESCRIPTION

This class is meant to be a default root object for Coat::Persistent models.
It provides through inheritance default attributes (that must exist in the
underlying table) and default hooks and methods.

=head1 USAGE

You just have to make your models inherit from Coat::Persistent::Object like
the following :

    package MyModel;
    use Coat;
    use Coat::Persistent;
    extends 'Coat::Persistent::Object';

    1;

=head1 ATTRIBUTES

Any model that inherits from this class must wrap a table that owns the
following fields:

=over 4

=item B<created_at> : a 'DateTime' field that contains the date when the entry
was inserted in the database (automatically updated). This attribute is stored
as a DateTime entry and is returned as a Class::Date object.

=item B<updated_at> : a 'DateTime' field that contains the date when the entry
was last updated.This attribute is stored as a DateTime entry and is returned
as a Class::Date object.

=back

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org>


=cut

