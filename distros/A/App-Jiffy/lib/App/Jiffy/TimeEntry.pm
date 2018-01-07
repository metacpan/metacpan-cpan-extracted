package App::Jiffy::TimeEntry;

use strict;
use warnings;

use Scalar::Util qw( blessed );
use MongoDB;
use MongoDB::OID;

use Moo;

my $collection = 'timeEntry';

has id => (
  is  => 'rw',
  isa => sub {
    die 'id must be a MongoDB::OID'
      unless blessed $_[0] and $_[0]->isa('MongoDB::OID');
  },
);

has start_time => (
  is  => 'rw',
  isa => sub {
    die 'start_time is not a DateTime object'
      unless blessed $_[0] and $_[0]->isa('DateTime');
  },
  default => sub {
    DateTime->now();
  },
);

has title => (
  is       => 'rw',
  required => 1,
);

has _duration => (
  is       => 'rw',
);

has cfg => ( is => 'ro', );

=head2 db

C<db> get the db handler from MongoDB

=cut

sub db {
  my $self   = shift;
  my $client = MongoDB::MongoClient->new;
  return $client->get_database( ( $self->cfg ) ? $self->cfg->{db} : 'jiffy' );
}

=head2 save

C<save> will commit the current state of the C<TimeEntry> to the database.

=cut

sub save {
  my $self     = shift;
  my $_id      = $self->id;
  my $document = {
    start_time => $self->start_time,
    title      => $self->title,
  };
  if ($_id) {

    # Update the existing record
    $self->db->get_collection($collection)
      ->update( { _id => $self->id }, { '$set' => $document } );
  } else {

    # Insert new record
    $_id = $self->db->get_collection($collection)->insert($document);

    # Update id
    $self->id($_id);
  }
}

=head2 duration

C<duration> returns the time between this entry and the next.

=cut

sub duration {
  my $self = shift;
  my $set = shift;

  if ($set) {
    $self->_duration($set);
  }

  if ($self->_duration) {
    return $self->_duration;
  }

  my @entry_after = App::Jiffy::TimeEntry::search(
    $self->cfg,
    query => {
      start_time => {
        '$gt' => $self->start_time,
      },
    },
    sort => {
      start_time => 1,
    },
    limit => 1,
  );

  if (@entry_after) {
    return $entry_after[0]->start_time->subtract_datetime( $self->start_time );
  } else {
    return DateTime->now->subtract_datetime( $self->start_time );
  }
}

=head2 find

C<find> will return a single document. The query will use the provided C<_id>.

=cut

sub find {
  my $cfg = shift;
  my $_id = shift;

  my $client = MongoDB::MongoClient->new;
  my $entry  = $client->get_database( $cfg->{db} )->get_collection($collection)
    ->find_one( { _id => $_id } );
  return unless $entry;
  return App::Jiffy::TimeEntry->new(
    id         => $entry->{_id},
    title      => $entry->{title},
    start_time => $entry->{start_time},
    cfg        => $cfg,
  );
}

=head2 search C<$config> C<%options>...

C<search> will return an array of TimeEntry that fit the given C<%options>.

C<%options> can include the following:

=over

=item C<query>

This is the query syntax available via L<MongoDB::Collection>.

=item C<sort>

If present, the results will be sorted via the hashref given by this option.

=item C<limit>

If present, the results will limited to the number provided.

=back

=cut

sub search {
  my $cfg     = shift;
  my %options = @_;
  my $query   = $options{query};
  my $sort    = $options{sort};
  my $limit   = $options{limit};

  my $client  = MongoDB::MongoClient->new;
  my $entries = $client->get_database( $cfg->{db} )->get_collection($collection)
    ->find($query);

  if ($sort) {
    $entries = $entries->sort($sort);
  }

  if ($limit) {
    $entries = $entries->limit($limit);
  }

  # Return undef if nothing was found
  return unless $entries;

  my $LocalTZ = DateTime::TimeZone->new(name => 'local'); # For caching

# @TODO create a subclass of the MongoDB cursor that allows chaining of results like MongoDB
  map {
    $_->{start_time}->set_time_zone($LocalTZ); # Convert to local tz
    App::Jiffy::TimeEntry->new(
      id         => $_->{_id},
      title      => $_->{title},
      start_time => $_->{start_time},
      cfg        => $cfg,
      )
  } $entries->all;
}

=head2 last_entry

C<last_entry> will return the last TimeEntry in the db.

=cut

sub last_entry {
  my $cfg = shift;

  my $client = MongoDB::MongoClient->new;
  my $entry  = $client->get_database( $cfg->{db} )->get_collection($collection)
    ->find->sort( { start_time => -1 } )->limit(1)->next;
  return unless $entry;
  return App::Jiffy::TimeEntry->new(
    id         => $entry->{_id},
    title      => $entry->{title},
    start_time => $entry->{start_time},
    cfg        => $cfg,
  );
}

=head2 TO_JSON

C<TO_JSON> will return the entry as a JSON convertible hash.

=cut

sub TO_JSON {
  my $self = shift;

  {
    start_time => $self->start_time->iso8601,
    title => $self->title,
    duration => {
      $self->duration->deltas
    },
  }
}

1;
