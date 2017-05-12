#
# This file is part of CatalystX-ExtJS-REST
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package # hide
TestSchema::ResultSet::FindOrDefault;

use strict;
use warnings;

use base qw/DBIx::Class::ResultSet/;
use Carp qw/ croak /;

=head1 DESCRIPTION


=head1 PUBLIC METHODS

=cut

sub find_or_default {
    my ($self, $id) = @_;

    # Find by primary key
    # Caution;
    # Works only for tables with a single column primary key.
    my $exists = $self->find( $id );

    return defined $exists ? $exists : $self->default_result;
}


=head2 new_result

 Title   : new_result
 Usage   : Gets the resultset with deleted objects
 Function: Returns a reference to the unrestricted resultset that still
           contains the deleted records or undef if non was saved.

           For more informations look at '_subquery_start'.
 Example : $restricted_rs->_get_rs_before_restricting_deleted;
 Returns : unrestricted resultset
 Args    : none

=cut

sub new_result {
    my ($self, $values) = @_;

    if (not defined $values) {
        # We don't pass values for the row object, use defaut values
        $values = $self->_get_default_values();
    }

    # $values:
    # $VAR1 = {
    #           'website' => '',
    #           'name' => '',
    #           'uuid' => undef,
    #           'historic_id' => undef,
    #           'modified' => undef,
    #           'subname' => '',
    #           'is_deleted' => undef,
    #           'id' => undef,
    #           'legalform_id' => 0
    #         };

    return $self->next::method( $values );
}

sub default_result {
    my ($self) = @_;

    # get defaut values
    my $values = $self->_get_default_values();

    return $self->new_result( $values );
}

sub _get_default_values {
    my ($self) = @_;
    my $default_values = {};

    # Get ResultSource object
    my $source = $self->result_source();

    # Get ordered list of columns
    my @columns = $source->columns;

    for my $column_name (@columns) {

        # Get default value
        # The default value is undef if not defined in ResultSet class
        $default_values->{$column_name} =
            $source->column_info($column_name)->{default_value};
    }

#     use Data::Dumper;
#     warn "setting default values" . Dumper($default_values);

    return $default_values;
}


1;
