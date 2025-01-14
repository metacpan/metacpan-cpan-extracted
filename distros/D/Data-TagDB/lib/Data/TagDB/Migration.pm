# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Migration;

use v5.10;
use strict;
use warnings;

use Scalar::Util qw(weaken);
use Carp;

use Data::TagDB;

use parent 'Data::TagDB::WeakBaseObject';

use constant RE_UUID => qr/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/;

use constant {
    FORMAT_TAGPOOL_SOURCE_FORMAT => 'e5da6a39-46d5-48a9-b174-5c26008e208e',
    FORMAT_TAGPOOL_TAGLIST_V1    => 'afdb46f2-e13f-4419-80d7-c4b956ed85fa',

    FEATURE_MODERN_LIMITED       => 'f06c2226-b33e-48f2-9085-cd906a3dcee0',
    FEATURE_HYBRID               => '5a1895b8-61f1-4ce1-a44f-1a239b7d9de7',
};

our $VERSION = v0.08;

my %table_defs = (
    tag      => 'CREATE TABLE IF NOT EXISTS tag (id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT);',
    hint     => 'CREATE TABLE IF NOT EXISTS hint (name VARCHAR(32) NOT NULL UNIQUE PRIMARY KEY, tag INTEGER NOT NULL REFERENCES tag(id));',
    metadata => 'CREATE TABLE IF NOT EXISTS metadata (tag INTEGER NOT NULL REFERENCES tag(id), relation INTEGER NOT NULL REFERENCES tag(id), context INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, type INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, encoding INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, data BLOB, UNIQUE(tag, relation, context, type, encoding, data));',
    relation => 'CREATE TABLE IF NOT EXISTS relation (tag INTEGER NOT NULL REFERENCES tag(id), relation INTEGER NOT NULL REFERENCES tag(id), context INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, related INTEGER NOT NULL REFERENCES tag(id), filter INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, UNIQUE(tag, relation, context, related, filter));',
);

my @indices = (
    [tag      => qw(id)],
    [hint     => qw(name)],
    [metadata => qw(tag)],
    [metadata => qw(tag relation)],
    [metadata => qw(data)],
    [relation => qw(tag)],
    [relation => qw(tag relation)],
    [relation => qw(related)],
);

my %indispensable = (
    'also-shares-identifier'    => 'ddd60c5c-2934-404f-8f2d-fcb4da88b633',
    'uuid'                      => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31',
);

my %hints = map {$_ => $_ =~ tr/_/-/r} (
    qw(also_shares_identifier tagname uuid uri oid wikidata_identifier small_identifier),  # recommend
    qw(important no_direct has_type owned_by implies flagged_as using_namespace for_type), # friendly
);

my %simple_relations = (
    'tag-type'          => '7f265548-81dc-4280-9550-1bd0aa4bf748',
    'tag-owner'         => '0ad7f760-8ee7-4367-97f2-ada06864325e',
    'tag-implies'       => 'e48cd5c6-83d7-411e-9640-cb370f3502fc',
    'tag-suggests'      => '56388bfe-39cd-4ea6-8224-f36a2a0b92ef', # filterless form only!
    'tag-replaced-by'   => 'd6e028d4-279e-453e-a7a3-16646bf091f7',
    'tag-generated-by'  => '8efbc13b-47e5-4d92-a960-bd9a2efa9ccb',
    'tag-links'         => 'd926eb95-6984-415f-8892-233c13491931',
);

my %simple_metadata = (
    'tag-description'       => 'ca33b058-b4ce-4059-9f0b-61ca0fd39c35',
    'tag-generator-request' => 'ab573786-73bc-4f5c-9b03-24ef8a70ae45',
    'tag-description-uri'   => '0a5e125d-d863-4013-b961-648205c2c460',
);

my %simple_flags = (
    'tag-mark-important'    => 'e6135f02-28c1-4973-986c-ab7a6421c0a0',
    'tag-remove'            => '34d5124b-7f47-4ddd-ab02-560396acee56',
    'tag-mark-no-direct'    => '05648b38-e73c-485c-b536-286ce0918193',
);



sub upgrade {
    my ($self) = @_;
    $self->_create_tables;
    $self->_create_indices;
    $self->_create_hints_indispensable;
    $self->_create_hints;
}


sub create {
    my ($pkg, $first, @rest) = @_;
    my Data::TagDB $db;
    my __PACKAGE__ $self;
    my DBI $dbh;

    if (scalar(@rest) == 0 && eval { $first->can('prepare'); }) {
        $dbh = $first;
    } else {
        $dbh = DBI->connect($first, @rest) or croak 'Cannot connect to database';
    }

    $dbh->begin_work;

    $self = $pkg->_new(dbh => $dbh);

    $self->_create_tables;
    $self->_create_tag_null;
    $self->_create_hints_indispensable;

    $db = Data::TagDB->new($dbh);

    $self->{db} = $db;
    weaken($self->{db});

    $self->upgrade;

    $dbh->commit;

    return $db;
}


sub db {
    my ($self) = @_;
    return $self->{db};
}


sub dbh {
    my ($self) = @_;
    return $self->{dbh};
}


sub include {
    my ($self, @sources) = @_;
    my $cache = $self->db->create_cache;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $db->wk;

    $cache->add(
        $wk->also_shares_identifier(1),
        $wk->uuid(1),
        $wk->tagname(1),
    );

    foreach my $entry (@sources) {
        my $source;

        $entry = {source => $entry} unless ref $entry;
        $source = $entry->{source};

        if ($source eq 'Data::TagDB::WellKnown') {
            my Data::TagDB::Tag $asi = $wk->also_shares_identifier(1);
            my Data::TagDB::Tag $tagname = $wk->tagname(1);
            my Data::TagDB::Tag $sid = $wk->small_identifier(1);
            my Data::TagDB::Tag $default_type = $wk->default_type(1);
            my Data::TagDB::Tag $default_encoding = $wk->default_encoding(1);
            foreach my $name ($wk->_list) {
                my Data::TagDB::Tag $tag = $wk->_call($name, 1);
                my $info = $wk->_info($name);
                $db->create_metadata(tag => $tag, relation => $asi, type => $tagname, data_raw => $info->{tagname}) if defined $info->{tagname};
                $db->create_metadata(tag => $tag, relation => $asi, type => $sid,     data_raw => $info->{sid})     if defined $info->{sid};
                $db->create_relation(tag => $tag, relation => $default_type,     related => $wk->_call($info->{default_type},     1)) if defined $info->{default_type};
                $db->create_relation(tag => $tag, relation => $default_encoding, related => $wk->_call($info->{default_encoding}, 1)) if defined $info->{default_encoding};
            }
        } elsif ($source eq 'Data::URIID') {
            require Data::URIID;
            my Data::TagDB::Tag $uuid = $wk->uuid(1);
            my $extractor = Data::URIID->new;

            foreach my $class (qw(service type action)) {
                foreach my $ise ($extractor->known($class)) {
                    if ($ise =~ RE_UUID) {
                        $db->create_tag([$uuid => $ise]);
                    }
                }
            }
        } elsif ($source eq 'Data::Identifier') {
            require Data::Identifier;
            my Data::TagDB::Tag $uuid = $wk->uuid(1);
            my Data::TagDB::Tag $sid = $wk->small_identifier(1);
            foreach my $identifier (Data::Identifier->wellknown) {
                my $identifier_sid = eval {$identifier->sid}; # sids in Data::Identifier are accurate (but may be undef).
                $db->create_tag([
                        $uuid => $identifier->uuid,
                        defined($identifier_sid) ? ($sid => $identifier_sid) : (),
                        ]);
            }
        } elsif (($source =~ /::/ || $source =~ /^[A-Z]/) && $source->isa('Data::Identifier::Interface::Known')) {
            foreach my $identifier (Data::Identifier->known(':all', as => 'Data::Identifier')) {
                $db->create_tag($identifier);
            }
        } elsif ($source eq 'file') {
            $self->_ingest_file($entry->{handle} // $entry->{filename}, %{$entry});
        } elsif ($source eq 'directory') {
            $self->_ingest_directory($entry->{filename}, %{$entry});
        } else {
            croak 'Invalid datasource: '.$source;
        }
    }
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;

    $opts{dbh} //= $opts{db}->dbh;

    return $pkg->SUPER::_new(%opts);
}

sub _create_table {
    my ($self, $name) = @_;
    my $query = $self->dbh->prepare($table_defs{$name});
    $query->execute;
    $query->finish;
}

sub _create_tables {
    my ($self) = @_;

    $self->_create_table($_) foreach qw(tag hint metadata relation);
}

sub _create_tag_null {
    my ($self) = @_;
    my DBI $dbh = $self->dbh;
    my $query = $dbh->prepare('INSERT INTO tag (id) VALUES (0);');
    $query->execute;
    $query->finish;
}

sub _create_hints_indispensable {
    my ($self) = @_;
    my DBI $dbh = $self->dbh;
    my %ids;

    # This loop is not efficient. However we only run it once per database. So no problem.

    foreach my $name (keys %indispensable) {
        my $query = $dbh->prepare('SELECT tag FROM hint WHERE name = ?');
        my $row;
        my $dbid;

        $query->execute($name);
        $row = $query->fetchrow_arrayref;
        $query->finish;

        next if defined($row) && defined($row->[0]) && $row->[0] > 0;

        $query = $dbh->prepare('INSERT INTO tag DEFAULT VALUES');
        $query->execute;
        $dbid = $query->last_insert_id;
        $query->finish;

        $query = $dbh->prepare('INSERT OR IGNORE INTO hint (name,tag) VALUES (?,?)');
        $query->execute($name, $dbid);
        $query->finish;

        $ids{$name} = $dbid;
    }

    {
        my $query = $dbh->prepare('INSERT OR IGNORE INTO metadata (tag,relation,context,type,encoding,data) VALUES (?,?,0,?,0,?)');
        foreach my $name (keys %indispensable) {
            my $dbid = $ids{$name};
            my $uuid = $indispensable{$name};

            $query->execute($dbid, $ids{'also-shares-identifier'}, $ids{uuid}, $uuid);
            $query->finish;
        }
    }
}

# This requies the database being fully up, so we have a $self->db.
sub _create_hints {
    my ($self) = @_;
    my DBI $dbh = $self->dbh;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $db->wk;

    foreach my $name (keys %hints) {
        my Data::TagDB::Tag $tag = $wk->_call($name, 1);
        my $query = $dbh->prepare('INSERT OR IGNORE INTO hint (name,tag) VALUES (?,?)');
        $query->execute($hints{$name}, $tag->dbid);
        $query->finish;
    }
}

sub _create_index {
    my ($self, $table, @fields) = @_;
    my DBI $dbh = $self->dbh;
    my $query;

    die 'Bad parameters' unless scalar @fields;

    $query = $dbh->prepare('CREATE INDEX IF NOT EXISTS '.$table.'_'.join('_', @fields).' ON '.$table.' ('.join(',', @fields).');');
    $query->execute;
    $query->finish;
}

sub _create_indices {
    my ($self) = @_;
    $self->_create_index(@{$_}) foreach @indices;
}

sub _ingest_file {
    require File::ValueFile::Simple::Reader;
    require Data::Identifier;

    my ($self, $from, %opts) = @_;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $db->wk;
    my Data::TagDB::Tag $tag_uuid = $wk->uuid(1);
    my $reader = File::ValueFile::Simple::Reader->new(
        $from,
        supported_formats => [FORMAT_TAGPOOL_SOURCE_FORMAT, FORMAT_TAGPOOL_TAGLIST_V1],
        supported_features => [FEATURE_MODERN_LIMITED, FEATURE_HYBRID],
    );
    my $format = FORMAT_TAGPOOL_SOURCE_FORMAT;
    my %tagcache;

    $reader->read_to_cb(sub {
            my ($reader, @line) = @_;
            $format //= eval{$reader->format->ise};
            unless (defined($format)) {
                croak 'Undefined format';
            }

            if ($format eq FORMAT_TAGPOOL_SOURCE_FORMAT) {
                my ($command, $ise, @args) = @line;

                return unless scalar(@line); # ignore blank lines

                croak 'Bad input: no command or tag' unless defined($command) && (defined($ise) || $command =~ /^source-/);

                if ($command eq 'tag-ise') {
                    my @ids = map {$db->tag_by_id($_->type) => $_->id} map {Data::Identifier->new(ise => $_)} $ise, @args;
                    $db->create_tag(\@ids);
                } elsif ($command eq 'tag-metadata' && scalar(@args) == 5) {
                    my @tags = map {defined($_) ? $db->create_tag(Data::Identifier->new(ise => $_)) : undef} $ise, @args[0..3];
                    $db->create_metadata(
                        tag         => $tags[0],
                        relation    => $tags[1],
                        context     => $tags[2],
                        type        => $tags[3],
                        encoding    => $tags[4],
                        data_raw    => $args[-1],
                    );
                } elsif ($command eq 'tag-relation' && scalar(@args) >= 2 && scalar(@args) <= 4) {
                    my @tags = map {defined($_) ? $db->create_tag(Data::Identifier->new(ise => $_)) : undef} $ise, @args;
                    $db->create_relation(
                        tag         => $tags[0],
                        relation    => $tags[1],
                        related     => $tags[2],
                        context     => $tags[3],
                        filter      => $tags[4],
                    );
                } elsif ($command eq 'tag') {
                    $db->create_tag(Data::Identifier->new(ise => $ise), [map {$wk->tagname(1) => $_} @args]);
                } elsif (defined($simple_relations{$command}) && scalar(@args) == 1) {
                    my Data::TagDB::Tag $relation = $tagcache{$simple_relations{$command}} //= $db->create_tag([$tag_uuid => $simple_relations{$command}]);
                    my Data::TagDB::Tag $tag      = $db->create_tag(Data::Identifier->new(ise => $ise));
                    my Data::TagDB::Tag $related  = $db->create_tag(Data::Identifier->new(ise => $args[0]));
                    $db->create_relation(
                        tag         => $tag,
                        relation    => $relation,
                        related     => $related,
                    );
                } elsif (defined($simple_metadata{$command}) && scalar(@args) == 1) {
                    my Data::TagDB::Tag $relation = $tagcache{$simple_metadata{$command}} //= $db->create_tag([$tag_uuid => $simple_metadata{$command}]);
                    my Data::TagDB::Tag $tag      = $db->create_tag(Data::Identifier->new(ise => $ise));
                    $db->create_metadata(
                        tag         => $tag,
                        relation    => $relation,
                        data_raw    => $args[-1],
                    );
                } elsif (defined($simple_flags{$command}) && scalar(@args) == 0) {
                    my Data::TagDB::Tag $related  = $tagcache{$simple_flags{$command}} //= $db->create_tag([$tag_uuid => $simple_flags{$command}]);
                    my Data::TagDB::Tag $relation = $wk->flagged_as(1);
                    my Data::TagDB::Tag $tag      = $db->create_tag(Data::Identifier->new(ise => $ise));
                    $db->create_relation(
                        tag         => $tag,
                        relation    => $relation,
                        related     => $related,
                    );
                } elsif ($command =~ /^source-default-(?:mark-(?:important|no-direct)|type|owner|implies)$/ ||
                    $command eq 'tag-generator' ||
                    $command eq 'tag-generator-hint' ||
                    $command eq 'tag-suggests' ||
                    $command eq 'tag-implies' ||
                    $command eq 'tag-oid' ||
                    $command eq 'tag-description-image-uri') {
                    croak 'Known but unsupported command on import: '.$command unless $opts{skip_unsupported};
                } else {
                    croak 'Unknown command: '.$command unless $opts{skip_unknown};
                }
            } else {
                croak 'Unsupported format: '.$format;
            }
        });
}

sub _ingest_directory {
    my ($self, $from, %opts) = @_;

    require File::Spec;

    opendir(my $dir, $from) or die $!;
    foreach my $entry (sort readdir($dir)) {
        my $full = File::Spec->catfile($from, $entry);

        next if $entry =~ /^\./;

        if (-d $full) {
            next unless $entry =~ /^[0-9]{2}-/ || $entry =~ /\.d$/;
            $self->_ingest_directory($full, %opts);
        } else {
            next unless $entry =~ /^[0-9]{2}-/ || $entry =~ /\.vf$/;
            $self->_ingest_file($full, %opts);
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Migration - Work with Tag databases

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use Data::TagDB;

    my Data::TagDB $db = Data::TagDB->new(...);
    $db->migration->upgrade;

    use Data::TagDB::Migration;
    my Data::TagDB $db = Data::TagDB::Migration->create(...);

Create with or upgrade database to current schema.

=head1 METHODS

=head2 upgrade

    $db->migration->upgrade;

Upgrade database to current schema.
Also ensures all required base objects are present.

=head2 create

    my Data::TagDB $db = Data::TagDB::Migration->create(...);

Creates a database and returns an handle to it.
This function takes the same arguments as L<Data::TagDB/new>.

=head2 db

    my Data::TagDB $db = $migration->db;

Returns the current L<Data::TagDB> object.

=head2 dbh

    my $dbh = $migration->dbh;

Returns the current L<DBI> connection.

=head2 include

    $migration->include(...);
    # e.g:
    $migration->include('Data::TagDB::WellKnown', ...);
    # same as:
    $migration->include({source => 'Data::TagDB::WellKnown'}, ...);
    # or:
    $migration->include({source => 'xxx', %opts}, ...);
    # e.g.:
    $migration->include({source => 'file', filename => 'xxx'}, ...);

Includes data from a given source.

Currently supported sources:
L<Data::TagDB::WellKnown>,
L<Data::URIID>,
L<Data::Identifier>,
any package implementing L<Data::Identifier::Interface::Known>,
C<file>, and C<directory>.

B<Note:>
This function should be called inside a transaction (see L<Data::TagDB/begin_work>).
Runing this inside a transaction will result in a speedup often ranging between 10 and 100 times.
It is safe to mix this function with any other function within a single transaction.

If the source is C<file> the following options are supported:

=over

=item C<filename>

The name of the file to read.
Required if C<handle> is not given.

=item C<handle>

The handle to read from. Must allow seeking.
Required if C<filename> is not given.

=item C<skip_unsupported>

Skip known but unsupported directives. Which directives are supported depend on the format being read.

=back

The C<directory> source supports the same options as the C<file> source but C<handle>.
It will recursivly search the directory for usable files.
Files not matching the standard format will be skipped.

For the I<tagpool-source-format> the following directives are supported:

=over

=item Modern

C<tag-ise>,
C<tag-metadata>,
C<tag-relation>.

=item Legacy

C<tag>,
C<tag-type>,
C<tag-owner>,
C<tag-implies> (only non-filter form),
C<tag-suggests> (only non-filter form),
C<tag-replaced-by>,
C<tag-generated-by>,
C<tag-links>,
C<tag-description>,
C<tag-generator-request>,
C<tag-description-uri>,
C<tag-mark-important>,
C<tag-remove>,
C<tag-mark-no-direct>.

=item Known but unsupported

C<source-default-mark-important>,
C<source-default-mark-no-direct>,
C<source-default-type>,
C<source-default-owner>,
C<source-default-implies>,
C<tag-oid>,
C<tag-generator>,
C<tag-generator-hint>.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
