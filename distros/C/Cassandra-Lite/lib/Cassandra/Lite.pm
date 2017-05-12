# ABSTRACT: Simple way to access Cassandra 0.7/0.8
package Cassandra::Lite;
BEGIN {
  $Cassandra::Lite::VERSION = '0.4.0';
}
use strict;
use warnings;

=head1 NAME

Cassandra::Lite - Simple way to access Cassandra 0.7/0.8

=head1 VERSION

version 0.4.0

=head1 DESCRIPTION

This module will offer you a simple way to access Cassandra 0.7/0.8 (maybe later version).
Some parts are not same as standard API document (especially arguments order), it's because I want to keep this module easy to use.

Before using this module, you need to know about the basic model of Cassandra.
L<http://wiki.apache.org/cassandra/DataModel> is a good start.

You'll need to install L<Thrift> perl modules first to use Cassandra::Lite.

B<WARNING: All API might be changed during development version.>

=head1 SYNOPSIS

First to initialize:

    use Cassandra::Lite;

    # Create with default options (C<keyspace> is a mantorary option):
    my $c = Cassandra::Lite->new(keyspace => 'Keyspace1');

    # Now just define $columnFamily and $key
    my $columnFamily = 'BlogArticle';
    my $key = 'key12345';

Then you can insert data:

    # Insert it.
    $c->put($columnFamily, $key, {title => 'testing title', body => '...'});

And get data:

    # Get a column
    my $scalarValue = $c->get($columnFamily, $key, 'title');

    # Get all columns
    my $hashRef = $c->get($columnFamily, $key);

More, to delete data:

    # Remove it
    $c->delete($columnFamily, $key);

Others:

    # Change keyspace
    $c->keyspace('BlogArticleComment');

    # Get count
    my $num2 = $c->get_count('Foo', 'key1');

    # Truncate column family
    $c->truncate('Foo');

=cut

use Any::Moose;
has 'client' => (is => 'rw', isa => 'Cassandra::CassandraClient', lazy_build => 1);
has 'consistency_level_read' => (is => 'rw', isa => 'Str', default => 'ONE');
has 'consistency_level_write' => (is => 'rw', isa => 'Str', default => 'ONE');
has 'keyspace' => (is => 'rw', isa => 'Str', trigger => \&_trigger_keyspace);
has 'password' => (is => 'rw', isa => 'Str', default => '');
has 'protocol' => (is => 'rw', isa => 'Thrift::BinaryProtocol', lazy_build => 1);
has 'server_name' => (is => 'rw', isa => 'Str', default => '127.0.0.1');
has 'server_port' => (is => 'rw', isa => 'Int', default => 9160);
has 'socket' => (is => 'rw', isa => 'Thrift::Socket', lazy_build => 1);
has 'transport' => (is => 'rw', isa => 'Thrift::FramedTransport', lazy_build => 1);
has 'transport_read' => (is => 'rw', isa => 'Int', default => 1024);
has 'transport_write' => (is => 'rw', isa => 'Int', default => 1024);
has 'username' => (is => 'rw', isa => 'Str', default => '');

use 5.010;
use Cassandra::Cassandra;
use Cassandra::Types;
use Thrift;
use Thrift::BinaryProtocol;
use Thrift::FramedTransport;
use Thrift::Socket;

=head1 FUNCTION
=cut

sub _build_client {
    my $self = shift;

    my $client = Cassandra::CassandraClient->new($self->protocol);
    $self->transport->open;
    $self->_login($client);

    $client;
}

sub _build_protocol {
    my $self = shift;

    Thrift::BinaryProtocol->new($self->transport);
}

sub _build_socket {
    my $self = shift;

    Thrift::Socket->new($self->server_name, $self->server_port);
}

sub _build_transport {
    my $self = shift;

    Thrift::FramedTransport->new($self->socket, $self->transport_read, $self->transport_write);
}

sub _consistency_level_read {
    my $self = shift;
    my $opt = shift // {};

    my $level = $opt->{consistency_level} // $self->consistency_level_read;

    eval "\$level = Cassandra::ConsistencyLevel::$level;";
    $level;
}

sub _consistency_level_write {
    my $self = shift;
    my $opt = shift // {};

    my $level = $opt->{consistency_level} // $self->consistency_level_write;

    eval "\$level = Cassandra::ConsistencyLevel::$level;";
    $level;
}

sub _login {
    my $self = shift;
    my $client = shift;

    my $auth = Cassandra::AuthenticationRequest->new;
    $auth->{credentials} = {username => $self->username, password => $self->password};
    $client->login($auth);
}

sub _trigger_keyspace {
    my ($self, $keyspace) = @_;

    $self->client->set_keyspace($keyspace);
}

=item
C<new(...)>

All supported options:

    my $c = Cassandra::Lite->new(
                server_name => 'server1',       # optional, default to '127.0.0.1'
                server_port => 9160,            # optional, default to 9160
                username => 'username',         # optional, default to empty string ''
                password => 'xxx',              # optional, default to empty string ''
                consistency_level_read => 'ONE' # optional, default to 'ONE'
                consistency_level_write => 'ONE' # optional, default to 'ONE'
                transport_read => 1024,         # optional, default to 1024
                transport_write => 1024,        # optional, default to 1024
                keyspace => 'Keyspace1',
            );

So, usually we can use this in dev environment:

    my $c = Cassandra::Lite->new(keyspace => 'Keyspace1');

=cut

=item
C<cql($query)>
=cut

sub cql {
    my $self = shift;

    my $query = shift;

    $self->client->execute_cql_query($query, Cassandra::Compression::NONE);
}

=item
C<delete($columnFamily, $key, $options)>

Delete entire row.
=cut

sub delete {
    my $self = shift;

    my $columnFamily = shift;
    my $key = shift;
    my $opt = shift // {};

    my $columnPath = Cassandra::ColumnPath->new({column_family => $columnFamily});
    my $timestamp = $opt->{timestamp} // time;

    my $level = $self->_consistency_level_write($opt);

    $self->client->remove($key, $columnPath, $timestamp, $level);
}

=item
C<get($columnFamily, $key, $column, $options)>

The simplest syntax is to get all columns:

    my $cf = 'BlogArticle';
    my $key1 = 'key12345';

    my $allColumns = $c->get($cf, $key1);

You can get a single column:

    my $title = $c->get($cf, $key1, 'title');

Also, you can get range column (this example will query from 'Column001' to 'Column999'):

    my $columns = $c->get($cf, $key1, {start => 'Column001', finish => 'Column999'});

With multiple keys:

    my $key2 = 'key56789';

    my $datas1 = $c->get($cf, [$key1, $key2]);
    my $datas2 = $c->get($cf, [$key1, $key2], {start => 'Column001', finish => 'Column999'});

With key range:

    my $datas3 = $c->get($cf, {start_key => 'a', end_key => 'b'});
    my $datas4 = $c->get($cf, {start_key => 'a', end_key => 'b'}, 'column');
    my $datas5 = $c->get($cf, {start_key => 'a', end_key => 'b'},
                         {start => 'Column001', finish => 'Column999'});

In order words, C<$key> can be scalar string (single key) or array reference (multiple keys).
And C<$column> can be undef (to get all columns), scalar string (to get one column), or hash reference (to get columns by range).

=cut

sub get {
    my $self = shift;

    my $columnFamily = shift;
    my $key = shift;
    my $column = shift;
    my $opt = shift // {};

    # Simple get is a totally different case.  It doesn't use columnParent.
    if ('SCALAR' eq ref \$key and defined $column and 'SCALAR' eq ref \$column) {
        my $columnPath = Cassandra::ColumnPath->new({column_family => $columnFamily, column => $column});
        my $level = $self->_consistency_level_read($opt);

        return $self->client->get($key, $columnPath, $level)->column->value;
    }

    my $columnParent = Cassandra::ColumnParent->new({column_family => $columnFamily});

    my $sliceRange;
    if (!defined $column) {
        $sliceRange = Cassandra::SliceRange->new({start => '', finish => ''});
    } elsif ('HASH' eq ref $column) {
        $sliceRange = Cassandra::SliceRange->new($column);
    } elsif ('SCALAR' eq ref \$column) {
        $sliceRange = Cassandra::SliceRange->new({start => $column, finish => $column});
    }

    my $predicate = Cassandra::SlicePredicate->new;
    $predicate->{slice_range} = $sliceRange;

    my $level = $self->_consistency_level_read($opt);

    if ('SCALAR' eq ref \$key) {
        return {map {$_->column->name => $_->column->value} @{$self->client->get_slice($key, $columnParent, $predicate, $level)}};
    }

    if ('ARRAY' eq ref $key) {
        my $ret = $self->client->multiget_slice($key, $columnParent, $predicate, $level);

        if (defined $column and 'SCALAR' eq ref \$column) {
            while (my ($k, $columns) = each %$ret) {
                $ret->{$k} = $columns->[0]->column->value;
            }
        } else {
            while (my ($k, $columns) = each %$ret) {
                $ret->{$k} = {map {$_->column->name => $_->column->value} @$columns};
            }
        }

        return $ret;
    } elsif ('HASH' eq ref $key) {
        my $range = Cassandra::KeyRange->new($key);
        my $ret = $self->client->get_range_slices($columnParent, $predicate, $range, $level);

        my $ret2 = {};

        if (defined $column and 'SCALAR' eq ref \$column) {
            foreach my $row (@$ret) {
                $ret2->{$row->key} = $row->columns->[0]->column->value;
            }
        } else {
            foreach my $row (@$ret) {
                $ret2->{$row->key} = {map {$_->column->name => $_->column->value} @{$row->columns}};
            }
        }

        return $ret2;
    }
}

=item
C<get_count($columnFamily, $key, $column, $options)>
=cut

sub get_count {
    my $self = shift;

    my $columnFamily = shift;
    my $key = shift;
    my $column = shift;
    my $opt = shift;

    my $columnParent = Cassandra::ColumnParent->new({column_family => $columnFamily});
    my $sliceRange = Cassandra::SliceRange->new($column);
    my $predicate = Cassandra::SlicePredicate->new({slice_range => $sliceRange});

    my $level = $self->_consistency_level_read($opt);

    if ('ARRAY' eq ref $key) {
        my $sliceRange = Cassandra::SliceRange->new($column);
        my $predicate = Cassandra::SlicePredicate->new({slice_range => $sliceRange});

        return $self->client->multiget_count($key, $columnParent, $predicate, $level);
    }

    $self->client->get_count($key, $columnParent, $predicate, $level);
}

=item
C<put($columnFamily, $key, $columns, $options)>
=cut

sub put {
    my $self = shift;

    my $columnFamily = shift;
    my $key = shift;
    my $columns = shift;
    my $opt = shift // {};

    my $level = $self->_consistency_level_write($opt);
    my $columnParent = Cassandra::ColumnParent->new({column_family => $columnFamily});
    my $column = Cassandra::Column->new;

    while (my ($k, $v) = each %$columns) {
        $column->{name} = $k;
        $column->{value} = $v;
        $column->{timestamp} = $opt->{timestamp} // time;

        $self->client->insert($key, $columnParent, $column, $level);
    }
}

=item
C<truncate($columnFamily)>

Truncate entire column family.
=cut

sub truncate {
    my $self = shift;

    my $columnFamily = shift;

    $self->client->truncate($columnFamily);
}

=head1 SEE ALSO

=over

=item *

Cassandra API

L<http://wiki.apache.org/cassandra/API>

=item *

Cassandra Thrift Interface

L<http://wiki.apache.org/cassandra/ThriftInterface>

=back

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gea-Suan Lin.

This software is released under 3-clause BSD license.
See L<http://www.opensource.org/licenses/bsd-license.php> for more information.

=cut

1;
