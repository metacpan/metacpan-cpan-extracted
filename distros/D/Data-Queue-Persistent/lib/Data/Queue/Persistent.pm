package Data::Queue::Persistent;

use 5.008004;
use strict;
use warnings;
use Carp qw / croak /;
use DBI;

our $VERSION = '0.13';

our $schema = q{
    CREATE TABLE %s (
                     qkey VARCHAR(255) NOT NULL,
                     idx INTEGER UNSIGNED NOT NULL,
                     value BLOB,
                     PRIMARY KEY (qkey, idx)
                     )
    };

sub new {
    my ($class, %opts) = @_;

    my $dsn = delete $opts{dsn};
    my $dbh = delete $opts{dbh};

    croak "No DSN or database handle passed to Data::Queue::Persistent->new"
        unless $dsn || $dbh;

    my $username = delete $opts{username};
    my $pass = delete $opts{pass};

    my $cache = delete $opts{cache} || 0;

    my $key = delete $opts{id} or croak "No queue id defined";

    my $table = delete $opts{table} || 'persistent_queue';

    my $noload = delete $opts{noload};
    my $max_size = delete $opts{max_size};

    # connect to db
    if ($dsn) {
        $dbh = DBI->connect($dsn, $username, $pass)
            or croak "Could not connect to database";
    }

    my $self = {
        cache      => $cache,
        dbh        => $dbh,
        q          => [],
        key        => $key,
        table_name => $table,
        max_size   => $max_size,
    };

    bless $self, $class;
    $self->init;
    $self->load if $self->caching && ! $noload;

    return $self;
}

sub table_name {
    my $self = shift;
    return $self->dbh->quote_identifier($self->{table_name});
}

sub dbh { $_[0]->{dbh} }
sub key { $_[0]->{key} }
sub q { $_[0]->{q} }
sub caching { $_[0]->{cache} }
sub max_size { $_[0]->{max_size} }

# returns how many items are in the queue
sub length {
    my $self = CORE::shift();

    return (scalar @{$self->{q}}) if $self->caching;

    my $table = $self->table_name;
    my ($length) = $self->dbh->selectrow_array("SELECT COUNT(idx) FROM $table WHERE qkey=?",
                                               undef, $self->key);
    die $self->dbh->errstr if $self->dbh->err;

    return $length || 0;
}

sub _max_idx {
    my $self = CORE::shift();

    # TODO: cache max index

    my $table = $self->table_name;
    my ($idx) = $self->dbh->selectrow_array("SELECT MAX(idx) FROM $table WHERE qkey=?",
                                               undef, $self->key);
    die $self->dbh->errstr if $self->dbh->err;

    return defined $idx ? $idx + 1 : 0;
}

# do a sql statement and die if it fails
sub do {
    my ($self, $sql, @vals) = @_;

    $self->dbh->do($sql, undef, @vals);
    croak $self->dbh->errstr if $self->dbh->err;
}

# initialize the storage
sub init {
    my ($self) = @_;

    croak "No table name defined" unless $self->table_name;

    # don't do anything if table already exists
    return if $self->table_exists;

    # table doesn't exist, create it
    my $sql = sprintf($schema, $self->table_name);
    $self->do($sql);
}

# load data from db
sub load {
    my $self = CORE::shift();

    my $table = $self->table_name or croak "No table name defined";
    die "Table $table does not exist." unless $self->table_exists;

    my $rows = $self->dbh->selectall_arrayref("SELECT value FROM $table WHERE qkey=? ORDER BY idx", undef, $self->key);
    die $self->dbh->errstr if $self->dbh->err;

    return unless $rows && @$rows;
    $self->absorb_rows(@$rows);
}

sub absorb_rows {
    my ($self, @rows) = @_;
    push @{$self->{q}}, map { $_->[0] } @rows;
}

# delete everything from the queue
sub empty {
    my ($self) = @_;

    my $table = $self->table_name;
    $self->do("DELETE FROM $table WHERE qkey=?", $self->key);

    $self->{q} = [] if $self->caching;
}

sub table_exists {
    my $self = CORE::shift();
    # get table info, see if our table exists
    my @tables = $self->dbh->tables(undef, undef, $self->{table_name}, "TABLE");
    my $table = $self->{table_name};

    $table = $self->dbh->quote_identifier($self->{table_name})
        if $self->dbh->get_info(29); # quote if the db driver uses table name quoting

    return grep { $_ =~ m/$table$/ } @tables;
}

# add @vals to the queue
*add = \&unshift;
sub unshift {
    my ($self, @vals) = @_;

    my $idx = $self->_max_idx;

    my $key = $self->dbh->quote($self->key);
    my $table = $self->table_name;
    my $dbh = $self->dbh;

    $dbh->begin_work;
    my $sth = $dbh->prepare(qq[ INSERT INTO $table (qkey, idx, value) VALUES ($key, ?, ?) ]);

    foreach my $val (@vals) {
        push @{$self->{q}}, $val if $self->caching;

        $sth->execute($idx++, $val);
        if ($dbh->err) {
            die $dbh->errstr;
            $dbh->rollback;
        }
    }

    $dbh->commit;

    # truncate queue to max_size
    my $max_size = $self->max_size;
    my $length = $self->length;
    $self->shift($length - $max_size) if defined $max_size && $length > $max_size;
}

# shift $count elements off the queue
*remove = \&shift;
sub shift {
    my ($self, $_count) = @_;

    my $count = defined $_count ? $_count : 1;
    $count += 0;

    if ($self->caching) {
        CORE::shift(@{$self->{q}}) for 1 .. $count;
    }

    my $table = $self->table_name;

    # begin transaction
    $self->dbh->begin_work;

    # get $count elements
    my $rows = $self->dbh->selectall_arrayref("SELECT idx, value FROM $table WHERE qkey = ? ORDER BY idx LIMIT $count",
                                              undef, $self->key);
    die $self->dbh->errstr if $self->dbh->err;

    my @idx = map { $_->[0] } @$rows;
    my @vals = map { $_->[1] } @$rows;

    return () unless @vals;

    # remove the retreived elements
    my $bindstr = join(',', map { '?' } @idx);
    $self->do("DELETE FROM $table WHERE qkey=? AND idx BETWEEN ? AND ?", $self->key, $idx[0], $idx[-1]);

    # commit transaction
    $self->dbh->commit;

    # return first element if no $count defined, otherwise return array of values
    return $vals[0] unless defined $_count;
    return @vals;
}

# retreive elements at an index
sub get {
    my ($self, $offset, $length, %opts) = @_;

    return $self->all unless defined $offset || defined $length;

    $length = -1 unless defined $length; # need to specify a limit when selecting an offset, this is wack
    $offset += 0;

    my $direction = $opts{reverse} ? "DESC" : '';

    my $table = $self->table_name;
    my $rows = $self->dbh->selectcol_arrayref("SELECT value FROM $table WHERE qkey = ? ORDER BY idx $direction LIMIT $length OFFSET $offset",
                                              undef, $self->key);
    die $self->dbh->errstr if $self->dbh->err;

    return wantarray ? @$rows : $rows->[0];
}

# returns all elements of the queue
sub all {
    my $self = CORE::shift();

    return @{$self->{q}} if $self->caching;

    my $valsref = $self->dbh->selectall_arrayref("SELECT value FROM " . $self->table_name . " WHERE qkey = ?",
                                                 undef, $self->key);
    return map { @$_ } @$valsref;
}

1;

__END__

=head1 NAME

Data::Queue::Persistent - Perisistent database-backed queue

=head1 SYNOPSIS

  use Data::Queue::Persistent;
  my $q = Data::Queue::Persistent->new(
    table  => 'persistent_queue', # name to save queues in
    dsn    => 'dbi:SQLite:dbname=queue.db', # dsn for database to save queues
    id     => 'testqueue', # queue identifier
    cache  => 1,
    noload => 1, # don't load saved queue automatically
    max_size => 100, # limit to 100 items
  );
  $q->add('first', 'second', 'third', 'fourth');
  $q->remove;      # returns 'first'
  $q->remove(2);   # returns ('second', 'third')
  $q->empty;       # removes everything

=head1 DESCRIPTION

This is a simple module to keep a persistent queue around. It is just
a normal implementation of a queue, except it is backed by a database
so that when your program exits the data won't disappear.

=head2 EXPORT

None by default.

=head2 Methods

=over 4

=item * new(%opts)

Creates a new persistent data queue object. This will also initialize
the database storage, and load the saved queue data if it already
exists.

Options:

dsn: DSN for database connection.

dbh: Already initialized DBI connection handle.

id: The ID of this queue. You can have multiple queues stored in the
same table, distinguished by their IDs.

user: The username for database connection (optional).

pass: The password for database connection (optional).

cache: Enable caching of the queue for speed. Not reccommended if
multiple instances of the queue will be used concurrently. Default is
0.

table: The table name to use ('persistent_queue' by default).

noload: Don't load queue data when initialized (only applicable if caching is used)

max_size: Limit the queue to max_size, with the oldest elements falling off

=item * add(@items)

Adds a list of items to the queue.

=item * remove($count)

Removes $count (1 by default) items from the queue and returns
them. Returns value if no $count specified, otherwise returns an array
of values.

=item * get([$offset[, $length]])

Gets $length elements starting at offset $offset

=item * all

Returns all elements in the queue. Does not modify the queue.

=item * length

Returns count of elements in the queue.

=item * empty

Removes all elements from the queue.

=item * unshift(@items)

Alias for C<add(@items)>.

=item * shift($count)

Alias for C<remove($count)>.

=back

=head1 SEE ALSO

Any data structures book.

=head1 AUTHOR

Mischa Spiegelmock, E<lt>mspiegelmock@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Mischa Spiegelmock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
