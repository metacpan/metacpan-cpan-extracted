# Copyright (c) 2024-2025 Philipp Schafft

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
use Data::TagDB::Cloudlet;
use Data::URIID::Colour;

our $VERSION = v0.11;



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
            _default => {
                tag_by_hint => $dbh->prepare('SELECT tag FROM hint WHERE name = ?'),
                _tag_simple_identifier => $dbh->prepare('SELECT data FROM metadata WHERE relation = (SELECT tag FROM hint WHERE name = \'also-shares-identifier\') AND type = (SELECT tag FROM hint WHERE name = ?) AND context = 0 AND encoding = 0 AND tag = ? ORDER BY data DESC'),
                _tag_by_dbid_type_and_data => $dbh->prepare('SELECT tag FROM metadata WHERE relation = (SELECT tag FROM hint WHERE name = \'also-shares-identifier\') AND type = ? AND context = 0 AND encoding = 0 AND data = ?'),
                _create_tag => $dbh->prepare('INSERT INTO tag DEFAULT VALUES'),
                _create_metadata => $dbh->prepare('INSERT OR IGNORE INTO metadata (tag,relation,context,type,encoding,data) VALUES (?,?,?,?,?,?)'),
                _create_relation => $dbh->prepare('INSERT OR IGNORE INTO relation (tag,relation,related,context,filter) VALUES (?,?,?,?,?)'),
            },
            Pg => {
                _create_tag => $dbh->prepare('INSERT INTO tag DEFAULT VALUES RETURNING id'),
                _create_metadata => $dbh->prepare('INSERT INTO metadata (tag,relation,context,type,encoding,data) VALUES (?,?,?,?,?,?) ON CONFLICT DO NOTHING'),
                _create_relation => $dbh->prepare('INSERT INTO relation (tag,relation,related,context,filter) VALUES (?,?,?,?,?) ON CONFLICT DO NOTHING'),
            },
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
    $self->_cache_clear;
}


sub tag_by_id {
    my ($self, $type, $id, $autocreate) = @_;

    # Shift arguments into correct order as needed:
    if (blessed($type) && $type->isa('Data::Identifier')) {
        ($self, $id, $autocreate) = @_;

        $type = $id->type;

        # Is $type === UUID?
        # TODO: Make this a better check.
        if ($type->eq('uuid')) {
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


sub tag_by_specification {
    my ($self, $specification, %opts) = @_;
    my $wk = $self->wk;
    my $style = $opts{style};
    my $important = $opts{important};
    my $role = $opts{role};
    my @candidates;

    croak 'No style given' unless defined($style) && length($style);

    if ($style eq 'ise') {
        @candidates = (eval { $self->tag_by_id(uuid => $specification) } // eval { $self->tag_by_id(oid => $specification) } // eval { $self->tag_by_id(uri => $specification) });
    } elsif ($style eq 'tagpool') {
        unless ($opts{as_is}) {
            $important ||= $specification =~ s/\!$//;

            if (!defined($role) && $specification =~ s/^(.+)\@([^@]+)$/$2/) {
                $role = $self->tag_by_specification($1, %opts);
            }
        }

        if ($specification =~ /^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/) {
            return $self->tag_by_id(uuid => $specification);
        }

        @candidates = $self->metadata(
            relation => $wk->also_shares_identifier,
            type => $wk->tagname,
            encoding => undef,
            data_raw => $specification,
        )->collect('tag');
    } elsif ($style eq 'sirtx') {
        my ($type, $id);
        my $backup_type;

        $specification =~ s/^\[(.+)\]$/$1/;

        if ($specification =~ /^\/([0-9]+)$/) {
            $id = $1;
            $type = $wk->sirtx_function_number;
        } elsif ($specification =~ /^\/([a-z_]+)$/) {
            $id = $1;
            $type = $wk->sirtx_function_name;
        } elsif ($specification =~ /^\*([0-9]+)$/) {
            @candidates = ($opts{sirtx_local_ids}{int $1});
        } elsif ($specification eq '*') {
            @candidates = ($opts{sirtx_local_ids}{0});
        } elsif ($specification =~ /^\'([0-9]+)$/) {
            my $num = int($1);
            require Data::Identifier::Generate;
            my $id = Data::Identifier::Generate->integer($num);
            @candidates = ($self->tag_by_id($id));
        } elsif ($specification eq '\'') {
            @candidates = ($wk->zero);
        } elsif ($specification =~ /^[\&\%]([0-9a-zA-Z_]+)$/) {
            my $port_tag = $self->tag_by_specification($1, %opts);
            my $ports = $opts{sirtx_ports};
            my $len = scalar(@{$ports});

            for (my $i = 0; !scalar(@candidates) && $i < $len; $i += 2) {
                my $p = $ports->[$i];
                if ($port_tag == $p || $port_tag->dbid eq $p->dbid) {
                    @candidates = ($ports->[$i+1]);
                }
            }
        } elsif ($specification =~ /^(.+):(.+)$/) {
            ($type, $id) = ($1, $2);
        } else {
            $type = $wk->sirtx_logical;
            $backup_type = $wk->sirtx_function_name;
            $id = $specification;
        }

        if (defined $type) {
            unless (ref $type) {
                $type = $self->tag_by_specification($type, %opts);
            }

            @candidates = $self->metadata(
                relation => $wk->also_shares_identifier,
                type => $type,
                encoding => undef,
                data_raw => $id,
            )->collect('tag');

            if (scalar(@candidates) == 0 && defined($backup_type)) {
                @candidates = $self->metadata(
                    relation => $wk->also_shares_identifier,
                    type => $backup_type,
                    encoding => undef,
                    data_raw => $id,
                )->collect('tag');
            }
        }
    } else {
        croak 'Invalid/unsupported style: '.$style;
    }

    if ($important) {
        @candidates = $self->relation(
            tag => \@candidates,
            relation => $wk->flagged_as,
            related => $wk->important,
        )->collect('tag');
    }

    if (defined $role) {
        @candidates = grep {
            $_->cloudlet('roles')->is_entry($role)
        } @candidates;
    }

    if (scalar(@candidates) == 1) {
        return $candidates[0];
    } elsif (scalar(@candidates) > 1) {
        croak 'Nore than one match found';
    } else {
        croak 'Tag not found';
    }

    die 'BUG';
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
        if ($self->_DBI_name eq 'Pg') {
            my $row = $query->fetchrow_arrayref;
            $tag = $self->tag_by_dbid($row->[0]);
        } else {
            $tag = $self->tag_by_dbid($query->last_insert_id);
        }
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
        $self->_as_tag($opts{tag}, 1)->dbid,
        $self->_as_tag($opts{relation}, 1)->dbid,
        Data::TagDB::Tag::dbid($self->_as_tag($opts{context}, 1)),
        Data::TagDB::Tag::dbid($self->_as_tag($opts{type}, 1)),
        Data::TagDB::Tag::dbid($self->_as_tag($opts{encoding}, 1)),
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
        $self->_as_tag($opts{tag}, 1)->dbid,
        $self->_as_tag($opts{relation}, 1)->dbid,
        $self->_as_tag($opts{related}, 1)->dbid,
        Data::TagDB::Tag::dbid($self->_as_tag($opts{context}), 1),
        Data::TagDB::Tag::dbid($self->_as_tag($opts{filter}), 1),
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


sub exporter {
    my ($self, $target, %opts) = @_;
    require Data::TagDB::Exporter;
    return Data::TagDB::Exporter->_new(db => $self, target => $target, %opts);
}


sub begin_work {
    my ($self, @args) = @_;
    croak 'Transaction already in process' if $self->{transaction_refc} || defined($self->{transaction_type});
    $self->{transaction_refc} = 1;
    return $self->dbh->begin_work(@args);
}

sub commit {
    my ($self, @args) = @_;
    croak 'No transaction in process' unless $self->{transaction_refc};
    $self->{transaction_refc}--;
    return if $self->{transaction_refc};
    return $self->dbh->commit(@args);
}

sub rollback {
    my ($self, @args) = @_;
    croak 'No transaction in process' unless $self->{transaction_refc};
    $self->{transaction_refc}--;
    return if $self->{transaction_refc};
    return $self->dbh->rollback(@args);
}


sub in_transaction {
    my ($self, $type, $code) = @_;
    my $error;

    croak 'Bad transaction type' unless $type eq 'ro' || $type eq 'rw';
    croak 'Transaction already in process' if $self->{transaction_refc};

    unless (defined($self->{transaction_type})) {
        $self->{transaction_type} = $type;
        $self->{transaction_open} = 0;
        $self->dbh->begin_work;
    }

    if ($self->{transaction_type} eq $type || $self->{transaction_type} eq 'rw') {
        # no-op
    } elsif ($self->{transaction_type} eq 'ro' && $type eq 'rw') {
        $self->{transaction_type} = $type;
    } else {
        $error = 'Transaction type missmatch';
    }

    unless (defined $error) {
        $self->{transaction_open}++;
        eval { $code->() };
        $self->{transaction_open}--;
    }

    unless ($self->{transaction_open}) {
        delete $self->{transaction_type};
        $self->dbh->commit;
    }

    croak $error if defined $error;
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
        state $done = 0;
        my $tag = Data::TagDB::Tag->_new(db => $self, dbid => $dbid);

        if ($done++ > 1024) {
            $self->_cache_maintain;
            $done = 0;
        }

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

sub _cache_maintain {
    my ($self) = @_;
    my $cache = $self->{cache_tag};

    foreach my $key (keys %{$cache}) {
        delete $cache->{$key} unless defined $cache->{$key};
    }
}

sub _cache_clear {
    my ($self) = @_;
    $self->_cache_maintain;
    %{$self->{cache_ise}} = ();
}

sub _as_tag {
    my ($self, $id, $autocreate) = @_;
    return undef unless defined $id;
    return $id if eval {$id->isa('Data::TagDB::Tag')};
    return $self->tag_by_id(Data::Identifier->new(from => $id, db => $self), $autocreate);
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

    eval { $self->register_decoder($wk->uuid,                  $wk->string_ise_uuid_encoding,          $decode_string) };
    eval { $self->register_decoder($wk->oid,                   $wk->string_ise_oid_encoding,           $decode_string) };
    eval { $self->register_decoder($wk->uri,                   $wk->ascii_uri_encoding,                $decode_uri) };
    eval { $self->register_decoder($wk->tagname,               $wk->utf_8_string_encoding,             $decode_string) };
    eval { $self->register_decoder($wk->x11_colour_name,       $wk->utf_8_string_encoding,             $decode_string) };
    eval { $self->register_decoder($wk->wikidata_identifier,   $wk->utf_8_string_encoding,             $decode_string) };
    eval { $self->register_decoder($wk->small_identifier,      $wk->ascii_decimal_integer_encoding,    $decode_int) };
    eval { $self->register_decoder($wk->unsigned_integer,      $wk->ascii_decimal_integer_encoding,    $decode_int) };
    eval { $self->register_decoder($wk->unicode_string,        $wk->utf_8_string_encoding,             $decode_string) };
    eval { $self->register_decoder($wk->colour_value,          $wk->hex_rgb_encoding,                  $decode_colour) };

    eval { $self->_register_backup_type($wk->wd_unicode_character, $wk->unicode_string) };
    eval { $self->_register_backup_type($wk->tagpool_tag_icontext, $wk->unicode_string) };
    eval { $self->_register_backup_type($wk->also_has_description, $wk->unicode_string) };
    eval { $self->_register_backup_type($wk->final_file_size,      $wk->unsigned_integer) };

    return $decoders;
}

sub _get_decoder {
    my ($self, $metadata) = @_;
    my $decoders = $self->{decoders} //= $self->_register_basic_decoders;
    my $for_type = $decoders->{$metadata->type_evaluated->dbid} //= {};
    return $for_type->{$metadata->encoding_evaluated->dbid} // croak 'No matching decoder found';
}

sub _DBI_name {
    my ($self) = @_;
    return $self->{_DBI_name} //= $self->dbh->{Driver}{Name}
}

sub _query {
    my ($self, $name) = @_;
    $self->assert_connected;
    return $self->{query}{$self->_DBI_name}{$name} // $self->{query}{_default}{$name} // confess 'No such query: '.$name;
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

sub _load_cloudlet {
    my ($self, %opts) = @_;
    my $direct = $opts{direct};
    my $indirect = $opts{indirect};

    $direct   = [$direct]   unless ref($direct) eq 'ARRAY';
    $indirect = [$indirect] unless ref($indirect) eq 'ARRAY' || !defined($indirect);

    return Data::TagDB::Cloudlet->new(db => $self, root => []) unless scalar(@{$direct});

    if (defined($indirect) && !scalar(@{$indirect})) {
        $indirect = undef;
    }

    if (defined $opts{indirect}) {
        my $query = 'WITH RECURSIVE X(related,root) AS (SELECT related,true FROM relation WHERE tag = ? AND relation IN ('.join(',', map{'?'} @{$direct}).') UNION SELECT relation.related,false FROM relation, X WHERE relation.relation IN ('.join(',', map{'?'} @{$indirect}).') AND relation.tag = X.related) SELECT related,root FROM X';
        my @bind = ($opts{tag}->dbid, map {$_->dbid} @{$direct}, @{$indirect});
        my $sth = $self->dbh->prepare($query);
        my @root;
        my @entry;

        $sth->execute(@bind);
        while (my $row = $sth->fetchrow_arrayref) {
            my $ent = $self->tag_by_dbid($row->[0]);
            if ($row->[1]) {
                push(@root, $ent);
            } else {
                push(@entry, $ent);
            }
        }
        $sth->finish;
        return Data::TagDB::Cloudlet->new(db => $self, root => \@root, entry => \@entry);
    } else {
        return Data::TagDB::Cloudlet->new(db => $self, root => [
                $self->relation(tag => $opts{tag}, relation => $opts{direct})->collect('related')
            ]);
    }

    # WITH RECURSIVE X(related,root) AS (SELECT related,true FROM relation WHERE tag = 597 AND relation IN (7, 201) UNION SELECT relation.related,false FROM relation, X WHERE relation.relation = 140 AND relation.tag = X.related) SELECT *,(SELECT data FROM metadata WHERE tag = X.related AND relation = 1 AND type = 5 LIMIT 1) FROM X
}

# ---- AUTOLOAD ----

sub AUTOLOAD {
    my ($self, @args) = @_;
    our $AUTOLOAD;
    my $function = $AUTOLOAD =~ s/^.*:://r;
    my $query = $self->{query}{$self->_DBI_name}{$function} // $self->{query}{_default}{$function} // confess 'Bad function: '.$function;

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

version v0.11

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

For an introduction see L<Data::TagDB::Tutorial>.

The instances of L<Data::TagDB::Tag> repesent any kind of object (may it be file, user account or a real life object like a tree).
It provides some convenience functions such as to query objects for their name.

L<Data::TagDB::Factory> (via L</factory>) is provided for easy creation of new tags.

B<Note:>
Correct transaction management can improve performance I<significantly>. Sometimes the improvement can be by a factor of a few thousand.
Applications should therefore consider to group requests into transactions. This is also true for read only requests.

B<Note:>
Future versions of this module will depend on L<Data::Identifier>.

B<Note:>
This module supports SQLite and PostgreSQL (experimental).

=head1 METHODS

=head2 new

    my $db = Data::TagDB->new($dsn, ...);
    # or:
    my $db = Data::TagDB->new($dbh);

Returns a new object that can be used for lookups.
Either an already connected L<DBI> handle can be passed or
data source that is then passed to L<DBI/connect> internally.

If a open handle is passed, the same restrictions apply as for L</dbh>.

=head2 dbh

    my $dbh = $db->dbh;

Returns the current L<DBI> connection.

This connection can be used to call any transaction independent method on the handle.
It can for example be used to call L<DBI/ping> to keep the connection alive.

If methods are called that depend on the state of the transaction logic
(such as performing an SELECT or UPDATE) the state of the transaction B<must> be managed via
this module. See L</begin_work>.

The same holds true for any open handle passed to L</new>. When passed the handle must
not be in any active transaction and must not be used outside this module to change the transaction
state of the handle.

It is also wise to avoid interacting with the tables managed by this module. This may result in the
internal states being in a wrong state. It is however generally safe (but for the restrictions given above)
to interact with tables outside of the use of this module.

As table names that are in use by this module depend on the version of the schema that is currently active
(and may change in future) it is most wise to have any custom tables in a seperate namespace of some kind
(the exact ways to do this may depend on the type of database used).

=head2 disconnect

    $db->disconnect

This disconnects from the database backend. It also renders this object useless.

=head2 tag_by_id

    my Data::TagDB::Tag $tag = $db->tag_by_id($type => $id);
    # or:
    my Data::TagDB::Tag $tag = $db->tag_by_id($hint => $id);
    # or:
    my Data::Identifier $id = ...;
    my Data::TagDB::Tag $tag = $db->tag_by_id($id);
    # e.g:
    my Data::TagDB::Tag $tag = $db->tag_by_id(uuid => 'abc...');

Gets a tag by an an identifier of the provided type. The type must be a C<Data::TagDB::Tag> or a
a string that is a valid hint.

If only argument is provided the argument must be an instance of L<Data::Identifier>.

=head2 tag_by_specification

    my Data::TagDB::Tag $tag = $db->tag_by_specification($specification, style => $style [, %opts ]);

Gets a tag by specification according to a style.
This method is mostly useful to parse user input and find the corresponding tag.

B<Note:>
This method is experimental. It may change prototype, and behaviour or may be removed in future versions without warning.
Role matching depends on L<Data::TagDB::Tag/cloudlet> and is subject to its status.

The following styles are supported:

=over

=item C<ise>

The given specification is an UUID, OID, or URI.

=item C<tagpool>

The given specification is in tagpool format.
Both C<type@tag> and C<tag!> notation is supported (can also be mixed freely).

Parsing interacts with options the same way as tagpool does.

=item C<sirtx>

The given specification is in SIRTX format.
Currently only I<*local>, I<'number>, I<logical>, and I<type:id> formats are supported.
There is very limited support for I<%port>, and I<&port>.
Bracket-escape is only supported for top level.

Supports the options C<sirtx_local_ids>, and C<sirtx_ports>.

=back

The following (all optional) options are supported:

=over

=item C<as_is>

If true, this disables special parsing rules.
For style C<tagpool> it disables all parsing but the check for UUIDs.

=item C<important>

Requires the tag to be marked important.

=item C<role>

A role the tag is required to have.

=item C<sirtx_local_ids>

An hashref with the local id (without the C<*>) as key and L<Data::TagDB::Tag> as value.

=item C<sirtx_ports>

An arrayref with an even number of elements (key-value pairs).
Elements with an even index are considered the key (port).
They are followed by the corresponding (port) value.

All elements must be an instance of L<Data::TagDB::Tag>.

=back

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

=head2 exporter

    my Data::TagDB::Exporter $exporter = $db->exporter($target, %opts);

Create a new exporter. C<$target> must be a open file handle (that supports seeking)
or a filename.

See also L<Data::TagDB::Exporter>.

The following options (all optional) are defined:

=over

=item C<format>

The format to use. This can be L<Data::TagDB::Tag>, a L<Data::Identfier>, or a raw ISE string.

The default is I<tagpool-source-format> (C<e5da6a39-46d5-48a9-b174-5c26008e208e>).

=back

=head2 begin_work, commit, rollback

    $db->begin_work;
    # ...
    $db->commit;
    # or:
    $db->rollback;

Those methods are provided as proxy to L<DBI>'s.
The correct use of transactions can improve the speed (both for reading and writing)
significantly. Specifically tag databases are subject to many improvements of correct transaction
mangement.

B<Note:>
For each call to C<begin_work> there must be a matching call to C<commit> or C<rollback>.
This is important as this API will keep track of transactions internally.

B<Note:>
A call to C<begin_work> may or may not fail if another transaction is already in process.
This may depend on the type of database used.

B<Note:>
The return value of those methods is undefined. On error they will C<die>.

B<Note:>
These methods are mutually exclusive with the use of L</in_transaction> at this time.
However, the use of L</in_transaction> is recommended.

For details see also: L<DBI/begin_work>, L<DBI/commit>, L<DBI/rollback>.

=head2 in_transaction

    $db->in_transaction(ro => sub { ....});
    # or:
    $db->in_transaction(rw => sub { ....});

Runs a block of code (a subref) inside a transaction.

The passed block is run in a transaction. The transaction is commited after the code finishes.

The type of the transaction can be C<ro> (read only) or C<rw> (read-write).
The module may optimise based on this information.
If a write operation is performed in a transaction that is marked C<ro> the behaviour is unspecified.

In contrast to L</begin_work> and L</commit> calls to this method can be stacked freely.
For example the following is valid:

    $db->in_transaction(ro => sub {
        # do some read...
        $db->in_transaction(rw => sub {
            # do some write...
        });
        # do more reading, writing is invalid here
    });

B<Note:>
If the code C<die>s the error is ignored. The transaction is still commited.
If the code wants to perform rollback in case it fails this function might not be the one to use.

B<Note:>
Data written might only be visible to other handles of the same database once I<all>
transactions have been finished.

B<Note:>
This method is mutually exclusive with the use of L</begin_work> at this time.

=head2 tag_by_hint

    my Data::TagDB::Tag $tag = $db->tag_by_hint($hint);

Get a tag by hint. What hints are supported depends on what is stored in the database's hint table.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
