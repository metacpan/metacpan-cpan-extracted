package Database::Async::Query;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

=head1 NAME

Database::Async::Query - represents a single database query

=head1 SYNOPSIS

 my $query = Database::Async::Query->new(
  db => Database::Async->new(...),
 );

=head1 DESCRIPTION

A query:

=over 4

=item * has zero or more parameters

=item * accepts zero or more input rows

=item * returns zero or more output rows

=item * can be prepared or direct

=back

=head2 Creating queries

Queries are initiated from the L<Database::Async> instance; users
are not expected to instantiate L<Database::Async::Query> objects
directly.

 my $query = $db->query('select 1');

=head2 Passing parameters

Normally additional parameters for L<placeholders|http://bobby-tables.com/>
are passed when creating the query instance:

 my $query_with_parameters = $db->query('select name from users where id = ?', $id);

For prepared statements, query parameters can be bound and passed for each
execution, see L</Prepared queries> for more details.

=head2 Retrieving data

Methods prefixed with C<row_> each provide a L<Ryu::Source> which
emits events for each row returned from the query:

 $db->query(q{select * from a_table})
  ->row_hashrefs
  ->each(sub {
   say "Had ID $_->{id} with name $_->{name}"
  })->await;

=head2 Direct queries

A direct query is of the form:

 $db->query(q{select 1})

or

 $db->query(q{select * from some_table where id = ?}, $id)

and has all the information required to start the query.

=head2 Prepared queries

When the same query needs to be executed multiple times with different
parameters, it may be worth using a prepared query. This involves sending
the SQL for the query to the server so that it can parse the text and
prepare a plan. Once complete, you can then send a set of parameters
and have the server execute and return any results.

A prepared query involves two steps.

First, the query is created:

 my $query = $db->query(q{select * from some_table where id = ?});

Next, it will need to be prepared. This will fail if the query was
provided any parameters when initially constructed:

 $query->prepare(
  statement => 'xyz'
 );

Some engines allow a C<statement> parameter, others will ignore it.

After a call to L</prepare>, the query is marked as prepared and will
support the L</bind> and L</execute> methods. Once the query is prepared,
it is traditional to bind some variables to it:

 $query->bind(
  $var1, $var2, ...
 );

after which it can be executed:

 $query->execute(
  portal => 'abc'
 );

and any results can be extracted by the usual methods such as L</row_hashrefs>.

Again, some engines support named portals, others will ignore the parameter.

Since passing parameters is so common, you can combine the L</bind> and
L</execute> steps by passing an arrayref to L</execute>:

 $query->execute([ $first_value, ... ], portal => '');

Streaming of values via L<Ryu::Source> is also supported:

 $query->execute($src, portal => '');

Note that prepared queries will continue to emit values from the C<< row_* >>
source(s) until the query itself is discarded. The caller is expected to
keep track of any required mapping from input parameters to output rows.

A full example might look something like this:

 async sub name_by_user_id {
  my ($self, $id) = @_;
  my $q = await $self->{name_by_user_id} //= do {
   # Prepare the query on first call
   my $q = $self->db->query(q{select name from "site"."user" where id = ?});
   $q->prepare(
    statement => 'name_by_user_id'
   )
  };
  my ($name) = await $q->execute([ $id ])->single;
  return $name;
 }

=head2 Custom engine features

Different engines support additional features or events.

Once a query is scheduled onto an engine, it will resolve the L</engine> L<Future>
instance:

 my $query = $db->query('select * from some_table');
 my $engine = await $query->engine;
 $engine->source('notification')
  ->map('payload')
  ->say;

=head2 Cancelling queries

In cases where you want to terminate a query early, use the L</cancel> method.
This will ask the engine to stop query execution if already scheduled. For a query
which has not yet been assigned to an engine, the L</cancel> method will cancel
the schedule request.

=head2 Cursors

Cursors are handled as normal SQL queries.

 $db->txn(async sub {
  my ($txn) = @_;
  await $txn->query(q{declare c cursor for select id from xyz})->void;
  say while await $txn->query(q{fetch next from c})->single;
  await $txn->query(q{close c})->void;
 });

=cut

no indirect;

use Database::Async::Row;

use Future;
use Syntax::Keyword::Try;
use Ryu::Async;
use Scalar::Util qw(blessed);

use Log::Any qw($log);

use overload
    '""' => sub { my ($self) = @_; sprintf '%s[%s]', ref($self), $self->sql },
    bool => sub { 1 },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    Scalar::Util::weaken($args{db});
    bless \%args, $class;
}

=head2 in

This is a L<Ryu::Sink> used for queries which stream data to the server.

It's buffered internally.

=cut

sub in {
    my ($self) = @_;
    $self->{in} //= do {
        my $sink = $self->db->new_sink;
        die 'already have streaming input but no original ->{in} sink' if $self->{streaming_input};
        $sink->source->completed->on_ready(sub { $log->debugf('Sink for %s completed with %s', $self, shift->state) });
        $self->{streaming_input} = $sink->source->buffer->pause;
        $self->ready_to_stream->on_done(sub {
            $log->debugf('Ready to stream, resuming streaming input');
            $self->streaming_input->resume;
        });
        $sink
    }
}

#sub {
#    my ($self) = @_;
#    my $engine = $self->{engine} or die 'needs a valid ::Engine instance';
#    my $sink = $self->in or die 'had no valid sink for streaming input';
#
#    my $src = $sink->buffer;
#    $src->pause;
#    $engine->stream_from($src);
#
#    $self->ready_to_stream
#        ->on_done(sub {
#            $log->tracef('Ready to stream for %s', $sink);
#            $src->resume;
#        })->on_fail(sub {
#            $src->completed->fail(@_) unless $sink->completed->is_ready;
#        })->on_cancel(sub {
#            $src->completed->cancel unless $sink->completed->is_ready;
#        });
#}

sub streaming_input { shift->{streaming_input} // die '->in has not yet been called' }

sub finish {
    my ($self) = @_;
    if($self->{in}) {
        $self->input_stream->done;
    } else {
        $self->input_stream->cancel;
    }
}

=head2 db

Accessor for the L<Database::Async> instance.

=cut

sub db { shift->{db} }

=head2 sql

The SQL string that this query would be running.

=cut

sub sql { shift->{sql} }

=head2 bind

A list of bind parameters for this query, can be empty.

=cut

sub bind { @{shift->{bind}} }

sub row_description {
    my ($self, $desc) = @_;
    $log->tracef('Have row description %s', $desc);
    my @names = map { $_->{name} } $desc->@*;
    $self->{field_names} = \@names;
    $self->{field_by_name} = {
        # First column wins by default if we have multiple hits
        map { $names[$_] => $_ } reverse 0..$#names
    };
    $self
}

sub row {
    my ($self, $row) = @_;
    $log->tracef('Have row %s', $row);
    $self->row_data->emit($row);
}

sub row_hashrefs {
    my ($self) = @_;
    $self->{row_hashrefs} //= $self->row_data
        ->map(sub {
            my ($row) = @_;
            +{
                map {;
                    $self->{field_names}[$_] => $row->[$_]
                } 0..$#$row
            }
        });
}

sub row_arrayrefs {
    my ($self) = @_;
    $self->{row_arrayrefs} //= $self->row_data;
}

=head2 start

Schedules this query for execution.

=cut

sub start {
    my ($self) = @_;
    $self->{queued} //= $self->db->queue_query($self)->retain;
}

sub run_on {
    my ($self, $engine) = @_;
    $log->tracef('Running query %s on %s', $self, $engine);
    $self->{engine} = $engine;
    $engine->query(
        $self->sql,
        $self->bind
    );
}

=head2 rows

Returns a L<Ryu::Source> which will emit the rows from this query.

Each row is a L<Database::Async::Row> instance.

Will call L</start> if required.

=cut

sub row_data {
    my ($self) = @_;
    $self->{row_data} //= do {
        my $row_data = $self->db->new_source;
        $self->completed->on_ready(sub {
            my $f = $self->{row_data}->completed;
            shift->on_ready($f) unless $f->is_ready;
        });
        $row_data->completed->on_ready(sub {
            my $f = $self->completed;
            shift->on_ready($f) unless $f->is_ready;
        });
        $self->start;
        $row_data;
    };
}

sub completed {
    my ($self) = @_;
    $self->{completed} //= do {
        my $f = $self->db->new_future;
        $self->start;
        $f
    }
}

sub void {
    my ($self) = @_;
    $self->start;
    return $self->completed;
}

sub ready_to_stream {
    my ($self) = @_;
    $self->{ready_to_stream} //= $self->db->new_future;
}

sub input_stream {
    my ($self) = @_;
    $self->{input_stream} //= $self->db->new_future;
}

sub done {
    my ($self) = @_;
    my $f = $self->completed;
    if($f->is_ready) {
        $log->warnf('Calling ->done but we think our status is already %s', $f->state);
        return $f;
    }
    # $self->in->completed->done unless $self->in->completed->is_ready;
    $self->completed->done;
}

sub from {
    my ($self, $src) = @_;
    if(ref($src) eq 'ARRAY') {
        $src = Ryu::Source->from($src);
    }
    die 'Invalid source' unless blessed($src) and $src->isa('Ryu::Source');

    $self->in->from($src);
    $src->prepare_await;
    $self;
}

sub rows {
    my ($self) = @_;
    $self->{rows} //= $self->row_data
        ->map(sub {
            my ($row) = @_;
            Database::Async::Row->new(
                index_by_name => +{ map { $row->[$_]->{description}->name => $_ } 0..$#$row },
                data          => $row
            )
        })
}

=head2 single

Used to retrieve data for a query that's always going to return a single row.

Defaults to all columns, provide a list of indices to select a subset:

 # should yield "a", "b" and "c" as the three results
 print for await $db->query(q{select 'a', 'b', 'c'})->single->as_list;

 # should yield just the ID column from the first row
 print for await $db->query(q{select id, * from some_table})->single('id')->as_list;

Returns a L<Future> which will resolve to the list of items.

=cut

sub single {
    my ($self, @id) = @_;
    $self->{single} //= $self->row_data
        ->first
        ->flat_map(sub {
            [ @id ? @{$_}{@id} : @$_ ]
        })->as_list;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

