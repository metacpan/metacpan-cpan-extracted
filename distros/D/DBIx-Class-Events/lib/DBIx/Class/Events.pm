package DBIx::Class::Events;

# ABSTRACT: Store Events for your DBIC Results
use version;
our $VERSION = 'v0.9.3'; # VERSION

use v5.10;
use strict;
use warnings;
use parent 'DBIx::Class';

use Carp;

__PACKAGE__->mk_classdata( events_relationship => 'events' );

sub event {
    my ($self, $event, $col_data) = @_;

    # Just calling $object->event shouldn't work
    croak("Event is required") unless defined $event;

    my %col_data = (
        $self->event_defaults($event, $col_data),

        # Ignore unknown columns when we enter the event.
        # TODO: optimize the ->columns call
        map { $_ => $col_data->{$_} }
            grep { exists $col_data->{$_} }
            $self->result_source
              ->related_source( $self->events_relationship )->columns,
    );

    return $self->create_related( $self->events_relationship,
        { %col_data, event => $event } );
}

sub event_defaults {}

sub state_at {
    my ($self, $time_stamp, @args) = @_;

    if (ref $time_stamp) {
        my $dtf = $self->result_source->schema->storage->datetime_parser;
        $time_stamp = $dtf->format_datetime( $time_stamp );
    }

    my $events = $self->search_related( $self->events_relationship );
    my $alias  = $events->current_source_alias;
    $events = $events->search( {
            "$alias.event" => { in => [qw( insert update delete )] },
            "$alias.triggered_on" => { '<=', $time_stamp },
        },
        {
            select   => [ "$alias.event", "$alias.details" ],
            order_by => [
                map {"$alias.$_ desc"} 'triggered_on',
                $events->result_source->primary_columns
            ],
        } )->search(@args);

    my $event = $events->next;
    return undef if !$event or $event->event eq 'delete';

    my %state;
    while ($event) {
        %state = ( %{ $event->details || {} }, %state );

        last if $event->event eq 'insert';
        $event = $events->next;
    }

    return \%state;
}

sub insert {
    my ( $class, @args ) = @_;

    my $self = $class->next::method(@args);

    my %inserted = $self->get_columns;
    $self->event( insert => { details => \%inserted } );

    return $self;
};

sub update {
    my ( $self, @args ) = @_;

    # Do this here instead of letting our parent do it
    # so that we can use get_dirty_columns.
    $self->set_inflated_columns(@args) if @args;

    my %changed = $self->get_dirty_columns;

    $self->next::method();    # we already set_inflated_columns

    $self->event( update => { details => \%changed } ) if %changed;

    return $self;
};

sub delete {
    my ( $self, @args ) = @_;

    # DBIx::Class::Row::delete has a special edge case for calling
    # delete as a class method, we however can't log it in that case.
    if ( ref $self ) {
        my %deleted = $self->get_columns;
        $self->event( delete => { details => \%deleted } );
    }

    return $self->next::method(@args);

};

1;

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Events - Store Events for your DBIC Results

=head1 VERSION

version v0.9.3

=head1 SYNOPSIS

    my $artist
        = $schema->resultset('Artist')->create( { name => 'Dead Salmon' } );
    $artist->events->count;    # is now 1, an 'insert' event

    $artist->change_name('Trout');    # add a name_change event
    $artist->update;    # An update event, last_name_change_id and name

    # Find their previous name
    my $name_change = $artist->last_name_change;
    print $name_change->details->{old}, "\n";

See C<change_name> and C<last_name_change> example definitions
in L</CONFIGURATION AND ENVIRONMENT>.

    # Three more name_change events and one update event
    $artist->change_name('Fried Trout');
    $artist->change_name('Poached Trout in a White Wine Sauce');
    $artist->change_name('Herring');
    $artist->update;

    # Look up all the band's previous names
    print "$_\n"
        for map { $_->details->{old} }
        $artist->events->search( { event => 'name_change' } );

    $artist->delete;    # and then they break up.

    # We can find out now when they broke up, if we remember their id.
    my $deleted_on
        = $schema->resultset('ArtistEvent')
        ->single( { artistid => $artist->id, event => 'delete' } )
        ->triggered_on;

    # Find the state of the band was just before the breakup.
    my $state_before_breakup
        = $artist->state_at( $deleted_on->subtract( seconds => 1 ) );

    # Maybe this is common,
    # so we have a column to link to who they used to be.
    my $previous_artist_id = delete $state_before_breakup->{artistid};

    # Then we can form a new band, linked to the old,
    # with the same values as the old band, but a new name.
    $artist = $schema->resultset('Artist')->create( {
        %{$state_before_breakup},
        previousid => $previous_artist_id,
        name       => 'Red Herring',
    } );

    # After a few more name changes, split-ups, and getting back together,
    # we find an event we should have considered, but didn't.
    my $death_event
        = $artist->event( death => { details => { who => 'drummer' } } );

    # but, we then go back and modify it to note that it was only a rumor
    $death_event->details->{only_a_rumour} = 1;
    $death_event->make_column_dirty('details'); # changing the hashref doesn't
    $death_event->update

    # And after even more new names and arguments, they split up again
    $artist->delete;

See L</CONFIGURATION AND ENVIRONMENT> for how to set up the tables.

=head1 DESCRIPTION

A framework for capturing events that happen to a Result in a table,
L</PRECONFIGURED EVENTS> are triggered automatically to track changes.

This is useful for both being able to see the history of things
in the database as well as logging when events happen that
can be looked up later.

Events can be used to track when things happen.

=over

=item when a user on a website clicks a particular button

=item when a recipe was prepared

=item when a song was played

=item anything that doesn't fit in the main table

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head2 event_defaults

A method that returns an even-sized list of default values that will be used
when creating a new event.

    my %defaults = $object->event_defaults( $event_type, \%col_data );

The C<$event_type> is a string defining the "type" of event being created.
The C<%col_data> is a reference to the parameters passed in.

No default values, but if your database doesn't set a default for
C<triggered_on>, you may want to set it to a C<< DateTime->now >> object.

=head2 events_relationship

An class accessor that returns the relationship to get from your object
to the relationship.

Default is C<events>, but you can override it:

    __PACKAGE__->has_many(
        'cd_events' =>
            ( 'MyApp::Schema::Result::ArtistEvents', 'cdid' ),
        { cascade_delete => 0 },
    );

    __PACKAGE__->events_relationship('cd_events');

=head2 Tables

=head3 Tracked Table

The table with events to be tracked in the L</Tracking Table>.

It requires the Component and L</events_relationship> in the Result class:

    package MyApp::Schema::Result::Artist;
    use base qw( DBIx::Class::Core );

    ...;

    __PACKAGE__->load_components( qw/ Events / );

    # A different name can be used with the "events_relationship" attribute
    __PACKAGE__->has_many(
        'events' => ( 'MyApp::Schema::Result::ArtistEvent', 'artistid' ),
        { cascade_delete => 0 },
    );

You can also add custom events to track when something happens.  For example,
you can create a method to add events when an artist changes their name:

    __PACKAGE__->add_column(
        last_name_change_id => { data_type => 'integer' } );

    __PACKAGE__->has_one(
        'last_name_change'        => 'MyApp::Schema::Result::ArtistEvent',
        { 'foreign.artisteventid' => 'self.last_name_change_id' },
        { cascade_delete          => 0 },
    );

    sub change_name {
        my ( $self, $new_name ) = @_;

        my $event = $self->event( name_change =>
                { details => { new => $new_name, old => $self->name } } );
        $self->last_name_change( $event );
        # $self->update; # be lazy and make our caller call ->update

        $self->name( $new_name );
    }

=head3 Tracking Table

This table holds the events for the L</Tracked Table>.

The C<triggered_on> column must either provide a C<DEFAULT> value
or you should add a default to L</event_defaults>.

    package MyApp::Schema::Result::ArtistEvent;

    use warnings;
    use strict;
    use JSON;

    use base qw( DBIx::Class::Core );

    __PACKAGE__->load_components(qw/ InflateColumn::DateTime /);

    __PACKAGE__->table('artist_event');

    __PACKAGE__->add_columns(
        artisteventid => { data_type => 'integer', is_auto_increment => 1 },
        artistid      => { data_type => 'integer' },

        # The type of event
        event         => { data_type => 'varchar' },

        # Any other custom columns you want to store for each event.

        triggered_on => {
            data_type     => 'datetime',
            default_value => \'NOW()',
        },

        # Where we store freeform data about what happened
        details => { data_type => 'longtext' },
    );

    __PACKAGE__->set_primary_key('artisteventid');

    # You should set up automatic inflation/deflation of the details column
    # as it is used this way by "state_at" and the insert/update/delete
    # events.  Does not have to be JSON, just be able to serialize a hashref.
    {
        my $json = JSON->new->utf8;
        __PACKAGE__->inflate_column( 'details' => {
            inflate => sub { $json->decode(shift) },
            deflate => sub { $json->encode(shift) },
        } );
    }

This L<C<belongs_to>|DBIx::Class::Relationship/belongs_to>
relationship is optional,
and the examples and tests assume if it exists,
it is not a real database-enforced foreign key
that will trigger constraint violations if the thing being tracked is deleted.

    # A path back to the object that this event is for,
    # not required unlike the has_many "events" relationship above
    __PACKAGE__->belongs_to(
        'artist' => ( 'MyApp::Schema::Result::Artist', 'artistid' ) );

You probably also want an index for searching for events:

    sub sqlt_deploy_hook {
        my ( $self, $sqlt_table ) = @_;
        $sqlt_table->add_index(
            name   => 'artist_event_idx',
            fields => [ "artistid", "triggered_on", "event" ],
        );
    }

=head1 PRECONFIGURED EVENTS

Automatically creates Events for actions that modify a row.

See the L</BUGS AND LIMITATIONS> of bulk modifications on events.

=over

=item insert

Logs all columns to the C<details> column, with an C<insert> event.

=item update

Logs dirty columns to the C<details> column, with an C<update> event.

=item delete

Logs all columns to the C<details> column, with a C<delete> event.

See the L</BUGS AND LIMITATIONS> for more information about
using this method with a database enforced foreign key.

=back

=head1 METHODS

=head2 event

Inserts a new event with L</event_defaults>:

    my $new_event = $artist->event( $event => \%params );

First, the L</event_defaults> method is called to build a list of values
to set on the new event.  This method is passed the C<$event> and a reference
to C<%params>.

Then, the C<%params>, filtered for valid L</events_relationship> C<columns>,
are added to the C<create_related> arguments, overriding the defaults.

=head2 state_at

Takes a timestamp and returns the state of the thing at that timestamp as a
hash reference.  Can be either a correctly deflated string or a DateTime
object that will be deflated with C<format_datetime>.

Returns undef if the object was not C<in_storage> at the timestamp.

    my $state = $schema->resultset('Artist')->find( { name => 'David Bowie' } )
        ->state_at('2006-05-29 08:00');

An idea is to use it to recreate an object as it was at that timestamp.
Of course, default values that the database provides will not be included,
unless the L</event_defaults> method accounts for that.

    my $resurrected_object
        = $object->result_source->new( $object->state_at($timestamp) );

See ".. format a DateTime object for searching?" under L<DBIx::Class::Manual::FAQ/Searching>
for details on formatting the timestamp.

You can pass additional L<search|DBIx::Class::ResultSet/search> conditions and
attributes to this method.  This is done in context of searching the events
table:

    my $state = $object->state_at($timestamp, \%search_cond, \%search_attrs);

=head1 BUGS AND LIMITATIONS

There is no attempt to handle bulk updates or deletes.  So, any changes to the
database made by calling
L<"update"|DBIx::Class::ResultSet/update> or L<"delete"|DBIx::Class::ResultSet/delete>
will not create events the same as L<single row|DBIx::Class::Row> modifications.  Use the
L<"update_all"|DBIx::Class::ResultSet/update_all> or L<"delete_all"|DBIx::Class::ResultSet/delete_all>
methods of the C<ResultSet> if you want these triggers.

If you create the C<belongs_to> relationship
described under L</Tracking Table>
as a database-enforced foreign key
then deleting from the tracked table will fail due to those constraints.

There are three required columns on the L</events_relationship> table:
C<event>, C<triggered_on>, and C<details>.  We should eventually make those
configurable.

=head1 SEE ALSO

=over

=item L<DBIx::Class::AuditAny>

=item L<DBIx::Class::AuditLog>

=item L<DBIx::Class::Journal>

=item L<DBIx::Class::PgLog>

=back

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2024 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__


1;
