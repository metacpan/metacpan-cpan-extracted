# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB;

use v5.10;
use strict;
use warnings;

use Scalar::Util qw(weaken blessed);

use Carp;
use DBI;

use Data::TagDB::Tag;
use Data::TagDB::Relation;
use Data::TagDB::Metadata;
use Data::TagDB::LinkIterator;
use Data::TagDB::MultiIterator;
use Data::TagDB::WellKnown;
use Data::URIID::Colour;

our $VERSION = v0.04;



sub new {
    my ($pkg, $first, @rest) = @_;
    my $dbh;

    croak 'No dsn or dbh given to new' unless defined $first;

    if (scalar(@rest) == 0 && eval { $first->can('prepare'); }) {
        $dbh = $first;
    } else {
        $dbh = DBI->connect($first, @rest) or croak 'Cannot connect to database';
    }

    return bless {
        dbh => $dbh,
        cache_tag => {},
        cache_ise => {},
        cache_default_type => {},
        cache_default_encoding => {},
        backup_type => {},
        query => {
            tag_by_hint => $dbh->prepare('SELECT tag FROM hint WHERE name = ?'),
            _tag_simple_identifier => $dbh->prepare('SELECT data FROM metadata WHERE relation = (SELECT tag FROM hint WHERE name = \'also-shares-identifier\') AND type = (SELECT tag FROM hint WHERE name = ?) AND context = 0 AND encoding = 0 AND tag = ? ORDER BY data DESC'),
            _tag_by_dbid_type_and_data => $dbh->prepare('SELECT tag FROM metadata WHERE relation = (SELECT tag FROM hint WHERE name = \'also-shares-identifier\') AND type = ? AND context = 0 AND encoding = 0 AND data = ?'),
            _create_tag => $dbh->prepare('INSERT INTO tag DEFAULT VALUES'),
            _create_metadata => $dbh->prepare('INSERT OR IGNORE INTO metadata (tag,relation,context,type,encoding,data) VALUES (?,?,?,?,?,?)'),
            _create_relation => $dbh->prepare('INSERT OR IGNORE INTO relation (tag,relation,related,context,filter) VALUES (?,?,?,?,?)'),
        },
    }, $pkg;
}


sub dbh {
    my ($self) = @_;
    return $self->{dbh};
}


sub disconnect {
    my ($self) = @_;
    $self->assert_connected->disconnect;
    $self->{dbh} = undef;
}


sub tag_by_id {
    my ($self, $type, $id, $autocreate) = @_;

    # Shift arguments into correct order as needed:
    if (blessed($type) && $type->isa('Data::Identifier')) {
        ($self, $id, $autocreate) = @_;

        $type = $id->type;

        # Is $type === UUID?
        # TODO: Make this a better check.
        if ($type == $type->type && $type->id eq '8be115d2-dc2f-4a98-91e1-a6e3075cbc31') {
            $type = $self->tag_by_hint('uuid');
        } else {
            $type = $self->tag_by_id($type);
        }

        $id = $id->id;
    }

    $type = $self->tag_by_hint($type) unless eval { $type->isa('Data::TagDB::Tag') };

    if ($autocreate) {
        return $self->create_tag([$type => $id]);
    } else {
        return $self->tag_by_dbid($self->_get_data(_tag_by_dbid_type_and_data => ($type->dbid, $id)));
    }
}


sub relation {
    my ($self, %opts) = @_;
    return $self->_link_iterator(%opts, package => 'Data::TagDB::Relation');
}


sub metadata {
    my ($self, %opts) = @_;
    return $self->_link_iterator(%opts, package => 'Data::TagDB::Metadata');
}


sub link {
    my ($self, %opts) = @_;
    return Data::TagDB::MultiIterator->new(db => $self, iterators => [
            $self->metadata(%opts),
            $self->relation(%opts),
        ]);
}


sub wk {
    my ($self) = @_;
    return $self->{wk} //= Data::TagDB::WellKnown->_new(db => $self);
}


sub register_decoder {
    my ($self, $type, $encoding, $decoder) = @_;
    my $decoders = $self->{decoders} //= $self->_register_basic_decoders;
    $decoders->{$type->dbid} //= {};
    $decoders->{$type->dbid}{$encoding->dbid} = $decoder;
}


sub create_tag {
    my ($self, $ids, $addional_ids) = @_;
    my $asi = $self->wk->also_shares_identifier;
    my $asi_dbid = $asi->dbid;
    my $query_tpl = 'SELECT tag FROM metadata WHERE relation = '.$asi_dbid.' AND type = ? AND context = 0 AND encoding = 0 AND data = ?';
    my $query = '';
    my @bind;
    my $row;
    my $tag;

    if (blessed($ids) && $ids->isa('Data::Identifier')) {
        $ids = [$self->tag_by_id($ids->type) => $ids->id];
    }

    if (blessed($addional_ids) && $addional_ids->isa('Data::Identifier')) {
        $addional_ids = [$self->tag_by_id($addional_ids->type) => $addional_ids->id];
    }

    for (my $i = 0; $i < scalar(@{$ids}); $i += 2) {
        my $type  = $ids->[$i + 0];
        my $value = $ids->[$i + 1];

        next unless defined $value;

        $query .= ' UNION ' if length $query;

        $query .= $query_tpl;
        push(@bind, $type->dbid, $value);
    }

    $query = $self->dbh->prepare($query);
    $query->execute(@bind);
    $row = $query->fetchrow_arrayref;
    $query->finish;

    if (defined($row) && defined($row->[0]) && $row->[0] > 0) {
        $tag = $self->tag_by_dbid($row->[0]);
    } else {
        $query = $self->_query('_create_tag');
        $query->execute;
        $tag = $self->tag_by_dbid($query->last_insert_id);
        $query->finish;
    }

    for (my $i = 0; $i < scalar(@{$ids}); $i += 2) {
        my $type  = $ids->[$i + 0];
        my $value = $ids->[$i + 1];

        $self->create_metadata(tag => $tag, relation => $asi, type => $type, data_raw => $value);
    }

    if (defined $addional_ids) {
        for (my $i = 0; $i < scalar(@{$addional_ids}); $i += 2) {
            my $type  = $addional_ids->[$i + 0];
            my $value = $addional_ids->[$i + 1];

            next unless defined $value;

            $self->create_metadata(tag => $tag, relation => $asi, type => $type, data_raw => $value);
        }
    }

    return $tag;
}


sub create_metadata {
    my ($self, %opts) = @_;
    my $query = $self->_query('_create_metadata');
    my @bind = (
        $opts{tag}->dbid,
        $opts{relation}->dbid,
        Data::TagDB::Tag::dbid($opts{context}),
        Data::TagDB::Tag::dbid($opts{type}),
        Data::TagDB::Tag::dbid($opts{encoding}),
        $opts{data_raw},
    );

    $query->execute(@bind);
    $query->finish;

    return Data::TagDB::Metadata->_new(%opts, db => $self);
}


sub create_relation {
    my ($self, %opts) = @_;
    my $query = $self->_query('_create_relation');
    my @bind = (
        $opts{tag}->dbid,
        $opts{relation}->dbid,
        $opts{related}->dbid,
        Data::TagDB::Tag::dbid($opts{context}),
        Data::TagDB::Tag::dbid($opts{filter}),
    );

    $query->execute(@bind);
    $query->finish;

    return Data::TagDB::Relation->_new(%opts, db => $self);
}


sub create_cache {
    my ($self) = @_;
    require Data::TagDB::Cache;
    return Data::TagDB::Cache->_new(db => $self);
}


sub migration {
    my ($self) = @_;
    require Data::TagDB::Migration;
    return $self->{migration} //= Data::TagDB::Migration->_new(db => $self);
}


sub factory {
    my ($self) = @_;
    require Data::TagDB::Factory;
    return $self->{factory} //= Data::TagDB::Factory->_new(db => $self);
}

# ---- Virtual methods ----

# ---- Private helpers ----

sub DESTROY {
    my ($self) = @_;
    eval { $self->disconnect };
}

sub assert_connected {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    confess 'Not connected to any database' unless defined $dbh;
    return $dbh;
}

sub tag_by_dbid {
    my ($self, $dbid) = @_;
    my $cache = $self->{cache_tag};
    if (defined $cache->{$dbid}) {
        return $cache->{$dbid};
    } else {
        my $tag = Data::TagDB::Tag->_new(db => $self, dbid => $dbid);
        $cache->{$dbid} = $tag;
        weaken($cache->{$dbid});
        return $tag;
    }
}

sub _tag_by_ise_cached {
    my ($self, $ise, $autocreate) = @_;
    if (defined $self->{cache_ise}{$ise}) {
        return $self->tag_by_dbid($self->{cache_ise}{$ise});
    } else {
        my $tag = $self->tag_by_id(uuid => $ise, $autocreate); # TODO: Allow all ISE here.
        $self->{cache_ise}{$ise} = $tag->dbid;
        return $tag;
    }
}

sub _default_type {
    my ($self, $relation) = @_;
    my $relation_dbid = $relation->dbid;
    if (defined $self->{cache_default_type}{$relation_dbid}) {
        return $self->tag_by_dbid($self->{cache_default_type}{$relation_dbid});
    } else {
        my $type = eval {$self->relation(tag => $relation, relation => $self->wk->default_type)->one->related};
        if (defined $type) {
            $self->{cache_default_type}{$relation_dbid} = $type->dbid;
        } elsif (defined $self->{backup_type}{$relation_dbid}) {
            return $self->tag_by_dbid($self->{cache_default_type}{$relation_dbid} = $self->{backup_type}{$relation_dbid});
        } else {
            die 'No default type known';
        }
        return $type;
    }
}

sub _default_encoding {
    my ($self, $type) = @_;
    my $type_dbid = $type->dbid;
    if (defined $self->{cache_default_encoding}{$type_dbid}) {
        return $self->tag_by_dbid($self->{cache_default_encoding}{$type_dbid});
    } else {
        my $encoding = $self->relation(tag => $type, relation => $self->wk->default_encoding)->one->related;
        $self->{cache_default_encoding}{$type_dbid} = $encoding->dbid;
        return $encoding;
    }
}

sub _register_backup_type {
    my ($self, $relation, $type) = @_;
    $self->{backup_type}{$relation->dbid} = $type->dbid;
}

sub _register_basic_decoders {
    my ($self) = @_;
    my $decoders = $self->{decoders} //= {};
    my $wk = $self->wk;
    my $decode_string = sub { $_[0]->data_raw };
    my $decode_uri    = sub { URI->new($_[0]->data_raw) };
    my $decode_int    = sub { my $v = $_[0]->data_raw; croak 'Bad data' unless $v =~ /^[0-9]+$/; int($v) };
    my $decode_colour = sub { Data::URIID::Colour->new(rgb => $_[0]->data_raw) };

    $self->register_decoder($wk->uuid,                  $wk->string_ise_uuid_encoding,          $decode_string);
    $self->register_decoder($wk->oid,                   $wk->string_ise_oid_encoding,           $decode_string);
    $self->register_decoder($wk->uri,                   $wk->ascii_uri_encoding,                $decode_uri);
    $self->register_decoder($wk->tagname,               $wk->utf_8_string_encoding,             $decode_string);
    $self->register_decoder($wk->x11_colour_name,       $wk->utf_8_string_encoding,             $decode_string);
    $self->register_decoder($wk->wikidata_identifier,   $wk->utf_8_string_encoding,             $decode_string);
    $self->register_decoder($wk->small_identifier,      $wk->ascii_decimal_integer_encoding,    $decode_int);
    $self->register_decoder($wk->unicode_string,        $wk->utf_8_string_encoding,             $decode_string);
    $self->register_decoder($wk->colour_value,          $wk->hex_rgb_encoding,                  $decode_colour);

    $self->_register_backup_type($wk->wd_unicode_character, $wk->unicode_string);
    $self->_register_backup_type($wk->also_has_description, $wk->unicode_string);

    return $decoders;
}

sub _get_decoder {
    my ($self, $metadata) = @_;
    my $decoders = $self->{decoders} //= $self->_register_basic_decoders;
    my $for_type = $decoders->{$metadata->type_evaluated->dbid} //= {};
    return $for_type->{$metadata->encoding_evaluated->dbid} // croak 'No matching decoder found';
}

sub _query {
    my ($self, $name) = @_;
    $self->assert_connected;
    return $self->{query}{$name} // confess 'No such query: '.$name;
}

sub _get_data {
    my ($self, $name, @args) = @_;
    my $query = $self->_query($name);
    my $row;

    $query->execute(@args);
    $row = $query->fetchrow_arrayref;
    $query->finish;

    croak 'No such entry' unless defined $row;

    return $row->[0];
}

sub _build_query {
    my ($self, %opts) = @_;
    my %parts;
    my @where;
    my @binds;

    if ($opts{package} eq 'Data::TagDB::Metadata') {
        $parts{FROM} = 'metadata';
        $parts{SELECT} = '*'; # TODO
    } else {
        $parts{FROM} = 'relation';
        $parts{SELECT} = '*'; # TODO
    }

    if (defined $opts{limit}) {
        $parts{LIMIT} = $opts{limit};
    }

    foreach my $key (qw(tag relation context filter related type encoding)) {
        foreach my $neg (0, 1) {
            my $curkey = ($neg ? 'no_' : '').$key;
            if (defined $opts{$curkey}) {
                my @list = ref($opts{$curkey}) eq 'ARRAY' ? @{$opts{$curkey}} : ($opts{$curkey});

                foreach my $ent (@list) {
                    croak 'Something not a Data::TagDB::Tag used as Tag filter' unless $ent->isa('Data::TagDB::Tag');
                }

                push(@where, sprintf('%s %sIN (%s)', $key, $neg ? 'NOT ' : '', join(',', map {$_->dbid} @list)));
            }
        }
    }

    if (defined $opts{data_raw}) {
        push(@where, 'data = ?');
        push(@binds, $opts{data_raw});
    }

    if (scalar(@where)) {
        $parts{WHERE} = join(' AND ', @where);
    }

    if (defined $opts{order_by}) {
        my @list = ref($opts{order_by}) eq 'ARRAY' ? @{$opts{order_by}} : ($opts{order_by});
        if (scalar @list) {
            $parts{ORDER} = 'BY '.join(', ',
                map {sprintf('%s ASC', $_)} @list
            );
        }
    }

    {
        my $q = '';
        my $sth;

        foreach my $key (qw(SELECT FROM WHERE ORDER LIMIT)) {
            if (defined $parts{$key}) {
                $q .= ' ' if length $q;
                $q .= $key.' '.$parts{$key};
            }
        }

        $sth = $self->dbh->prepare($q);
        $sth->execute(@binds);
        return $sth;
    }
}

sub _link_iterator {
    my ($self, %opts) = @_;
    my $query = $self->_build_query(%opts);
    my %args;

    if ($opts{package} eq 'Data::TagDB::Metadata') {
        $args{tag_keys} = {map{$_ => $_} qw(type encoding)};
        $args{raw_keys} = {data_raw => 'data'};
    } else {
        $args{tag_keys} = {map{$_ => $_} qw(filter related)};
        $args{raw_keys} = {}; # empty
    }

    # Add common keys:
    $args{tag_keys}{$_} = $_ foreach qw(tag relation context);

    return Data::TagDB::LinkIterator->new(%args, db => $self, query => $query, package => $opts{package});
}

# ---- AUTOLOAD ----

sub AUTOLOAD {
    my ($self, @args) = @_;
    our $AUTOLOAD;
    my $function = $AUTOLOAD =~ s/^.*:://r;
    my $query = $self->{query}->{$function} or confess 'Bad function: '.$function;

    if ($function =~ /^tag_by_/) {
        my $row;

        $query->execute(@args);
        $row = $query->fetchrow_hashref;
        $query->finish;

        croak 'No such tag' unless defined($row->{tag}) && $row->{tag} > 0;

        return $self->tag_by_dbid($row->{tag});
    } else {
        confess 'Unsupported function with know query: '.$function;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB - Work with Tag databases

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use Data::TagDB;

    my $db = Data::TagDB->new($dsn, ...);
    # or:
    my $db = Data::TagDB->new($dbh);

    # Create new database:
    use Data::TagDB::Migration;
    my Data::TagDB $db = Data::TagDB::Migration->create(...);

This module implements SQL based universal tag databases. Such databases can be used to store any kind of (semantic) data.

This module and it's submodule implement creation of databases, migration (to most current scheme),
adding data and reading data from the database.

The instances of L<Data::TagDB::Tag> repesent any kind of object (may it be file, user account or a real life object like a tree).
It provides some convenience functions such as to query objects for their name.

L<Data::TagDB::Factory> (via L</factory>) is provided for easy creation of new tags.

=head1 METHODS

=head2 new

    my $db = Data::TagDB->new($dsn, ...);
    # or:
    my $db = Data::TagDB->new($dbh);

Returns a new object that can be used for lookups.
Either an already connected L<DBI> handle can be passed or
data source that is then passed to L<DBI/connect> internally.

=head2 dbh

    my $dbh = $db->dbh;

Returns the current L<DBI> connection.

=head2 disconnect

    $db->disconnect

This disconnects from the database backend. It also renders this object useless.

=head2 tag_by_id

    my Data::TagDB::Tag $tag = $db->tag_by_hint($type => $id);
    # or:
    my Data::TagDB::Tag $tag = $db->tag_by_hint($hint => $id);
    # or:
    my Data::Identifier $id = ...;
    my Data::TagDB::Tag $tag = $db->tag_by_hint($id);
    # e.g:
    my Data::TagDB::Tag $tag = $db->tag_by_hint(uuid => 'abc...');

Gets a tag by an an identifier of the provided type. The type must be a C<Data::TagDB::Tag> or a
a string that is a valid hint.

If only argument is provided the argument must be an instance of L<Data::Identifier>.

=head2 relation

    my Data::TagDB::Iterator $iter = $db->relation(...);

Returns an iterator for relations.
The following keys can be used to filter the list. All must be L<Data::TagDB::Tag> or an array ref of them objects:
C<tag>,
C<relation>,
C<context>,
C<filter>, and
C<related>.
Each may be prefixed with C<no_> for negative filtering.

=head2 metadata

    my Data::TagDB::Iterator $iter = $db->metadata(...);

Returns an iterator for relations.
The following keys can be used to filter the list. All must be L<Data::TagDB::Tag> or an array ref of them objects:
C<tag>,
C<relation>,
C<context>,
C<type>, and
C<encoding>.
Each may be prefixed with C<no_> for negative filtering.

Additionally C<data_raw> can be used to filter for a data value.

=head2 link

    my Data::TagDB::Iterator $iter = $db->link(...);

This combines L</relation>, and L</metadata>. An iterator is returned that lists both metadata, and relations (in any order).
The common subset of filters can be used. Namely:
C<tag>,
C<relation>, and
C<context>.

=head2 wk

    my Data::TagDB::WellKnown $tag = $db->wk;
    my Data::TagDB::Tag       $tag = $wk->...;
    # e.g.:
    my Data::TagDB::Tag       $asi = $db->wk->also_shares_identifier;

Returns a dictionary of well known tags.

=head2 register_decoder

    $db->register_decoder($type, $encoding, sub { ... });

Registers a decoder for a given type and encoding. Both C<$type>, and C<$encoding>
must be L<Data::TagDB::Tag>.

=head2 create_tag

    my Data::TagDB::Tag $tag = $db->create_tag([$type => $value, ...], [$type => $value, ...]);
    # or:
    my Data::Identifier $id = ...;
    my Data::Identifier $extra = ...;
    my Data::TagDB::Tag $tag = $db->create_tag($id, [ $extra ]);

Create a tag (or return it if it already exists). Takes two lists if type-identifier pairs.
The first list is the list of identifiers that uniquely identify the tag (e.g. an UUID).
The second list contains additional, non unique identifiers (e.g. tagnames) and is optional.

If the tag does not exist it is created. Once it exists all identifiers added (for already existing tags missing identifiers are added).

Each list can be replaced by a single instance of L<Data::Identifier>.

=head2 create_metadata

    my Data::TagDB::Metadata $metadata = $db->create_metadata(
        tag         => $tag,        # required
        relation    => $relation,   # required
        context     => $context,
        type        => $type,
        encoding    => $encoding,
        data_raw    => $raw,        # required
    );

Create a metadata entry if it does not yet exist. Returns it once created.

=head2 create_relation

    my Data::TagDB::Relation $relation = $db->create_relation(
        tag         => $tag,        # required
        relation    => $relation,   # required
        related     => $related,    # required
        context     => $context,
        filter      => $filter,
    );

Creates a relation (if it does not yet exist) and returns it.

=head2 create_cache

    my Data::TagDB::Cache $cache = $db->create_cache;

Create a new cache object every time this is called.
Cache objects can be used to speed up processing.
See L<Data::TagDB::Cache> for details.

=head2 migration

    $db->migration->upgrade;

Get a migration object. This is mostly used for upgrading the database schema to the
current one. It is recommended to perform upgrades for long running processes.
For short running processes this can increase the startup time.

See also L<Data::TagDB::Migration>.

=head2 factory

    my Data::TagDB::Factory $factory = $db->factory;

Get a factory object used to create tags.
See also L<Data::TagDB::Factory> for details.

=head2 tag_by_hint

    my Data::TagDB::Tag $tag = $db->tag_by_hint($hint);

Get a tag by hint. What hints are supported depends on what is stored in the database's hint table.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
