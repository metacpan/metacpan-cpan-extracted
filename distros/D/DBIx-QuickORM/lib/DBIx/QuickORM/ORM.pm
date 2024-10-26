package DBIx::QuickORM::ORM;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/confess croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/alias/;

require DBIx::QuickORM::GlobalLookup;
require DBIx::QuickORM::Schema;
require DBIx::QuickORM::Source;
require DBIx::QuickORM::Transaction;
require DBIx::QuickORM::Cache::Naive;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    <db
    +connection
    +transactions
    <cache
    <schema
    +con_schema  <con_sources
    +temp_schema <temp_sources
    <autofill
    <accessor_name_cb
    <locator
    <created
    <broken_row_behavior
    <row_class
};

use Role::Tiny::With qw/with/;

# Aliases must come before 'with'
alias start_txn => 'start_transaction';
alias txn_do => 'transaction_do';
alias transactions => 'txns';

with 'DBIx::QuickORM::Role::SelectLike';
with 'DBIx::QuickORM::Role::HasORM';
with 'DBIx::QuickORM::Role::HasTransactions';

sub orm { $_[0] }

sub temp_table_supported { $_[0]->connection->temp_table_supported }
sub temp_view_supported  { $_[0]->connection->temp_view_supported }

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    my $db = $self->{+DB} or croak "'db' is a required attribute";

    $self->{+AUTOFILL}     //= 1;
    $self->{+TEMP_SOURCES} //= {};
    $self->{+CON_SOURCES}  //= {};
    $self->{+CACHE}        //= DBIx::QuickORM::Cache::Naive->new();

    $self->{+BROKEN_ROW_BEHAVIOR} //= 'die';

    croak "You must either provide the 'schema' attribute or enable 'autofill'"
        unless $self->{+SCHEMA} || $self->{+AUTOFILL};

    $self->{+LOCATOR} = DBIx::QuickORM::GlobalLookup->register($self);

    $self->{+TRANSACTIONS} = [];
}

sub clone {
    my $self = shift;
    my (%params) = @_;

    my $type = blessed($self);

    for my $field (NAME(), DB(), SCHEMA(), AUTOFILL(), ACCESSOR_NAME_CB()) {
        $params{$field} //= $self->{$field};
    }

    return $type->new(%params);
}

sub con_schema {
    my $self = shift;

    return $self->{+CON_SCHEMA} if $self->{+CON_SCHEMA};

    $self->{+CON_SCHEMA} = DBIx::QuickORM::Schema->new(name => $self->{+NAME});

    if (my $schema = $self->{+SCHEMA}) {
        $self->{+CON_SCHEMA} = $self->{+CON_SCHEMA}->merge($schema);
    }

    if (my $af = $self->{+AUTOFILL}) {
        my %params;
        $params{name_cb} = $af if ref($af) eq 'CODE';
        $self->{+CON_SCHEMA} = $self->{+CON_SCHEMA}->merge($self->connection->generate_schema, %params);
    }

    $self->{+CON_SCHEMA}->compile;

    return $self->{+CON_SCHEMA};
}

sub temp_schema {
    my $self = shift;
    return $self->{+TEMP_SCHEMA} //= DBIx::QuickORM::Schema->new();
}

sub reconnect {
    my $self = shift;
    delete $self->{+CONNECTION};

    $self->{+CON_SOURCES}  = {};
    $self->{+TEMP_SOURCES} = {};

    delete $self->{+TEMP_SCHEMA};

    return $self->connection;
}

sub connection {
    my $self = shift;

    my $con = $self->{+CONNECTION};

    return $self->{+CONNECTION} = $self->{+DB}->connect
        unless $con;

    return $self->reconnect
        unless $$ == $con->pid;

    return $con;
}

sub _table {
    my $self = shift;
    my ($name) = @_;

    my ($schema, $table);

    for my $meth (qw/ temp_schema con_schema /) {
        $schema = $self->$meth()              or next;
        $table  = $schema->maybe_table($name) or next;
        return ($schema, $table);
    }

    return;
}

sub table {
    my $self = shift;
    my ($name) = @_;

    my ($schema, $table) = $self->_table($name);

    return $table;
}

sub aggregate        { my ($self, $source, @args) = @_; $self->source($source)->aggregate(@args) }
sub all              { my ($self, $source, @args) = @_; $self->source($source)->all(@args) }
sub any              { my ($self, $source, @args) = @_; $self->source($source)->any(@args) }
sub aside            { my ($self, $source, @args) = @_; $self->source($source)->aside(@args) }
sub async            { my ($self, $source, @args) = @_; $self->source($source)->async(@args) }
sub count            { my ($self, $source, @args) = @_; $self->source($source)->count(@args) }
sub find             { my ($self, $source, @args) = @_; $self->source($source)->find(@args) }
sub find_or_insert   { my ($self, $source, @args) = @_; $self->source($source)->find_or_insert(@args) }
sub first            { my ($self, $source, @args) = @_; $self->source($source)->first(@args) }
sub forked           { my ($self, $source, @args) = @_; $self->source($source)->forked(@args) }
sub insert           { my ($self, $source, @args) = @_; $self->source($source)->insert(@args) }
sub insert_row       { my ($self, $source, @args) = @_; $self->source($source)->insert_row(@args) }
sub last             { my ($self, $source, @args) = @_; $self->source($source)->last(@args) }
sub relations        { my ($self, $source, @args) = @_; $self->source($source)->relations(@args) }
sub select           { my ($self, $source, @args) = @_; $self->source($source)->select(@args) }
sub update           { my ($self, $source, @args) = @_; $self->source($source)->update(@args) }
sub update_or_insert { my ($self, $source, @args) = @_; $self->source($source)->update_or_insert(@args) }

sub shotgun { die "FIXME" }

sub source {
    my $self = shift;
    my ($name) = @_;

    croak "source() requires a table/view name" unless $name;

    return $self->{+TEMP_SOURCES}->{$name} if $self->{+TEMP_SOURCES}->{$name};
    return $self->{+CON_SOURCES}->{$name}  if $self->{+CON_SOURCES}->{$name};

    my ($schema, $table) = $self->_table($name);

    croak "'$name' is not defined in the schema as a table/view, or temporary table/view"
        unless $schema && $table;

    return $self->{+CON_SOURCES}->{$name} = DBIx::QuickORM::Source->new(
        connection => $self->connection,
        schema     => $schema,
        table      => $table,
        orm        => $self,
    );
}

sub load_schema_sql { shift->connection->load_schema_sql(@_) }

sub create_temp_table { shift->_create_temp(table => @_) }
sub create_temp_view  { shift->_create_temp(view  => @_) }

sub _create_temp {
    my $self = shift;
    my ($type, $name, %params) = @_;

    my $supported = "temp_${type}_supported";
    my $create    = "create_temp_${type}";

    my $from   = $params{from}   or croak "Must provide a 'from' source to build the $type";
    my $select = $params{select} or croak "Must provide a 'select' to build the $type";

    my $con    = $self->connection;
    my $schema = $self->temp_schema;

    croak "The current database '" . ref($self->{+DB}) . "' does not support temporary ${type}s"
        unless $con->$supported;

    croak "There is already a temporary table or view named '$name'"
        if $schema->maybe_table($name) || $self->{+TEMP_SOURCES}->{$name};

    $from = $self->source($from) unless blessed($from) && $from->isa('DBIx::QuickORM::Source');

    my ($sql, $bind) = $from->sql_for_select(@$select);

    $con->$create($name, $sql, $bind);

    my $table;
    if ($table = $params{table}) {
        if (ref($table) eq 'CODE') {
            require DBIx::QuickORM;
            $table = DBIx::QuickORM::rogue_table($name => $table);
        }

        $table = $table->merge($con->generate_table_schema($name)) if $params{autofill};
    }
    elsif ($params{autofill}) {
        $table = $con->generate_table_schema($name);
    }
    else {
        croak "Must specify either a 'table' specification, or set the `autofill => 1` parameter";
    }

    # Might get cloned and modified
    $table = $schema->add_table($name => $table);

    return $self->{+TEMP_SOURCES}->{$name} = DBIx::QuickORM::Source->new(
        connection => $con,
        schema     => $schema,
        table      => $table,
    );
}

sub drop_temp_source {
    my $self = shift;
    my ($name) = @_;

    my $source = $self->source($name) or croak "No such source '$name'";
    my $table  = $source->table;
    croak "'$name' is not temporary" unless $table->is_temp;
    $source->drop;

    delete $self->{TEMP_SOURCES}->{$name};

    return;
}

sub drop_temp_table {
    my $self = shift;
    my ($name) = @_;

    my $source = $self->source($name) or croak "No such table '$name'";
    croak "'$name' is a view, not a table" if $source->table->is_view;

    return $self->drop_temp_source($name);
}

sub drop_temp_view {
    my $self = shift;
    my ($name) = @_;

    my $source = $self->source($name) or croak "No such view '$name'";
    croak "'$name' is a view, not a table" if $source->table->is_view;

    return $self->drop_temp_source($name);
}

sub with_temp_view  { shift->_with_temp(view  => @_) }
sub with_temp_table { shift->_with_temp(table => @_) }

sub _with_temp {
    my $self = shift;
    my ($type, $name, $select, $code) = @_;

    my $create = "create_temp_$type";
    my $drop   = "drop_temp_$type";

    my $source = $self->$create($name, @$select);

    my $out;
    my $ok  = eval { $out = $code->($source); 1 };
    my $err = $@;

    $self->$drop($name);

    return $out if $ok;
    die $err;
}

sub generate_and_load_schema {
    my $self = shift;
    my $sql = $self->generate_schema_sql();
    return $self->load_schema_sql($sql);
}

sub generate_schema_sql {
    my $self = shift;
    my $con = $self->connection or die "WTF?";
    $self->{+DB}->generate_schema_sql(schema => $self->{+SCHEMA}, connection => $con, dbh => $con->dbh);
}

sub txn_do {
    my $self = shift;
    my $cb = pop;
    my $name = shift;

    my $want = wantarray;
    my @caller = caller;

    croak "txn_do takes a coderef as its final argument" unless $cb && ref($cb) eq 'CODE';

    my $txn = $self->start_txn(name => $name, caller => \@caller);

    my $out;
    my $ok = eval { $out = $cb->($txn); 1 };
    my $err = $@;

    if ($ok) {
        local $@;
        $ok &&= eval { $txn->commit; 1 };
        $err = $@;

        if ($ok) {
            return (1, $out) if $want;

            if (defined $want) {
                return $out || 1;
            }

            return;
        }
    }

    unless ($ok) {
        local $@;
        eval { $txn->rollback; 1 } or warn $@;
    }

    $txn = undef;

    return (0, $err) if $want;

    if (defined $want) {
        warn $err;
        return 0;
    }

    die $err;
}

sub start_txn {
    my $self = shift;
    my %params = @_;

    $params{caller} //= [caller];

    my $con = $self->{+CONNECTION};
    return -1 if $con->in_external_transaction;

    my $txns = $self->transactions;

    my $sp;
    if (my $depth = @$txns) {
        $sp = "SAVEPOINT" . $depth;
        $con->create_savepoint($sp);
    }
    else {
        $sp = undef;
        $con->start_txn;
    }

    my $parent = @$txns ? $txns->[-1] : undef;
    my $txn    = DBIx::QuickORM::Transaction->new(
        %params,
        connection => $con,
        savepoint  => $sp,
        parent     => $parent,
    );

    $parent->set_child($txn) if $parent;

    push @$txns => $txn;
    weaken($txns->[-1]);

    $self->{+CACHE}->new_transaction($txn);

    return $txn;
}

sub transactions {
    my $txns = $_[0]->{+TRANSACTIONS};

    # Transactions are weak refs in the array, so they may go undef on us.
    pop @$txns while @$txns && !$txns->[-1];

    return $txns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM - Actively maintained, quick to start, powerful ORM tool.

=head1 DESCRIPTION

An actively maintained ORM tool that is qucik and easy to start with, but
powerful and expandable for long term and larger projects. An alternative to
L<DBIx::Class>, but not a drop-in replacement.

=head1 SYNOPSIS

FIXME!

=head1 PRIMARY INTERFACE

See L<DBIx::QuickORM> for the primary interface documentation,

=head1 RECIPES

See L<DBIx::QuickORM::Recipes> for documentation on specific scenarios that may
fit your need.

=head1 FEATURE SUMMARY

=over 4

=item Declarative syntax

See L<DBIx::QuickORM>.

=item Perl schema to SQL conversion/generation

    my $sql = $orm->generate_schema_sql;
    $orm->generate_and_load_schema();

=item SQL schema to perl conversion/generation

    orm { db { ... }; autofill(); } # Populate from the database!

Also

    my $schema = $db->connect->generate_schema();

Also

    my $schema = DBIx::QuickORM::Util::SchemaBuilder->generate_schema($orm->connection);

=item Async query support - single connection

    my $async = $orm->select({...})->async();
    until( $async->ready ) { ... }
    my @rows = $async->all;

=item Multiple concurrent async query support - multiple connections on 1 process

    my $aside1 = $orm->select({...})->aside();
    my $aside2 = $orm->select({...})->aside();
    my $aside3 = $orm->select({...})->aside();

    until( $aside1->ready ) { ... }
    my @rows = $aside1->all;
    ...

=item Multiple concurrent async query support - emulation via forking

    my $forked1 = $orm->select({...})->forked();
    my $forked2 = $orm->select({...})->forked();
    my $forked3 = $orm->select({...})->forked();

    until( $forked1->ready ) { ... }
    my @rows = $forked1->all;
    ...

=item Plugin system - Lots of hooks available

    plugin sub { ... }; # On the fly plugin writing
    plugin Some::Plugin; # Use a plugin class (does not have or need a new method)
    plugin Other::Plugin->new(...); Plugin that need to be blessed

Define custom plugin hooks in your custom tools:

    plugin_hook NAME => \%params; # Any/All plugins can take action here.

=item Ability to customize relationship names when generating perl schema from SQL schema

This is done va plugins, See L<DBIx::QuickORM::Plugin>.

=item Can have multiple ORMs on any number of databases in a single app

Any number of orms with any number of schemas, they can all talk to the same DB
or to different ones.

=item Select object system that closely resembles ResultSets from DBIx::Class

ResultSet was a good idea, regardless of your opinion on L<DBIx::Class>. The
L<DBIx::QuickORM::Select> objects implement most of the same things.

=item Uses SQL::Abstract under the hood, so query syntax should be familiar to DBIx::Class users

See L<SQL::Abstract>.

    my $sel = $orm->select(\%sql_abstract_where, $order_by);
    my $sel = $orm->select(where => \%where, order_by => $order_by, ...);

=item Build in support for transactions and savepoints

The C<< transaction(sub { ... }) >> method can be accessed via the orm, select,
source and row objects.

    $orm->transaction(sub { ... });
    $sel->transaction(sub { ... });
    $src->transaction(sub { ... });
    $row->transaction(sub { ... });

=item Per-connection source/row caches

=item First-class Inflation/Deflation (conflation (yes, its a bad pun)) support

=item Multiple databases supported:

See the L<DBIx::QuickORM::DB> for the database base class all drivers build
upon. You can even add your own if yours is not on this list.

=over 4

=item PostgreSQL

See L<DBIx::QuickORM::DB::PostgreSQL>, which uses L<DBD::Pg> under the hood.

=item MySQL (Generic)

See L<DBIx::QuickORM::DB::MySQL>, which supports both L<DBD::mysql> and
L<DBD::MariaDB> for connections.

=item MySQL (Percona)

See L<DBIx::QuickORM::DB::Percona>, which supports both L<DBD::mysql> and
L<DBD::MariaDB> for connections.

=item MariaDB

See L<DBIx::QuickORM::DB::MariaDB>, which supports both L<DBD::mysql> and
L<DBD::MariaDB> for connections.

=item SQLite

See L<DBIx::QuickORM::DB::SQLite>, which uses L<DBD::SQLite> under the hood.

=back

=back

=head1 MOTIVATION

The most widely accepted ORM for perl, L<DBIx::Class> is for all intents and
purposes, dead. There is only 1 maintainer, and that person has stated that the
project is feature complete. The project will recieve no updates apart from
critical bugs. The distribution has been marked such that it absolutely can
never be transferred to anyone else.

There are 4 ways forward:

=over 4

=item Use DBIx::Class it as it is.

Many people continue to do this.

=item Monkeypatch DBIx::Class

I know a handful of people who are working on a way to do this that is not
terrible and will effectively keep L<DBIx::Class> on life support.

=item Fork DBIx::Class

I was initially going to take this route. But after a couple hours in the
codebase I realized I dislike the internals of DBIx::Class almost as much as I
dislike using it as an app developer.

=item Write an alternative

I decided to take this route. I have never liked DBIx::Class, I find it
difficult to approach, and it is complicated to start a project with it. The
interface is unintuitive, and the internals are very opaque.

My goal is to start with the interface, make it approachable, easy to start,
etc. I also want the interface to be intuitive to use. I also want
expandability. I also want to make sure I adopt the good ideas and capabilities
from DBIx::Class. Only a fol would say DBIx::Class has nothing of value.

=back

=head1 GOALS

=over 4

=item Quick to start

It should be very simple to start a project. The ORM should stay out of your
way until you want to make it do something for you.

=item Intuitive

Names, interfaces, etc should make sense and be obvious.

=item Declarative Syntax

DBIx::Class had an abysmal interface calling C<< __PACKAGE__->blah >> all over
the place. You also had to create a lot of classes to line up with your tables.
With DBIx::QuickORM You can declare your table structure anywhere, and they do
not need associated clases per table. That said it is also trivial to define a
class for any given table and add your own custom methods.

=item Make as few assumptions as possible

DBIx::Class and other orms tend to make some assumptions such as:

=over 4

=item Only 1 database connection at a time

=item Only 1 database server at a time

=item Only 1 instance of the schema at a time

=back

=item Expandability

Should be easy to extend and expand the functionality.

=item Inflation/Deflation should be trivial, and "just work" in fetched objects, inserts, selects, etc.

The way DBIx::Class handled inflation and deflation left a lot of places where
you had to ask "Can I pass an inflated form here? or do I need to deflate it
first?". In DBIx::QuickORM this should never be a question, there will be few
if any places where inflation and deflation is not automatic.

In this project I am calling it "conflation", yes it is a terrible pun, and thr
word "conflate" has no real connection to "inflate" or "deflate" as far as I
know... but I like it as a blanket term to encapsulate both "inflate" and
"deflate". Most inflation and deflation occurs with conflator classes.

=item Easy to generate the perl side orm from the database itself if the schema is already in the database

If you tell the orm how to connect to the database, you can ask it to just
generate the table based data. If it does not generate them exactly how you
want (object or relationship names are not ideal) then you have hooks to use to
tell it how to name them.

This is a core functionality of DBIx::QuickORM, not a secondary project or
side-thought.

=item Easy to generate the sql to initialize the database if you have the perl code already defined

If you write perl code that defines your database structure, table layout,
relations, etc. Then you can ask the orm to give you an SQL dump in whatever
supported SQL variant you want. You can then take this SQL and load it into
your database. You can even tell the DB to load the schema into a database once
you are connected.

This is a core functionality of DBIx::QuickORM, not a secondary project or
side-thought.

=item Built-in support for PostgreSQL, MariaDB, SQLite and MySQL.

These are my big 4 for initial support. Additional DB's can be supported, and
you can write your own database-orm inferface modules if you want something
else supported.

With a properly written DB class the ORM can even handle translating concepts
from one database to another. For example MySQL is the only one of the big 4
that does not have a builtin UUID type. The ORM will let you use BINARY(16),
VARCHAR(36) on MySQL, or even other types to store the UUID, and with the UUID
conflator (inflation/deflation) you can make it completely transparent to the
app. The same schema definition (on perls side) will work just as well on any
of the 4 database servers.

=item Async capabilities

Async is supported in multiple ways:

=over 4

=item Using native Async functionality on the current connection

Send off a query, then do somthing else until it is ready. Even works inside
transactions! The caveat is you cannot use the db connection for anything else
while you wait.

This feature is accessed as C<< $select->async >>. See
L<DBIx::QuickORM::Select>.

=item Using native Async functionality with multiple connections

You can make Async requests where each one operates on a different connection
so they can operate concurrently. The caching is managed for you as well. The
main caveat here is that you cannot use it with transactions and multiple
connections cannot share a transaction.

Exceptions will be thrown if you start one of these during a transaction.

Exceptions will be thrown if you start a transaction while one of these is
running.

This feature is accessed as C<< $select->aside >>. See
L<DBIx::QuickORM::Select>.

=item Using fork + Different connections

The queries each run on their own connection and in their own processes, then
the data will be send to the primary process. This is useful for databases that
do not support async queries natively, such as SQLite.

Exceptions will be thrown if you start one of these during a transaction.

Exceptions will be thrown if you start a transaction while one of these is
running.

This feature is accessed as C<< $select->forked >>. See
L<DBIx::QuickORM::Select>.

=back

=item Transaction Management

DBIx::QuickORM provides easy ways to start and mnage transactions, as well as
using savepoints for an effective "nested transactions" functionality.

Caveat: If combined with external transaction management, things can go bad, or
be confusing.

=item Cache Management

DBIx::QuickORM provides a caching layer that associates cache with a specific
connection. You can clear all the cache for the connection, or all the cache
for a specific table in the connection. You can also disable cache or ignore
cache at any time. There is also sane handling of caching with transactions.

=back

=head1 SCOPE

The primary scope of this project is to write a good ORM for perl. It is very
easy to add scope, and try to focus on things outside this scope. I am not
opposed to such things being written around the ORM fucntionality, afterall the
project has a lot of useful code, and knowledge of the database. But th primary
focus must always be the ORM functionality, and it must not suffer in favor of
functionality beyond that scope.

=head1 MAINTENANCE COMMITMENT

I want to be sure that what happened to L<DBIx::Class> cannot happen to this
project. I will maintain this as long as I am able. When I am not capable I
will let others pick up where I left off.

I am stating here, in the docs, for all to see for all time:

B<If I become unable to maintain this project, I approve of others being given
cpan and github permissions to develop and release this distribution.>

Peferably maint will be handed off to someone who has been a contributor, or to
a group of contributors, If none can be found, or none are willing, I trust the
cpan toolchain group to takeover.

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<http://github.com/exodist/DBIx-QuickORM/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

