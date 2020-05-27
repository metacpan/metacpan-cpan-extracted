package Data::AnyXfer::Elastic::Import::File;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use Carp;
use Class::Load ( );


=head1 NAME

Data::AnyXfer::Elastic::Import::File - Role representing import data
in storage

=head1 SYNOPSIS

    # store some data in the "file" entry

    My::File->does('Data::AnyXfer::Elastic::Import::File')
        or croak 'Class must consume our role!';

    my $file =
       My::File->new( ..storage info... );

    $file->add(qw/
        this is a list of multiple data items within a single storage record
    /);


    # and then...

    my $file = My::File->new( ..same storage info... );

    my @items;
    push @items, $data while ( my $data = $file->get );

    print join(' ', @items);
    # prints
    # >"this is a list of multiple data items within a single storage record"

=head1 DESCRIPTION

This role represents a C<Data::AnyXfer::Elastic> "file" for import
data. A "file" in this sense relates to a file in a filing system.
A collection of data under a common "tab" / name.

The interface allows the storage and retrieval of data. Details of actual
storage and persistence are handled by the
L<Data::AnyXfer::Elastic::Import::Storage> backend.

=head1 SEE ALSO

L<Data::AnyXfer::Elastic::Import::Storage>

=cut

=head1 PACKAGE METHODS

=cut

# ADDITIONAL CONSTRUCTORS


=head2 from

Synonym for L</create>.

=cut

sub from { return shift->create(@_); }


=head2 create

my $file =
Data::AnyXfer::Elastic::Import::File->create( ...args... );

Package method for creating C<File> instances. This method will guess which
file implementation / subclass you require by the arguments you supply.

Currently this method supports returning two types of file object:

=over

=over

=item L<Data::AnyXfer::Elastic::Import::File::Simple>

=item L<Data::AnyXfer::Elastic::Import::File::MultiPart>

=back

=back

This methods supports all arguments accepted by any of the underlying
supported file implementations.

It also allows a hint arg, C<multi_part>, a C<BOOLEAN>, which can be
used to force a multipart file return.

=cut

sub create {

    my ( $class, %args ) = @_;

    # detect if the file is multi part or simple
    my $target_class = delete $args{multi_part} || defined $args{part_size}
        ? 'Data::AnyXfer::Elastic::Import::File::MultiPart'
        : 'Data::AnyXfer::Elastic::Import::File::Simple';

    # make sure the relevant class is loaded
    Class::Load::load_class($target_class);
    # return a new instance
    return $target_class->new(%args);
}


=head1 AS A ROLE

=head2 METHODS REQUIRED

=cut


# FILE INTERFACE DEFINITION


=head3 add

    $file->add(@multiple_bits_of_data);

    # or...

    $file->add('test string');

Takes a list of values to store under the current "file". Multiple calls are
additive, as the name implies.

Returns a boolean indicating success or failure. Failure would usually be
due to particular details of the storage backend. You should ideally die
from these errors inside the storage backend or within your implementation
of L</add>, in which case this method should always return 1, or die.

=cut

requires 'add';


=head3 get

    my @multiple_bits_of_data;
    push @multiple_bits_of_data, $data while ( my $data = $file->get );

    # or...

    my $string = $file->get;

Returns the next data value contained within this file instance. This method
acts as an iterator, returning undef once all values have been returned.

=cut

requires 'get';


=head3 clear

    $file->clear;

Deletes all data held within this "file" instance.
Returns a boolean indicating success or failure.

=cut

requires 'clear';


=head3 reset

    $file->reset;
    my $first_data_piece = $file->get;

Resets the current iteration position back to the start of the "file" record.
See L</get>.

Always returns 1 (always succeeds).

=cut

requires 'reset';



1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

