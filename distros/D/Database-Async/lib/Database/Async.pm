package Database::Async;
# ABSTRACT: database interface for use with IO::Async
use strict;
use warnings;

our $VERSION = '0.012';

use parent qw(Database::Async::DB IO::Async::Notifier);

=head1 NAME

Database::Async - provides a database abstraction layer for L<IO::Async>

=head1 SYNOPSIS

 # Just looking up one thing?
 my ($id) = $db->query(
  q{select id from some_table where name = ?},
  bind => ['some name']
 )->single
  # This is an example, so we want the result immediately - in
  # real async code, you'd rarely call Future->get, but would
  # typically use `->then` or `->on_done` instead
  ->get;
 # or, with Future::AsyncAwait, try:
 my ($id) = await $db->query(
  q{select id from some_table where name = ?},
  bind => ['some name']
 )->single;

 # Simple query
 $db->query(q{select id, some_data from some_table})
    ->rows_hashref
    ->each(sub {
        printf "ID %d, data %s\n", $_->{id}, $_->{some_data};
    })
    # If you want to complete the full query, don't forget to call
    # ->get or ->retain here!
    ->retain;

 # Transactions
 $db->transaction(sub {
  my ($tx) = @_;
 })->commit
  # This returns a Future, so if you want to wait for it to complete,
  # call `->get` (throws an exception if something goes wrong)
  # or `->await` (just waits for it to succeed or fail, but ignores
  # the result).
 ->get;

=head1 DESCRIPTION

Database support for L<IO::Async>. This is the base API, see L<Database::Async::Engine>
and subclasses for specific database functionality.

B<This is an early preview release>.

L<DBI> provides a basic API for interacting with a database, but this is
very low level and uses a synchronous design. See L<DBIx::Async> if you're
familiar with L<DBI> and want an interface that follows it more closely.

Typically a database only allows a single query to run at a time.
Other queries will be queued.

Set up a pool of connections to provide better parallelism:

    my $dbh = Database::Async->new(
        uri  => 'postgres://write@maindb/dbname?sslmode=require',
        pool => {
            max => 4,
        },
    );

Queries and transactions will then automatically be distributed
among these connections. However, note that:

=over 4

=item * all queries within a transaction will be made on the same connection

=item * ordering guarantees are weaker: queries will be started in
order on the next available connection

=back

With a single connection, you could expect:

    Future->needs_all(
     $dbh->do(q{insert into x ...}),
     $dbh->do(q{select from x ...})
    );

to insert the rows first, then return them in the C<select> call. B<With a pool of connections, that's not guaranteed>.

=head2 Pool configuration

The following parameters are currently accepted for defining the pool:

=over 4

=item * C<min> - minimum number of total connections to maintain, defaults to 0

=item * C<max> - maximum permitted active connections, default is 1

=item * C<ordering> - how to iterate through the available URIs, options include
C<random> and C<serial> (default, round-robin behaviour).

=item * C<backoff> - algorithm for managing connection timeouts or failures. The default
is an exponential backoff with 10ms initial delay, 30s maximum, resetting on successful
connection.

=back

See L<Database::Async::Pool> for more details.

=head2 DBI

The interface is not the same as L<DBI>, but here are some approximate equivalents for
common patterns:

=head3 selectall_hashref

In L<DBI>:

 print $_->{id} . "\n" for
  $dbh->selectall_hashref(
   q{select * from something where id = ?},
   undef,
   $id
  )->@*;

In L<Database::Async>:

 print $_->{id} . "\n" for
  $db->query(
   q{select * from something where id = ?},
   bind => [
    $id
   ])->rows_hashref
     ->as_arrayref
     ->@*

In L<DBI>:

 my $sth = $dbh->prepare(q{select * from something where id = ?});
 for my $id (1, 2, 3) {
  $sth->bind(0, $id, 'bigint');
  $sth->execute;
  while(my $row = $sth->fetchrow_hashref) {
   print $row->{name} . "\n";
  }
 }

In L<Database::Async>:

 my $sth = $db->prepare(q{select * from something where id = ?});
 (Future::Utils::fmap_void  {
  my ($id) = @_;
  $sth->bind(0, $id, 'bigint')
   ->then(sub { $sth->execute })
   ->then(sub {
    $sth->rows_hashref
     ->each(sub {
      print $_->{name} . "\n";
     })->completed
   })
 } foreach => [1, 2, 3 ])->get;

=cut

use mro;
no indirect;

use Future::AsyncAwait;
use Syntax::Keyword::Try;

use URI;
use URI::db;
use Module::Load ();
use Scalar::Util qw(blessed);

use Database::Async::Engine;
use Database::Async::Pool;
use Database::Async::Query;
use Database::Async::StatementHandle;
use Database::Async::Transaction;

use Log::Any qw($log);

=head1 METHODS

=cut

=head2 transaction

Resolves to a L<Future> which will yield a L<Database::Async::Transaction>
instance once ready.

=cut

async sub transaction {
    my ($self, @args) = @_;
    Scalar::Util::weaken(
        $self->{transactions}[@{$self->{transactions}}] =
            my $txn = Database::Async::Transaction->new(
                database => $self,
                @args
            )
    );
    await $txn->begin;
    return $txn;
}

=head2 txn

Executes code within a transaction. This is meant as a shorter form of
the common idiom

 $db->transaction
    ->then(sub {
     my ($txn) = @_;
     Future->call($code)
      ->then(sub {
       $txn->commit
      })->on_fail(sub {
       $txn->rollback
      });
    })

The code must return a L<Future>, and the transaction will only be committed
if that L<Future> resolves cleanly.

Returns a L<Future> which resolves once the transaction is committed.

=cut

async sub txn {
    my ($self, $code, @args) = @_;
    my $txn = await $self->transaction;
    try {
        my @data = await Future->call(
            $code => ($txn, @args)
        );
        await $txn->commit;
        return @data;
    } catch {
        my $exception = $@;
        try {
            await $txn->rollback;
        } catch {
            $log->warnf("exception %s in rollback", $@);
        }
        die $exception;
    }
}

=head1 METHODS - Internal

You're welcome to call these, but they're mostly intended
for internal usage, and the API B<may> change in future versions.

=cut

=head2 uri

Returns the configured L<URI> for populating database instances.

=cut

sub uri { shift->{uri} }

=head2 pool

Returns the L<Database::Async::Pool> instance.

=cut

sub pool {
    my ($self) = @_;
    $self->{pool} //= Database::Async::Pool->new(
        $self->pool_args
    )
}

=head2 pool_args

Returns a list of standard pool constructor arguments.

=cut

sub pool_args {
    my ($self) = @_;
    return (
        request_engine => $self->curry::weak::request_engine,
        uri            => $self->uri,
    );
}

=head2 configure

Applies configuration, see L<IO::Async::Notifier> for details.

Supports the following named parameters:

=over 4

=item * C<uri> - the endpoint to use when connecting a new engine instance

=item * C<engine> - the parameters to pass when instantiating a new L<Database::Async::Engine>

=item * C<pool> - parameters for setting up the pool, or a L<Database::Async::Pool> instance

=back

=cut

sub configure {
    my ($self, %args) = @_;
    if(my $uri = delete $args{uri}) {
        # This could be any type of object. We make
        # the assumption here that it safely serialises
        # to a standard URI. Some of the database
        # engines provide such a standard (e.g. PostgreSQL).
        # Others may not...
        $self->{uri} = URI->new("$uri");
    }
    if(exists $args{engine}) {
        $self->{engine_parameters} = delete $args{engine};
    }
    if(my $pool = delete $args{pool}) {
        if(blessed $pool) {
            $self->{pool} = $pool;
        } else {
            $self->{pool} = Database::Async::Pool->new(
                $self->pool_args,
                %$pool,
            );
        }
    }
    $self->next::method(%args);
}

=head2 ryu

A L<Ryu::Async> instance, used for requesting sources, sinks and timers.

=cut

sub ryu {
    my ($self) = @_;
    $self->{ryu} //= do {
        $self->add_child(
            my $ryu = Ryu::Async->new
        );
        $ryu
    }
}

=head2 new_source

Instantiates a new L<Ryu::Source>.

=cut

sub new_source { shift->ryu->source }

=head2 new_sink

Instantiates a new L<Ryu::Sink>.

=cut

sub new_sink { shift->ryu->sink }

=head2 new_future

Instantiates a new L<Future>.

=cut

sub new_future { shift->loop->new_future }

=head1 METHODS - Internal, engine-related

=cut

=head2 request_engine

Attempts to instantiate and connect to a new L<Database::Async::Engine>
subclass. Returns a L<Future> which should resolve to a new
L<Database::Async::Engine> instance when ready to use.

=cut

sub request_engine {
    my ($self) = @_;
    $log->tracef('Requesting new engine');
    my $engine = $self->engine_instance;
    $engine->connect->retain
}

=head2 engine_instance

Loads the appropriate engine class and attaches to the loop.

=cut

sub engine_instance {
    my ($self) = @_;
    my $uri = $self->uri or die 'need a URI for database connection';
    die 'unknown database type ' . $uri->scheme
        unless my $engine_class = $Database::Async::Engine::ENGINE_MAP{$uri->scheme};
    Module::Load::load($engine_class) unless $engine_class->can('new');
    $log->tracef('Instantiating new %s', $engine_class);
    $self->add_child(
        my $engine = $engine_class->new(
            %{$self->{engine_parameters} || {}},
            db => $self,
            uri => $uri
        )
    );
    $engine;
}

=head2 engine_ready

Called by L<Database::Async::Engine> instances when the engine is
ready for queries.

=cut

sub engine_ready {
    my ($self, $engine) = @_;
    $self->pool->queue_ready_engine($engine);
}

sub db { shift }

=head2 queue_query

Assign the given query to the next available engine instance.

=cut

async sub queue_query {
    my ($self, $query) = @_;
    $log->tracef('Queuing query %s', $query);
    my $engine = await $self->pool->next_engine;
    $log->tracef('Query %s about to run on %s', $query, $engine);
    return await $engine->handle_query($query);
}

sub diagnostics {
    my ($self) = @_;
}

1;

__END__

=head1 SEE ALSO

There's a range of options for interacting with databases - at a low level:

=over 4

=item * L<DBIx::Async> - runs L<DBI> in subprocesses, very inefficient but tries to
make all the methods behave a bit like DBI but deferring results via L<Future>s.

=item * L<DBI> - synchronous database access

=item * L<Mojo::Pg> - attaches a L<DBD::Pg> handle to an event loop

=item * L<Mojo::mysql> - apparently has the ability to make MySQL "fun", an intriguing
prospect indeed

=back

and at higher levels, L<DBIx::Class> or one of the many other ORMs might be
worth a look. Nearly all of those will use L<DBI> in some form or other.
Several years ago I put together a list, the options have doubtless multiplied
since then:

=head2 Asynchronous ORMs

The list here is sadly lacking:

=over 4

=item * L<Async::ORM|https://github.com/vti/async-orm> - asynchronous ORM, see also article in L<http://showmetheco.de/articles/2010/1/mojolicious-async-orm-and-dbslayer.html>

=back

=head2 Synchronous ORMs

If you're happy for the database to tie up your process for an indefinite amount of time, you're in
luck - there's a nice long list of modules to choose from here:

=over 4

=item * L<DBIx::Class> - one of the more popular choices

=item * L<Rose::DB::Object> - written for speed, appears to cover most of the usual requirements, personally
I found the API less intuitive than other options but it appears to be widely deployed

=item * L<Fey::ORM> - "newer" than the other options, also appears to be reasonably flexible

=item * L<DBIx::DataModel> - UML-based Object-Relational Mapping (ORM) framework

=item * L<Alzabo> - another ORM which includes features such as GUI schema editing and SQL diff

=item * L<Class::DBI> - generally considered to be superceded by L<DBIx::Class>, which provides a compatibility
layer for existing applications

=item * L<Class::DBI::Lite> - like L<Class::DBI> but lighter, presumably

=item * L<ORMesque> - lightweight class-based ORM using L<SQL::Abstract>

=item * L<Oryx> - Object persistence framework, meta-model based with support for both DBM and regular RDBMS
backends, uses tied hashes and arrays

=item * L<Tangram> - An object persistence layer

=item * L<KiokuDB> - described as an "Object Graph storage engine" rather than an ORM

=item * L<DBIx::DataModel> - ORM using UML definitions

=item * L<Jifty::DBI> - another ORM

=item * L<ORLite> - minimal SQLite-based ORM

=item * L<Ormlette> - object persistence, "heavily influenced by Adam Kennedy's L<ORLite>". "light and fluffy", apparently!

=item * L<ObjectDB> - another lightweight ORM, currently has only L<DBI> as a dependency

=item * L<ORM> - looks like it has support for MySQL, PostgreSQL and SQLite

=item * L<fytwORM> - described as a "bare minimum ORM used for prototyping / proof of concepts"

=item * L<DBR> - Database Repository ORM

=item * L<SweetPea::Application::Orm> - specific to the L<SweetPea> web framework

=item * L<Jorge> - ORM Made simple

=item * L<Persistence::ORM> - looks like a combination between persistent Perl objects and standard ORM

=item * L<Teng> - lightweight minimal ORM

=item * L<Class::orMapper> - DBI-based "easy O/R Mapper"

=item * L<UR|https://github.com/genome/UR> - class framework and object/relational mapper (ORM) for Perl

=item * L<DBIx::NinjaORM> - "Flexible Perl ORM for easy transitions from inline SQL to objects"

=item * L<DBIx::Oro> - Simple Relational Database Accessor

=item * L<LittleORM> - Moose-based ORM

=item * L<Storm> - another Moose-based ORM

=item * L<DBIx::Mint> - "A mostly class-based ORM for Perl"

=back

=head2 Database interaction

=over 4

=item * L<DBI::Easy> - seems to be a wrapper around L<DBI>

=item * L<AnyData> - interface between L<DBI> and arbitrary data sources such as XML or HTML

=item * L<DBIx::ThinSQL> - helpers for SQL statements

=item * L<DB::Evented> - event-based wrapper for L<DBI>-like behaviour, uses L<AnyEvent::DBI>

=back

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

