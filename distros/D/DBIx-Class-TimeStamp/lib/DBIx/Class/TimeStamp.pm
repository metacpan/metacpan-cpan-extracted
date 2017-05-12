package DBIx::Class::TimeStamp;

use base qw(DBIx::Class);

use warnings;
use strict;

use DateTime;

our $VERSION = '0.14';

__PACKAGE__->load_components( qw/DynamicDefault InflateColumn::DateTime/ );

=head1 NAME

DBIx::Class::TimeStamp - DBIx::Class extension to update and create date and time based fields

=head1 DESCRIPTION

Works in conjunction with InflateColumn::DateTime to automatically set update
and create date and time based fields in a table.

=head1 SYNOPSIS

 package My::Schema;

 __PACKAGE__->load_components(qw( TimeStamp ... Core ));
 
 __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    t_created => { data_type => 'datetime', set_on_create => 1 },
    t_updated => { data_type => 'datetime',
        set_on_create => 1, set_on_update => 1 },
 );

Now, any update or create actions will update the specified columns with the
current time, using the DateTime inflator.  

This is effectively trigger emulation to get consistent behavior across
databases that either implement them poorly or not at all.

=cut

sub add_columns {
    my ($self, @cols) = @_;
    my @columns;

    while (my $col = shift @cols) {
        my $info = ref $cols[0] ? shift @cols : {};

        if ( delete $info->{set_on_create} ) {
            $info->{dynamic_default_on_create} = 'get_timestamp';
        }

        if ( delete $info->{set_on_update} ) {
            $info->{dynamic_default_on_update} = 'get_timestamp';

            if ( defined $info->{dynamic_default_on_create} and
                 $info->{dynamic_default_on_create} eq 'get_timestamp'
             ) {
                $info->{dynamic_default_on_update} = 'get_timestamp';
            }
        }

        push @columns, $col => $info;
    }

    return $self->next::method(@columns);
}

=head1 METHODS

=head2 get_timestamp

Returns a DateTime object pointing to now.  Override this method if you have
different time accounting functions, or want to do anything special.

The date and time objects in the database are expected to be inflated.  As such
you can be pretty flexible with what you want to return here.

=cut

sub get_timestamp {
    return DateTime->now
}

=head1 AUTHOR

J. Shirley <jshirley@gmail.com>

=head1 CONTRIBUTORS

Florian Ragwitz (Porting to L<DBIx::Class::DynamicDefault>)

LTJake/bricas

=head1 COPYRIGHT & LICENSE

Copyright 2009 J. Shirley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

