package DBIx::Class::Result::ExternalAttribute;

use strict;
use warnings;
use Carp;

=head1 NAME

DBIx::Class::Result::ExternalAttribute - The great new DBIx::Class::Result::ExternalAttribute!

=head1 VERSION

Version 0.06

=cut

# version
our $VERSION = '0.06';

# use base
use base qw/ DBIx::Class Class::Accessor::Grouped /;

my $rh_klass_attribute_column = {};

=head1 SYNOPSIS

use attached model to store attribute.

for example artist result:

    package t::app::Main::Result::Artist;
    use base qw/DBIx::Class::Core/;
    __PACKAGE__->table('artist');
    __PACKAGE__->add_columns(
        "id",
        { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
        "name",
        {   data_type     => "varchar",
            default_value => "",
            is_nullable   => 0,
            size          => 255
        });
    __PACKAGE__->set_primary_key('id');

    __PACKAGE__->load_components(qw/ Result::ExternalAttribute Result::ColumnData /);
    __PACKAGE__->init_external_attribute(
        artist_attribute =>
          't::app::Main::Result::ArtistAttribute',
        'artist_id'
    );
    __PACKAGE__->register_relationships_column_data();

use a artist attribute result:

    package t::app::Main::Result::ArtistAttribute;
    use base qw/DBIx::Class::Core/;
    __PACKAGE__->table('artist_attribute');
    __PACKAGE__->add_columns(
        "artist_id",
        { data_type => "integer", is_nullable => 0 },
        "year_old",
        { data_type     => "integer", is_nullable   => 1});
    __PACKAGE__->set_primary_key('artist_id');
    __PACKAGE__->load_components(qw/ Result::ColumnData /);
    __PACKAGE__->belongs_to( artist => "t::app::Main::Result::Artist", 'artist_id');

    1;

with this configuration, you can call methods:

    $artist->get_column_data => get only columns of artist result

    $artist->get_column_data_with_attribute => get columns of Artist and ArtistAttribute result except artist_id

    #update with artist attributes
    $artist->update({name => "Me", year_old => 15});

    #create with artist attributes
    my $rh = t::app::Main::Result::Artist->prepare_params_with_attribute({name => "Me", year_old => 15});
    $schema->resultset('Artist')->create($rh);

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 rh_klass_attribute_column

accessor to init_external_attrinute HASH configuration

=cut

sub rh_klass_attribute_column {
    my ( $klass, $rel, $klass_attribute_column, $external_key ) = @_;
    croak "this function must be call with a class" unless defined $klass;
    if ( @_ == 4 ) {
        return $rh_klass_attribute_column->{$klass}->{$rel}->{'columns'} =
          $klass_attribute_column;
        return $rh_klass_attribute_column->{$klass}->{$rel}->{'external_key'} =
          $external_key;
    }
    if ( @_ == 2 ) {
        return $rh_klass_attribute_column->{$klass}->{$rel};
    }
    else {
        return $rh_klass_attribute_column->{$klass};
    }
}

=head2 init_external_attribute

init function, declare has one relationships

=cut

sub init_external_attribute {
    my ( $klass, $rel, $klass_attribute, $external_key ) = @_;

    # declare has_one relation
    $klass->has_one( $rel, $klass_attribute, $external_key );

    # create accessor for each column
#  $klass->mk_group_accessors(simple => $klass_attribute->columns);
    #init hash of attribute associate object
    my @columns;
    foreach my $col ( $klass_attribute->columns ) {
        push( @columns, $col ) unless $col eq $external_key;
    }
    $klass->rh_klass_attribute_column( $rel, \@columns, $external_key );
}

=head2 columns_data_with_attribute

columns_data_with_external_attribute is deprecated, please use get_column_data_with_attribute

=cut

sub columns_data_with_attribute {
    carp "columns_data_with_external_attribute is deprecated, please use get_column_data_with_attribute";
    my $self = shift;
    $self->get_column_data_with_attribute(@_);
}

=head2 get_column_data_with_attribute

extract column_data with attribute column

=cut

sub get_column_data_with_attribute {
    my $self      = shift;
    my $klass     = ref $self;
    my $rh_result = $self->get_column_data();
    foreach my $rel_attr ( keys %{ $klass->rh_klass_attribute_column } ) {
        my $rel_object = $self->$rel_attr;
        next unless defined $rel_object;
        my $rh_result_attribute = $self->$rel_attr->get_column_data();
        foreach my $col ( @{ $klass->rh_klass_attribute_column($rel_attr)->{'columns'} } ) {
            $rh_result->{$col} = $rh_result_attribute->{$col};
        }
    }

    return $rh_result;
}

=head2 prepare_params_with_attribute

prepare params for creation with attributes

=cut

sub prepare_params_with_attribute {
    my ( $klass, $rh_fields ) = @_;
    foreach my $rel ( keys %{ $klass->rh_klass_attribute_column } ) {
        foreach my $col ( @{ $klass->rh_klass_attribute_column($rel)->{'columns'} } ) {
            if ( defined $rh_fields->{$col} ) {
                $rh_fields->{$rel}->{$col} = $rh_fields->{$col};
                delete $rh_fields->{$col};
            }
        }
    }
    return $rh_fields;
}

=head2 update

overdefinition of update function

=cut

sub update {
    my ( $self, $rh_fields ) = @_;
    my $klass = ref $self;
    foreach my $rel ( keys %{ $klass->rh_klass_attribute_column } ) {
        foreach my $col ( @{ $klass->rh_klass_attribute_column($rel)->{'columns'} } ) {
            if ( defined $rh_fields->{$col} ) {
                $self->$rel->$col( $rh_fields->{$col} );
                delete $rh_fields->{$col};
            }
        }
    }
    return $self->next::method($rh_fields);
}

=head2 insert

overdefinition of update function

=cut
sub insert 
{
    my ( $self, @args ) = @_;
    my $klass = ref $self;
    $self->next::method(@args);
    foreach my $rel ( keys %{ $klass->rh_klass_attribute_column } ) {
        $self->find_or_create_related($rel, {});
    }
    return $self;
}

=head1 AUTHOR

Nicolas Oudard, C<< <nicolas at oudard.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-result-externalattribute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Result-ExternalAttribute>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Result::ExternalAttribute


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Result-ExternalAttribute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Result-ExternalAttribute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Result-ExternalAttribute>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Result-ExternalAttribute/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Nicolas Oudard.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DBIx::Class::Result::ExternalAttribute

