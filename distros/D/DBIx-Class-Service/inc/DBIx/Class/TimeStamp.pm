#line 1
package DBIx::Class::TimeStamp;

use base qw(DBIx::Class);

use warnings;
use strict;

use DateTime;

our $VERSION = '0.05';

__PACKAGE__->load_components( qw/InflateColumn::DateTime/ );
__PACKAGE__->mk_classdata( 
    '__column_timestamp_triggers' => {
        on_update => [], on_create => []
    }
);

#line 47

sub add_columns {
    my $self = shift;

    # Add everything else, get everything setup, and then process
    $self->next::method(@_);
   
    my @update_columns = ();
    my @create_columns = ();

    foreach my $column ( $self->columns ) {
        my $info = $self->column_info($column);
        if ( $info->{data_type} =~ /^(datetime|date|timestamp)$/i ) {
            if ( $info->{set_on_update} ) {
                push @update_columns, $column;
            }
            if ( $info->{set_on_create} ) {
                push @create_columns, $column;
            }
        }
    }
    if ( @update_columns or @create_columns ) {
        my $triggers = {
            on_update => [ @update_columns ],
            on_create => [ @create_columns ],
        };
        $self->__column_timestamp_triggers($triggers);
    }
}

sub insert {
    my $self  = shift;
    my $attrs = shift;

    my $now  = $self->get_timestamp();

    my @columns = @{ $self->__column_timestamp_triggers()->{on_create} };

    foreach my $column ( @columns ) {
        next if defined $self->get_column( $column );
        my $accessor = $self->column_info($column)->{accessor} || $column;
        $self->$accessor($now);
    }
    
    return $self->next::method(@_);
}

sub update {
    my $self = shift;

    my $now  = $self->get_timestamp();
    my %dirty = $self->get_dirty_columns();
    my @columns = @{ $self->__column_timestamp_triggers()->{on_update} };

    foreach my $column ( @columns ) {
        next if exists $dirty{ $column };
        my $accessor = $self->column_info($column)->{accessor} || $column;
        $self->$accessor($now);
    }

    return $self->next::method(@_);
}

#line 121

sub get_timestamp {
    return DateTime->now
}

#line 141

1;

