package Catmandu::Store::DBI;

use Catmandu::Sane;
use Catmandu::Util qw(require_package);
use DBI;
use Catmandu::Store::DBI::Bag;
use Moo;
use namespace::clean;

our $VERSION = "0.0702";

with 'Catmandu::Store';
with 'Catmandu::Transactional';

has data_source => (
    is       => 'ro',
    required => 1,
    trigger  => sub {
        my $ds = $_[0]->{data_source};
        $ds = $ds =~ /^DBI:/i ? $ds : "DBI:$ds";
        $_[0]->{data_source} = $ds;
    },
);
has username => (is => 'ro', default => sub {''});
has password => (is => 'ro', default => sub {''});
has timeout => (is => 'ro', predicate => 1);
has reconnect_after_timeout => (is => 'ro');
has handler                 => (is => 'lazy');
has _in_transaction         => (is => 'rw', writer => '_set_in_transaction',);
has _connect_time           => (is => 'rw', writer => '_set_connect_time');
has _dbh => (is => 'lazy', builder => '_build_dbh', writer => '_set_dbh',);

sub handler_namespace {
    'Catmandu::Store::DBI::Handler';
}

sub _build_handler {
    my ($self) = @_;
    my $driver = $self->dbh->{Driver}{Name} // '';
    my $ns = $self->handler_namespace;
    my $pkg;
    if ($driver =~ /pg/i) {
        $pkg = 'Pg';
    }
    elsif ($driver =~ /sqlite/i) {
        $pkg = 'SQLite';
    }
    elsif ($driver =~ /mysql/i) {
        $pkg = 'MySQL';
    }
    else {
        Catmandu::NotImplemented->throw(
            'Only Pg, SQLite and MySQL are supported.');
    }
    require_package($pkg, $ns)->new;
}

sub _build_dbh {
    my ($self) = @_;
    my $opts = {
        AutoCommit                       => 1,
        RaiseError                       => 1,
        mysql_auto_reconnect             => 1,
        mysql_enable_utf8                => 1,
        pg_utf8_strings                  => 1,
        sqlite_use_immediate_transaction => 1,
        sqlite_unicode                   => 1,
    };
    my $dbh
        = DBI->connect($self->data_source, $self->username, $self->password,
        $opts,);
    $self->_set_connect_time(time);
    $dbh;
}

sub dbh {
    my ($self)       = @_;
    my $dbh          = $self->_dbh;
    my $connect_time = $self->_connect_time;
    my $driver = $dbh->{Driver}{Name} // '';

    # MySQL has builtin option mysql_auto_reconnect
    if (   $driver !~ /mysql/i
        && $self->has_timeout
        && time - $connect_time > $self->timeout)
    {
        if ($self->reconnect_after_timeout || !$dbh->ping) {

            # ping failed, so try to reconnect
            $dbh->disconnect;
            $dbh = $self->_build_dbh;
            $self->_set_dbh($dbh);
        }
        else {
            $self->_set_connect_time(time);
        }
    }

    $dbh;
}

sub transaction {
    my ($self, $sub) = @_;

    if ($self->_in_transaction) {
        return $sub->();
    }

    my $dbh = $self->dbh;
    my @res;

    eval {
        $self->_set_in_transaction(1);
        $dbh->begin_work;
        @res = $sub->();
        $dbh->commit;
        $self->_set_in_transaction(0);
        1;
    } or do {
        my $err = $@;
        eval {$dbh->rollback};
        $self->_set_in_transaction(0);
        die $err;
    };

    @res;
}

sub DEMOLISH {
    my ($self) = @_;
    $self->{_dbh}->disconnect if $self->{_dbh};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Catmandu::Store::DBI - A Catmandu::Store plugin for DBI based interfaces

=head1 VERSION

Version 0.0424

=head1 SYNOPSIS

    # From the command line
    $ catmandu import JSON to DBI --data_source SQLite:mydb.sqlite < data.json

    # Or via a configuration file
    $ cat catmandu.yml
    ---
    store:
       mydb:
         package: DBI
         options:
            data_source: "dbi:mysql:database=mydb"
            username: xyz
            password: xyz
    ...
    $ catmandu import JSON to mydb < data.json
    $ catmandu export mydb to YAML > data.yml
    $ catmandu export mydb --id 012E929E-FF44-11E6-B956-AE2804ED5190 to JSON > record.json
    $ catmandu count mydb
    $ catmandy delete mydb

    # From perl
    use Catmandu::Store::DBI;

    my $store = Catmandu::Store::DBI->new(
        data_source => 'DBI:mysql:database=mydb', # prefix "DBI:" optional
        username => 'xyz', # optional
        password => 'xyz', # optional
    );

    my $obj1 = $store->bag->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

    my $obj3 = $store->bag->get('test123');

    $store->bag->delete('test123');

    $store->bag->delete_all;

    # All bags are iterators
    $store->bag->each(sub { ... });
    $store->bag->take(10)->each(sub { ... });

=head1 DESCRIPTION

A Catmandu::Store::DBI is a Perl package that can store data into
DBI backed databases. The database as a whole is  a 'store'
L<Catmandu::Store>. Databases tables are 'bags' (L<Catmandu::Bag>).

Databases need to be preconfigured for accepting Catmandu data. When
no specialized Catmandu tables exist in a database then Catmandu will
create them automatically. See  "DATABASE CONFIGURATION" below.

DO NOT USE Catmandu::Store::DBI on an existing database! Tables and
data can be deleted and changed.

=head1 CONFIGURATION

=over

=item data_source

Required. The connection parameters to the database. See L<DBI> for more information.

Examples:

      dbi:mysql:foobar   <= a local mysql database 'foobar'
      dbi:Pg:dbname=foobar;host=myserver.org;port=5432 <= a remote PostGres database
      dbi:SQLite:mydb.sqlite <= a local SQLLite file based database mydb.sqlite
      dbi:Oracle:host=myserver.org;sid=data01 <= a remote Oracle database

Drivers for each database need to be available on your computer. Install then with:

    cpanm DBD::mysql
    cpanm DBD::Pg
    cpanm DBD::SQLite

=item user

Optional. A user name to connect to the database

=item password

Optional. A password for connecting to the database

=item timeout

Optional. Timeout for a inactive database handle. When timeout is reached, Catmandu
checks if the connection is still alive (by use of ping) or it recreates the connection.
See TIMEOUTS below for more information.

=item reconnect_after_timeout

Optional. When a timeout is reached, Catmandu reconnects to the database. By
default set to '0'

=back

=head1 DATABASE CONFIGURATION

When no tables exists for storing data in the database, then Catmandu
will create them. By default tables are created for each L<Catmandu::Bag>
which contain an '_id' and 'data' column.

This behavior can be changed with mapping option:

    my $store = Catmandu::Store::DBI->new(
        data_source => 'DBI:mysql:database=test',
        bags => {
            # books table
            books => {
                mapping => {
                    # these keys will be directly mapped to columns
                    # all other keys will be serialized in the data column
                    title => {type => 'string', required => 1, column => 'book_title'},
                    isbn => {type => 'string', unique => 1},
                    authors => {type => 'string', array => 1}
                }
            }
        }
    );

For keys that have a corresponding table column configured, the method 'select' of class L<Catmandu::Store::DBI::Bag> provides
a more efficiënt way to query records.

See L<Catmandu::Store::DBI::Bag> for more information.

=head2 Column types

=over

=item string

=item integer

=item binary

=back

=head2 Column options

=over

=item column

Name of the table column if it differs from the key in your data.

=item array

Boolean option, default is C<0>. Note that this options is only supported for PostgreSQL.

=item unique

Boolean option, default is C<0>.

=item index

Boolean option, default is C<0>. Ignored if C<unique> is true.

=item required

Boolean option, default is C<0>.

=back

=head1 TIMEOUT

It is a good practice to set the timeout high enough. When using transactions, one should avoid this situation:

    $bag->store->transaction(sub{
        $bag->add({ _id => "1" });
        sleep $timeout;
        $bag->add({ _id => "2" });
    });

The following warning appears:

    commit ineffective with AutoCommit enabled at lib//Catmandu/Store/DBI.pm line 73.
    DBD::SQLite::db commit failed: attempt to commit on inactive database handle

This has the following reasons:

    1.  first record added
    2.  timeout is reached, the connection is recreated
    3.  the option AutoCommit is set. So the database handle commits the current transaction. The first record is committed.
    4.  this new connection handle is used now. We're still in the method "transaction", but there is no longer a real transaction at database level.
    5.  second record is added (committed)
    6.  commit is issued. But this unnecessary, so the database handle throws a warning.

=head1 SEE ALSO

L<Catmandu::Bag>, L<DBI>

=cut
