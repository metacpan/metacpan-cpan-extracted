package DBD::Cassandra;
use 5.010;
use strict;
use warnings;

use DBD::Cassandra::dr;
use DBD::Cassandra::db;
use DBD::Cassandra::st;

our $VERSION= '0.56';
our $drh= undef;

sub driver {
    return $drh if $drh;

    DBD::Cassandra::st->install_method('x_finish_async');
    DBD::Cassandra::db->install_method('x_wait_for_schema_agreement');

    my ($class, $attr)= @_;
    $drh = DBI::_new_drh($class."::dr", {
            'Name' => 'Cassandra',
            'Version' => $VERSION,
            'Attribution' => 'DBD::Cassandra by Tom van der Woerdt',
        }) or return undef;

    return $drh;
}

sub CLONE {
    undef $drh;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

DBD::Cassandra - Database driver for Cassandra's CQL3

=head1 EXAMPLE

    use DBI;

    my $dbh = DBI->connect("dbi:Cassandra:host=localhost;keyspace=test", $user, $password, { RaiseError => 1 });
    my $rows = $dbh->selectall_arrayref("SELECT id, field_one, field_two FROM some_table");

    for my $row (@$rows) {
        # Do something with your row
    }

    $dbh->do("INSERT INTO some_table (id, field_one, field_two) VALUES (?, ?, ?)",
        { Consistency => "quorum" },
        1, "String value", 38962986
    );

    $dbh->disconnect;

=head1 DESCRIPTION

B<DBD::Cassandra> is a Perl5 Database Interface driver for Cassandra,
using the CQL3 query language.

=head2 Configuration

=over

=item Database handles

    use DBI;

    $dsn = "dbi:Cassandra:database=$database";
    $dsn = "dbi:Cassandra:keyspace=$keyspace;host=$hostname;port=$port";
    $dsn = "dbi:Cassandra:keyspace=$keyspace;consistency=local_quorum";

    my $dbh = DBI->connect($dsn, $username, $password);

=over

=item keyspace

=item database

=item db

Optionally, a keyspace to use by default. If this is not specified,
all queries must include the keyspace name.

=item hostname

=item hosts

Hostname to initially connect to. Defaults to C<localhost>. Can be
comma-separated to specify multiple hosts.

=item port

Port number to connect to. Defaults to C<9042>

=item compression

The compression method we should use for the connection. Currently
Cassandra allows C<lz4> and C<snappy>. Defaults to the algorithm with
the best compression ratio, if the server supports it. Compression can
be disabled by setting C<compression=none>.

Only used for data frames longer than 512 bytes, smaller frames get
sent uncompressed.

=item cql_version

There are several versions of the CQL language and this option lets you
pick one. Defaults to the highest available version. Consult your
Cassandra manual to see which versions your database supports.

=item consistency

See the chapter on consistency levels

=item request_timeout

Maximum amount of time (in seconds) to wait for a Cassandra network operation to finish.

=item read_timeout

=item write_timeout

B<Deprecated>. These two are summed and used as C<request_timeout>.

=item tls

Boolean (1|0); whether to use TLS. Defaults to off.

=back

=item Statement handles

    my $sth= $dbh->prepare('SELECT "id", "field1", "field2" FROM table_name WHERE id=?', { Consistency => 'one' });

=over

=item async

See "asynchronous queries".

=item consistency

See "consistency levels".

=item per_page

Cassandra supports pagination through result sets, to avoid having the entire
result set in memory.

    my $sth = $dbh->prepare('SELECT id FROM tablename', { PerPage => 1000 });
    $sth->execute;
    while (my $row = $sth->fetchrow_arrayref()) {
        print "$row->[0]\n";
    }

It is important to keep in mind that this mode can cause errors while fetching
rows, as extra queries may be executed by the driver internally.

=back

=back

=head1 ASYNCHRONOUS QUERIES

    my $sth= $dbh->prepare("SELECT id FROM some_table WHERE x=?",
        { async => 1 });
    $sth->execute(5);

    some_other_function();

    while (my $row = $sth->fetchrow_arrayref()) {
        print "$row->[0]\n";
    }

B<DBD::Cassandra> supports asynchronous queries in an easy to use form.
When C<async => 1> is passed to C<prepare()>, any subsequent executes
on the handle are not read back immediately. Instead, these are delayed
until the result is actually needed.

For inserts and other writes, a convenience method C<x_finish_async> is
provided, which returns an approximation to what C<execute()> would have
returned in an non-asynchronous context. This method also raises errors,
if needed.

    my $sth= $dbh->prepare("INSERT INTO table (a, b) VALUES (?, ?)",
        { async => 1 });
    $sth->execute(5, 6);

    some_other_function_that_takes_a_while();

    $sth->x_finish_async;

=head2 Performance considerations

When using asynchronous queries, some previously premature optimizations
become relevant. For example, it is very helpful to re-use statement
handles in large volumes of inserts :

    my @dataset_to_insert= ([1, 2, 3, 4], [5, 6, 7, 8]);
    my (@pending, @reusable);

    while (my $row= shift @dataset_to_insert) {
        my $sth= (shift @reusable) || $dbh->prepare(
            "INSERT INTO some_table (a, b, c, d) VALUES (?, ?, ?, ?)"
        );
        $sth->execute(@$row);
        push @pending, $sth;

        if (@pending > 500) { # Tune this number!
            my $pending_sth= shift @pending;
            $pending_sth->x_finish_async;
            push @reusable, $pending_sth;
        }
    }

    $_->x_finish_async for @pending;

=head1 CONSISTENCY LEVELS

    $dbh->do("INSERT INTO some_table (id, field_name) VALUES (?, ?)",
        { Consistency => "quorum" },
        @values
    );

B<DBD::Cassandra> accepts a I<Consistency> attribute for statements.
Supported consistency levels are C<any>, C<one>, C<two>, C<three>,
C<quorum>, C<all>, C<local_quorum>, C<each_quorum>, C<serial>,
C<local_serial> and C<local_one>.

This attribute is ignored on statements that do not support it, such
as C<CREATE>.

A global consistency level can be defined as part of the DSN.

=head1 CAVEATS, BUGS, TODO

=over

=item *

There is currently no support for transactions. C<begin_work> will die
if you try to use it.

=item *

Thread support is untested. Use at your own risk.

=item *

The C<timestamp> format is implemented naively by returning
milliseconds since the UNIX epoch. In Perl you get this number through
C<time() * 1000>. Trying to save times as C<DateTime> objects or
strings will not work, and will likely result in warnings and
unexpected behavior.

=item *

When using asynchronous queries, more functions than just execute() may
throw errors. It is recommended that you enable RaiseError. If this is
not possible, it should also suffice to call C<$sth->x_finish_async> and
check its return value before reading any data from the handle.

=item *

Cassandra/CQL3 is strict about the queries you write. When switching
from other databases, such as MySQL, this may come as a surprise. This
module supports C<quote(..)>, but try to use prepared statements
instead. They will save you a lot of trouble.

=back

=head1 UPGRADING

=head2 From versions 0.25 and lower

As of C<DBD::Cassandra> 0.51, this module uses C<Cassandra::Client> internally.
The unit tests from the previous release all still pass, but there are subtle
changes :

=over

=item read_timeout/write_timeout are deprecated, use request_timeout instead

=item the driver now manages a pool of connections internally

Instead of only connecting to the one specified host, multiple hosts can be
passed as seed-hosts. These are then used to bootstrap the actual internal pool
of connections.

=back

=head2 From versions 0.24 and lower

Prior to version 0.25 there was a bug corrupting float and double values as
they were stored in the database. The endianness on these values was wrong,
which only shows when reading stored data back in an application written using
a different driver.

If you were writing float or double values using a DBD::Cassandra prior to
0.25, please be careful with this upgrade. A way to rewrite your values between
the two formats is :

    my $good_float = unpack('f>', pack('f', $bad_float));
    my $good_double= unpack('d>', pack('d', $bad_double));

If you never used a DBD::Cassandra version prior to 0.25, or do not use floats
or doubles, this bug does not affect you and upgrading to 0.25 is safe.

=head1 LICENSE

This module is released under the same license as Perl itself.

=head1 AUTHORS

Tom van der Woerdt, L<tvdw@cpan.org|mailto:tvdw@cpan.org>
