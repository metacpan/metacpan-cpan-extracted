use Modern::Perl;

package DBIx::Squirrel;
$DBIx::Squirrel::VERSION = '1.2.10';
=pod

=encoding UTF-8

=head1 NAME

DBIx::Squirrel - A C<DBI> extension

=head1 VERSION

version 1.2.10

=head1 SYNOPSIS

    # ------------------
    # Import the package
    # ------------------

    use DBIx::Squirrel;

    # We still have the freedom to accomplish tasks the familiar DBI-way.
    #
    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, \%attr);
    $sth = $dbh->prepare('SELECT * FROM product WHERE Name=?');

    if ( $sth->execute('Acme Rocket') ) {
        $row = $sth->fetchrow_hashref
        print $row->{Name}, "\n";
        $sth->finish
    }

    # ------------------------------
    # Import the package (variation)
    # ------------------------------

    use DBIx::Squirrel database_entities => [qw/db product/];

    # Associate "db" with a database connection, then use "db" to reference
    # it in future.
    #
    db(DBIx::Squirrel->connect($dsn, $user, $pass, \%attr));

    # First, we need to associate "product" with a result set, then use
    # "product" to reference itt in future. The next time arguments are
    # passed, they are treated as bind-values when the statement is
    # executed.
    #
    product(db->results('SELECT * FROM product WHERE Name=?'));

    # Print the named product if there is one. The "single" method will
    # finish the statement automatically.
    #
    print $_->Name, "\n" if product('Acme Rocket')->single;

    # ----------------------------
    # Cloning database connections
    # ----------------------------

    # Cloning connections created by the DBI, DBIx::Squirrel and
    # subclasses is permitted.
    #
    $dbh = DBI->connect($dsn, $user, $pass, \%attr);
    $clone = DBIx::Squirrel->connect($dbh);

    # -----------------------------------------
    # Parameter placeholders and binding values
    # -----------------------------------------

    # Several commonly used placeholder styles are supported and just work!
    #
    # Use the style you prefer. DBIx::Squirrel doesn't care about the DBD
    # engine you are using. By the time the statement is prepared, it will
    # have been normalised to use the legacy style ("?") supported by all
    # engines.
    #
    # Oracle
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=:id');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=:1');

    # Postgres
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=$1');

    # SQLite
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=?1');

    # MySQL, MariaDB and legacy
    $sth = $dbh->prepare('SELECT * FROM product WHERE id=?');

    # Able to bind values to individual parameters for both positional
    # and named placeholder schemes.

    # Use either of these calling styles when binding a value to a
    # named placeholder; both are ok.
    #
    $sth->bind_param(id => '1001099');
    $sth->bind_param(':id', '1001099');

    # Use this calling styles when binding a values to a positional
    # placeholder.
    #
    $sth->bind_param(1, '1001099');

    # Or, bind all values in one call.
    #
    $sth->bind( id => '1001099', ... );
    $sth->bind( ':id' => '1001099', ... );
    $sth->bind( '1001099', ... );

    # References are ok, too.
    #
    $sth->bind( { id => '1001099', ... } );
    $sth->bind( { ':id' => '1001099', ... } );
    $sth->bind( [ '1001099', ... ] );

    # You can also pass the bind values in the same manner to
    # the "execute" and "iterate" methods.
    #
    $res = $sth->execute(...);
    $res = $itr->execute(...);
    $itr = $itr->iterate(...);

    # --------------------------------------------
    # The database connection object's "do" method
    # --------------------------------------------

    # WHEN CALLED IN SCALAR-CONTEXT, the "do" method is used exactly as
    # it would when working with the DBI. The only difference is that
    # the DBIx::Squirrel interface allows for more options in how
    # bind-values are passed.
    #
    $res = $dbh->do('SELECT * FROM product WHERE id=?', '1001099');
    $res = $dbh->do('SELECT * FROM product WHERE id=?', ['1001099']);
    $res = $dbh->do('SELECT * FROM product WHERE id=:id', id => '1001099');
    $res = $dbh->do('SELECT * FROM product WHERE id=:id', ':id' => '1001099');

    # You must supply hash reference (or "undef") as the statement attributes,
    # when bind-values are presented as a hash reference.
    #
    $res = $dbh->do(
        'SELECT * FROM product WHERE id=:id',
        undef | \%attr,
        { ':id' => '1001099'}
    );
    $res = $dbh->do(
        'SELECT * FROM product WHERE id=:id',
        undef | \%attr,
        { id => '1001099' },
    );

    # WHEN CALLED IN LIST-CONTEXT, however, the "do" method works as
    # described previously, but returns both the statement's execution
    # result and its handle (in that order).
    #
    ($res, $sth) = $dbh->do(...);

    # ---------
    # Iterators
    # ---------

    # Both database and statement objects can be used to generate two
    # kinds of iterator.
    #
    # A basic iterator.
    #
    $itr = $dbh->iterate($query, \%attr, ...);
    $itr = $sth->iterate(...);

    # A fancy iterator (or result set).
    #
    $itr = $dbh->results($query, \%attr, ...);
    $itr = $sth->results(...);

    # When we only expect one row, and we require the statement to be
    # finished after that row is fetched, we can call the "single"
    # method (or its alias "one").
    #
    # This method will emit a warning if there are more rows to fetch
    # as a reminder to use "LIMIT 1" in your query.
    #
    $row = $itr->single(OPTIONAL-NEW-BIND-VALUES)
      or die "No matching row!";

    $row = $itr->one(OPTIONAL-NEW-BIND-VALUES)
      or die "No matching row!";

    # As above, but won't whinge if there were unexpectedly more rows
    # available to be fetched.
    #
    $row = $itr->find(OPTIONAL-NEW-BIND-VALUES)
      or die "No matching row!";

    # Populate an array using "next".
    #
    @ary = ();
    push @ary, $_ while $itr->next;

    @ary = $itr->first;
    push @ary, $_ while $itr->next;

    # Get everything at once.
    #
    @ary = $itr->first;
    push @ary, $itr->remaining;

    @ary = $itr->all;

    # Having "all" return a reference is faster!
    #
    $ary_ref = $itr->all;

    # Get the number of records. More memory efficient than "count_all",
    # since "next" is called after each record is read and discarded.
    #
    $num = $itr->count();

    # Get the number of records. Not as memory efficient as "count", since
    # all rows are fetched at once and the size of the resulting array
    # is returned.
    #
    $num = $itr->count_all();

    # Reset an iterator so that it will be executed again.
    #
    $itr = $itr->reset();

    # Reset the iterator. Also set the slice-style.
    #
    $itr = $itr->reset({});
    $itr = $itr->reset([]);

    # Reset the iterator. Also specify how many rows to slurp at a time.
    #
    $itr = $itr->reset(10);

    # Reset the iterator. Set the slice style and how slurpy our row fetches
    # are.
    #
    $itr = $itr->reset($slice, $row_count);
    $itr = $itr->reset($row_count, $slice);

    # --------------------
    # Working with results
    # --------------------

    # Accessing column values using basic iterators.
    #
    $itr = $dbh->iterate('SELECT Id, Name FROM product WHERE Name=?')->reset([]);
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: $row->[0]\n"
    }

    $itr = $dbh->iterate('SELECT Id, Name FROM product WHERE Name=?')->reset({});
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: $row->{Id}\n"
    }

    # Accessing column values using using fancy iterators can be accomplished
    # as shown above. Fancy iterators, however, don't care how your rows are
    # sliced, because they also provide access to column values via on-demand
    # accessors. You can use any case for accessors as they all resolve to
    # the same column.
    #
    $itr = $dbh->results('SELECT Id, Name FROM product WHERE Name=?');
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: ", $row->Id, "\n"
    }

    $itr = $dbh->results('SELECT Id, Name FROM product WHERE Name=?');
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: ", $row->ID, "\n"
    }

    $itr = $dbh->results('SELECT Id, Name FROM product WHERE Name=?');
    if ($row = $itr->iterate('Acme Rocket')->single) {
        print "Id: ", $row->id, "\n"
    }

    # ---------------
    # Transformations
    # ---------------

    # A transformation is a sequence of one or more trailing code references
    # passed to the method that generates the iterator. The initial result
    # enters the first stage of the transformation as $_ (and in $_[0]). The
    # result of that transformation is passed on to the next stage (or to the
    # caller), with an explicit "return" statement or as the result of the
    # sfinal expression.
    #
    # Transformations are a great way to declare, in one place, any common
    # processing logic that should be applied automatically to results as
    # they are fetched.
    #
    $itr = $dbh->iterate(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {$_->[0]},
    )->reset([]);
    if ($id = $itr->iterate('Acme Rocket')->single) {
        print "Id: $id\n"
    }

    $itr = $dbh->iterate(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {$_->{Id}},
    )->reset({});
    if ($id = $itr->iterate('Acme Rocket')->single) {
        print "Id: $id\n"
    }

    $itr = $dbh->results(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {$_->Id},
    );
    if ($id = $itr->iterate('Acme Rocket')->single) {
        print "Id: $id\n"
    }

    # Transformation squences.
    #
    $itr = $dbh->results(
        'SELECT Id, Name FROM product WHERE Name=?' => sub {
            $_->Id;
        } => sub {
            my $result = $_;
            print "Id: $result\n";
            return $result;
        },
    );
    $id = $itr->iterate('Acme Rocket')->single;
=cut

use DBI;
use Exporter;
use Scalar::Util qw/reftype/;
use Sub::Name;
use DBIx::Squirrel::dr   ();
use DBIx::Squirrel::db   ();
use DBIx::Squirrel::st   ();
use DBIx::Squirrel::it   ();
use DBIx::Squirrel::rs   ();
use DBIx::Squirrel::rc   ();
use DBIx::Squirrel::util qw/throw uniq/;


BEGIN {
    @DBIx::Squirrel::ISA                          = 'DBI';
    *DBIx::Squirrel::EXPORT_OK                    = *DBI::EXPORT_OK;
    *DBIx::Squirrel::EXPORT_TAGS                  = *DBI::EXPORT_TAGS;
    *DBIx::Squirrel::err                          = *DBI::err;
    *DBIx::Squirrel::errstr                       = *DBI::errstr;
    *DBIx::Squirrel::rows                         = *DBI::rows;
    *DBIx::Squirrel::lasth                        = *DBI::lasth;
    *DBIx::Squirrel::state                        = *DBI::state;
    *DBIx::Squirrel::connect                      = *DBIx::Squirrel::dr::connect;
    *DBIx::Squirrel::connect_cached               = *DBIx::Squirrel::dr::connect_cached;
    *DBIx::Squirrel::SQL_ABSTRACT                 = *DBIx::Squirrel::db::SQL_ABSTRACT;
    *DBIx::Squirrel::DEFAULT_SLICE                = *DBIx::Squirrel::it::DEFAULT_SLICE;
    *DBIx::Squirrel::DEFAULT_MAXROWS              = *DBIx::Squirrel::it::DEFAULT_MAXROWS;
    *DBIx::Squirrel::BUF_MULT                     = *DBIx::Squirrel::it::BUF_MULT;
    *DBIx::Squirrel::BUF_MAXROWS                  = *DBIx::Squirrel::it::BUF_MAXROWS;
    $DBIx::Squirrel::FINISH_ACTIVE_BEFORE_EXECUTE = !!1;
    $DBIx::Squirrel::NORMALISE_SQL                = !!1;
    *DBIx::Squirrel::NORMALIZE_SQL                = *DBIx::Squirrel::NORMALISE_SQL;
}

use constant E_BAD_ENT_BIND     => 'Cannot associate with an invalid object';
use constant E_EXP_HASH_ARR_REF => 'Expected a reference to a HASH or ARRAY';


sub _partition_imports_into_helpers_and_dbi_imports {
    my $class = shift;
    my(@helpers, @dbi);
    while (@_) {
        my $symbol = shift;
        next unless defined($symbol);
        if ($symbol eq 'database_entities') {
            my $symbols = shift;
            if (UNIVERSAL::isa($symbols, 'ARRAY')) {
                push @helpers, @{$symbols};
            }
        }
        elsif ($symbol eq 'database_entity') {
            $symbol = shift;
            if (defined($symbol) and not ref($symbol)) {
                push @helpers, $symbol;
            }
        }
        else {
            push @dbi, $symbol;
        }
    }
    return (\@helpers, \@dbi);
}


sub import {
    no strict 'refs';    ## no critic
    my $class  = shift;
    my $caller = caller;
    my($helpers, $dbi) = $class->_partition_imports_into_helpers_and_dbi_imports(@_);
    for my $name (@{$helpers}) {
        my $symbol = $class . '::' . $name;
        my $helper = sub {
            unless (defined(${$symbol})) {
                if (@_) {
                    throw E_BAD_ENT_BIND
                      unless UNIVERSAL::isa($_[0], 'DBI::db')
                      or UNIVERSAL::isa($_[0], 'DBI::st')
                      or UNIVERSAL::isa($_[0], 'DBIx::Squirrel::it');
                    ${$symbol} = shift;
                    return ${$symbol};
                }
            }
            return unless defined(${$symbol});
            if (@_) {
                my @params = do {
                    if (@_ == 1 && ref $_[0]) {
                        if (reftype($_[0]) eq 'ARRAY') {
                            @{+shift};
                        }
                        elsif (reftype($_[0]) eq 'HASH') {
                            %{+shift};
                        }
                        else {
                            throw E_EXP_HASH_ARR_REF;
                        }
                    }
                    else {
                        @_;
                    }
                };
                if (UNIVERSAL::isa(${$symbol}, 'DBI::db')) {
                    return ${$symbol}->prepare(@params);
                }
                elsif (UNIVERSAL::isa(${$symbol}, 'DBI::st')) {
                    return ${$symbol}->execute(@params);
                }
                elsif (UNIVERSAL::isa(${$symbol}, 'DBIx::Squirrel::it')) {
                    return ${$symbol}->iterate(@params);
                }
                else {
                    # ok - no worries
                }
            }
            return ${$symbol};
        };
        *{$symbol} = subname($name => $helper);
        *{$caller . '::' . $name} = subname($caller . '::' . $name => \&{$symbol})
          unless defined(&{$caller . '::' . $name});
    }
    if (@{$dbi}) {
        DBI->import(@{$dbi});
        @_ = ('DBIx::Squirrel', @{$dbi});
        goto &Exporter::import;
    }
    return $class;
}

1;
__END__

=pod

=encoding UTF-8

=head1 DESCRIPTION

The C<DBIx::Squirrel> package extends the C<DBI> by providing a few extra
conveniences that are subtle and additive in nature, and, hopefully, quite
useful.

=head2 Importing the package

In the simplest case, just import the package as you would any other:

    use DBIx::Squirrel;

Any symbols and tags that you would typically import from the C<DBI> can
also be requested via C<DBIx::Squirrel>:

    use DBIx::Squirrel DBI-IMPORT-LIST;

If required (and in addition to any C<DBI> imports), C<DBIx::Squirrel> can
create and import Database Entity Helper functions for you:

    use DBIx::Squirrel database_entity=>NAME;
    use DBIx::Squirrel database_entities=>[NAMES];

=head3 Database Entity Helper Functions

A database entity helper is nothing more than a standard function providing
some syntactic sugar in the form of a polymorphic interface for interacting
with database entities such as database connections, statements and
iterators.

While it is not absolutely necessary to use themE<mdash>you could just as
easily use scalar referencesE<mdash>helper functions do possess the advantage
of being shared more easily among package namespaces than, say, lexical
variables.

Helper semantics deal with three common types of interaction:

=over

=item * B<Establishing an association>

Before it can be used, a helper must first be associated with a database
entity. This is accomplished by passing the function single argument: a
reference to the associated object.

Once established, associations are I<sticky> and cannot easily be undone.
You should take care to create them once only, in a sensible place.

Use Perl's standard importing mechanisms (as shown above) to share
associations among different package namespaces.

=item * B<Resolving an association>

Fetching the reference to the associated database entity is accomplished
by calling the helper function without any arguments.

When no association exists in this scenario, a helper returns C<undef>.

=item * B<Addressing an association>

Addressing an association amounts to doing something meaningful with it,
and we accomplish this by calling the helper function with one or more
arguments.

Once associated with a database entity, a helper function will consume
any arguments that are passed to it and send a version of these to the
database entity method that imparts meaning to the interaction.

Meaning in this context is determined by the type of association:

=over

=item *

for a database connection, a statement is prepared using the C<prepare> method;

=item *

for statements and iterators, these are executed with the C<execute> and C<iterate>
methods respectively.

=back

B<Clearly there is a paradox here>, and itcentres around those statements
and iterators that take no parameters and expect no bind-values. In order
to smooth-out this wrinkle, you can opt to enclose arguments inside an
anonymous array or hash. When no bind-values are expected, you can coerce
the helper into performing the execution by passing an empty ARRAYREF or
HASHREF. Alternatively, you could just resolve the association and call
the relevant method manually.

=back

=head4 Examples

=over

=item *

Let us do a full worked example. We will connect to a database, create and
work with two result sets, one of which expects a single bind-value. Some
concepts will be expanded upon and improved later, but it might be helpful
to dip a toe in the water ahead of time:

    use DBIx::Squirrel database_entities => [ qw/db artists artist/ ];

    # Associate helper ("db") with our database connection:

    @connect_args = ( 'dbi:SQLite:dbname=chinook.db', '', '', { sqlite_unicode => 1 } );
    db( DBIx::Squirrel->connect(@connection_args) );

    # Resolve the database connection helper ("db"), using it to
    # associate helpers ("artist" and "artists") with different
    # result sets:

    artist( db->results('SELECT * FROM artists WHERE Name=? LIMIT 1') );
    artists( db->results('SELECT * FROM artists') );

    # Address the helper ("artist"), passing it a bind-value, to get
    # the ArtistId of the artist whose name is "Aerosmith".
    #
    # We could have called "next" to get the only matching record, but by
    # calling "single" (or "first") we can ensure that there are no warnings
    # about dangling active statements emitted when we disconnect from the
    # database.

    print artist('Aerosmith')->single->ArtistId, "\n";

    # Iterate over the "artists" result set, printing the Name-column for
    # each artist. We don't need to trigger execution manually because
    # the "next" method will do that for us, if it is necessary.

    while ( artists->next ) {
        print $_->Name, "\n";
    };

=back

=head2 Connecting to databases

Connecting to a database using C<DBIx::Squirrel> may be done exactly as it
would when using the C<DBI>'s C<connect_cached> and C<connect> methods.

=head3 Cloning database connections

The C<connect> method implemented by the C<DBIx::Squirrel> package offers
an alternative form:

    $new_dbh = DBIx::Squirrel->connect($original_dbh, \%attr);

This form clones another connection object and returns a brand new object
that is blessed using the same class that invoked the C<connect> method.
The method will allow you to clone database connections created by the
C<DBI> and any subclasses (C<DBIx::Squirrel> being one).

=head2 Preparing statements

Preparing a statement using C<DBIx::Squirrel> may be done exactly as
it would be done using the C<DBI>'s C<prepare_cached> and C<prepare>
methods.

=head3 Placeholders

A nice quality-of-life improvement offered by C<DBIx::Squirrel>'s own
implementation of the C<prepare_cached> and C<prepare> methods is their
built-in ability to cope with a number of different placeholder styles:

=over

=item * named (C<:name>);

=item * positional (C<:number>, C<$number>, C<?number>);

=item * legacy (C<?>)

=back

It does not matter what style your C<DBD>-driver supports, C<DBIx::Squirrel>
will happily deal with all of the above styles. Just pick the one that
you prefer to work with, or use the one that is most suitable for the
task at hand.

By the time your statement is passed to the C<DBD>-driver for execution,
both it and its bind-values will have been normalised to use the legacy
style (C<?>) supported by all drivers.

=head4 Examples

=over

=item *

Legacy placeholders (C<?>):

    $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=? LIMIT 1');

    # Any of the following value-binding styles will work:
    $res = $sth->execute('Aerosmith');
    $res = $sth->execute(['Aerosmith']);

=item *

SQLite positional placeholders (C<?number>):

    $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=?1 LIMIT 1');

    # Any of the following value-binding styles will work:
    $res = $sth->execute('Aerosmith');
    $res = $sth->execute(['Aerosmith']);

=item *

PostgreSQL positional placeholders (C<$number>):

    $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=$1 LIMIT 1');

    # Any of the following value-binding styles will work:
    $res = $sth->execute('Aerosmith');
    $res = $sth->execute(['Aerosmith']);

=item *

Oracle positional placeholders (C<:number>):

    $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=:1 LIMIT 1');

    # Any of the following value-binding styles will work:
    $res = $sth->execute('Aerosmith');
    $res = $sth->execute(['Aerosmith']);

=item *

Oracle named placeholders (C<:name>):

    $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=:Name LIMIT 1');

    # Any of the following value-binding styles will work:
    $res = $sth->execute(Name => 'Aerosmith');
    $res = $sth->execute( ':Name' => 'Aerosmith');
    $res = $sth->execute({Name => 'Aerosmith'});
    $res = $sth->execute({':Name' => 'Aerosmith'});

=back

=head2 Iterators

In addition to statement objects, C<DBIx::Squirrel> provides two kinds
of iterator:

=over

=item * Basic

=item * Fancy, I<or Result Sets>

=back

=head3 Basic Iterators

Basic iterators present row data as ARRAYREFs or HASHREFs depending
on the slice-style currently in use. Column values are accessed either
by column-index when using the ARRAYREF-slicing, or by column-name
when using the HASHREF-slicing.

The default, row data is sliced as an ARRAYREF. The iterator "reset"
method may be used to alter this behaviour.

=head4 How to create a basic iterator

    $itr = $dbh->iterate(
        $query,
        [undef|\%attr,]
        [@bindvalues,]
        [@transforms]
    );

    $itr = $sth->iterate(
        [@bindvalues,]
        [@transforms]
    );

The C<iterate> methods may be replaced by either of the C<it> or C<iterator>
aliases, if preferred.

=head3 Fancy Iterators

Fancy iterators behave just like their basic alternatives, but the
row data they present is blessed. Column values may continue to be
accessed as they would be with basic iterators, but accessor methods
may also be used to get column values. Such accessor methods are
created the first time they are used.

=head4 How to create a fancy iterator

    $itr = $dbh->results(
        $query,
        [undef|\%attr,]
        [@bindvalues,]
        [@transforms]
    );

    $itr = $sth->results(
        [@bindvalues,]
        [@transforms]
    );

The C<results> methods may be replaced by either of the C<rs> or C<resultset>
aliases, if preferred.

=head2 Transforming results

All C<DBIx::Squirrel> iterators support an optional processing step called
I<transformation>.

Transformation can be summarised as the automatic, just-in-time processing,
re-shaping or filtering of results, as they are fetched from the database
and before they are handed-off to the caller.

A transformation is comprised of one or more processing stages. Each stage
receives its version of the result, changes it or does something else it,
and finally hands it off to the next stage, or to the caller if there are
no more stages.

Recall that there are two kinds of iterator, and two methods to construct
each:

    Basic Iterators              |  Fancy Iterators
    -----------------------------|------------------------------
    $itr = $dbh->iterate(        |  $itr = $dbh->results(
        $query,                  |      $query,
        [undef|\%attr,]          |      [undef|\%attr,]
        [@bindvalues,]           |      [@bindvalues,]
        [@transforms]            |      [@transforms]
    );                           |  );
                                 |
    $itr = $sth->iterate(        |  $itr = $sth->results(
        [@bindvalues,]           |      [@bindvalues,]
        [@transforms]            |      [@transforms]
    );                           |  );

The final element of each constructor's argument-list is the transformation
pipeline (C<[@transforms]>). Each stage of this pipeline is an individual
processing step, represented by a CODEREF (or a call that returns a CODEREF).

Each stage of a transformation receives the latest version of the result via
the argument-list (C<$_[0]> to be precise). For the sake of convenience (and
for convention), this result is also available as C<$_>. If you prefer to
rely on something like C<$_>, but would like something much less ephemeral,
just C<use DBIx::Squirrel::util 'result'> and use the C<result> function
inside your transformation stage.

Handing off to the next stage, or the caller, is with an explicit C<return>
statement, or the result of evaluating the unit's final expression. Returning
nothingE<mdash>either C<()>, or a bare C<return>E<mdash>from a processing
step will filter the result out entirely, and no further processing steps
will apply to it.

=head3 Examples

=over

=item 1.

See script C<examples/transformations/01.pl>:

    use DBIx::Squirrel database_entities => [qw/db get_artist_id_by_name/];

    db do {
        DBIx::Squirrel->connect(
            "dbi:SQLite:dbname=./t/data/chinook.db",
            "",
            "",
            {   PrintError     => !!0,
                RaiseError     => !!1,
                sqlite_unicode => !!1,
            },
        );
    };

    get_artist_id_by_name do {
        db->results(
            "SELECT ArtistId, Name FROM artists WHERE Name=? LIMIT 1" => sub {
                my($artist) = @_;
                print "----\n";
                print "Name: ", $artist->Name, "\n";
                return $artist;
            } => sub {$_->ArtistId}
        );
    };

    foreach my $name ("AC/DC", "Aerosmith", "Darling West", "Rush") {
        if (get_artist_id_by_name($name)->single) {
            print "ArtistId: $_\n";
        }
    }

    db->disconnect();

The script is comprised of four parts:

=over

=item *

B<Connect to the database>

Here, I am not just connecting to the database. I am associating the resulting
database connection handle with the C<db> helper function, meaning I can refer
to it as C<db> in future.

=item *

B<Create the C<get_artist_id_by_name> helper function>

Here, I am constructing a fancy iterator and also associating it with the
C<get_artist_id_by_name> helper function. This means I can just call the
C<get_artist_id_by_name> function to execute the iterator in future.

Also here, I describe the the kind of processing I want applied to every
single result produced by this iterator, expressed as a transformation
pipeline that is comprised of two separate stages:

=over

=item *

I want the names of matched artists printed nicely on the console;

=item *

I am only intersted in getting back the artist's id.

=back

=item *

B<Query the database and process the results>

Here, I'm executing the query once for each one of four artists to get and
print their artist ids.

=item *

B<Disconnect from the database>

Just as we would with the C<DBI>.

=back

Find the script and run it:

    $ perl -Ilib examples/transformations/01.pl
    ----
    Name: AC/DC
    ArtistId: 1
    ----
    Name: Aerosmith
    ArtistId: 3
    ----
    Name: Rush
    ArtistId: 128

Notice that we got nothing back for one of our artists? That's because
the artist in question is not in our database and we cannot apply a
transformation to nothing, so nothing is returned.

=back

=head1 COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2014 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

=head1 SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut
