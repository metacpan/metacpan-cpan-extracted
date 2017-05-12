package Data::Morph::Backend::DBIC;
$Data::Morph::Backend::DBIC::VERSION = '1.140400';
#ABSTRACT: Provides a Data::Morph backend for DBIx::Class

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose(':all');
use MooseX::Params::Validate;
use Devel::PartialDump('dump');
use namespace::autoclean;
use DBIx::Class;
use Scalar::Util('weaken');


has result_set =>
(
    is => 'ro',
    isa => class_type('DBIx::Class::ResultSet'),
    required => 1,
);


has auto_insert =>
(
    is => 'ro',
    isa => Bool,
    default => 0,
);


has new_instance =>
(
    is => 'ro',
    isa => CodeRef,
    lazy => 1,
    builder => '_build_new_instance',
);


sub _build_new_instance
{
    my ($self) = @_;
    weaken($self);
    return sub { $self->result_set->new_result({}) };
}


sub epilogue
{
    my ($self, $obj) = @_;

    $obj->update_or_insert
        if $self->auto_insert;
}

with 'Data::Morph::Role::Backend' =>
{
    input_type => class_type('DBIx::Class::Row'),
    get_val => sub
    {
        my ($obj, $key) = @_;
        if($obj->can($key))
        {
            return $obj->$key;
        }
        elsif($obj->has_column($key))
        {
            return +{$obj->get_inflated_columns}->{$key};
        }
        else
        {
            die "Can't find '$key' column in: " . dump($obj);
        }
    },
    set_val => sub
    {
        my ($obj, $key, $value) = @_;
        if($obj->can($key))
        {
            $obj->$key($value);
        }
        elsif($obj->has_column($key))
        {
            return $obj->set_inflated_columns({$key => $value});
        }
        else
        {
            die "Can't find '$key' column in: " . dump($obj);
        }
    }
};

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=head1 NAME

Data::Morph::Backend::DBIC - Provides a Data::Morph backend for DBIx::Class

=head1 VERSION

version 1.140400

=head1 DESCRIPTION

Data::Morph::Backend::DBIC implements a L<Data::Morph> backend that talks to a
database via DBIx::Class. New instances or rows are created from the passed in
L<DBIx::Class::ResultSet> to the constructor. Values are set and retrieved from
the row using the following logic: If there is an accessor, use it, if not, see
if it has a column, use inflated_columns methods, if not die. So directives
defined in the map for reading and writing should match either accessors or
column names

=head1 PUBLIC_ATTRIBUTES

=head2 result_set

    is: ro, isa: DBIx::Class::ResultSet, required: 1

This attribute holds the active ResultSet that should be used when creating new
rows

=head2 auto_insert

    is: ro, isa: Bool, default: false

During the execution of the L</epilogue>, this attribute is checked to see if
the newly created and populated instance should be inserted into the database

=head2 new_instance

    is: ro, isa: CodeRef, lazy: 1, builder: _build_new_instance

This attribute overrides what is provided in L<Data::Morph::Role::Backend> and
uses a builder method that returns a coderef that uses L</result_set> to return
a new row using L<DBIx::Class::ResultSet/new_result>

=head1 PUBLIC_METHODS

=head2 epilogue

    (DBIx::Class::Row)

This method implements L<Data::Morph::Role::Backend/epilogue>. It reads
L</auto_insert> to determine if the row should be inserted into the database.

=head1 PROTECTED_METHODS

=head2 _build_new_instance

This is the builder method for L</new_instance>. If special logic is needed in
creation of the instance factory, simply override or advise this method as
needed. By default, it returns a CodeRef that builds L<DBIx::Class::Row>
objects using L<DBIx::Class::ResultSet/new_result> upon the L</result_set>

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
