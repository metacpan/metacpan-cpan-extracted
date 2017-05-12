package Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC::Metadata;
{
  $Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC::Metadata::VERSION = '2.143070';
}

use strict;
use warnings;

our @EXPORT;
BEGIN {
    use base 'Exporter';
    @EXPORT = qw/ dispatch_table source_dispatch_table schema_metadata /;
}

use SQL::Translator;
use SQL::Translator::AutoCRUD::Utils;

# return mapping of url path part to friendly display names
# for each result source within a given schema.
# also generate a cache of which App Model supports which source.
# die if the schema is not supported by this backend.
sub source_dispatch_table {
    my ($self, $c, $schema_path) = @_;
    my $display = {};

    die "failed to load metadata for schema [$schema_path] - is it DBIC?"
        if not exists $self->_schema_cache->{handles}->{$schema_path};
    my $cache = $self->_schema_cache->{handles}->{$schema_path};

    # rebuild retval from cache
    if (exists $cache->{sources}) {
        my $sources = $cache->{sources};
        return { map {($_ => {
                display_name => $sources->{$_}->{display_name},
            })} keys %$sources };
    }

    # find the catalyst model supporting each result source
    my $schema_model = $c->model( $cache->{model} );
    foreach my $moniker ($schema_model->schema->sources) {
        my $source_model = _find_source_model($c, $cache->{model}, $moniker)
            or die "unable to translate moniker [$moniker] into model";
        my $result_source = $c->model($source_model)->result_source;
        my $path = make_path($result_source);

        $display->{$path} = {
            display_name => make_label($path),
        };

        $cache->{sources}->{$path} = {
            model => $source_model,
            display_name => $display->{$path}->{display_name},
        };
    }

    # already cached for us
    return $display;
}

# return mapping of uri path part to friendly display names
# for each schema which this backend supports.
# also generate a cache of which App Model supports which schema.
sub dispatch_table {
    my ($self, $c) = @_;
    my ($display, %schema);
    my $cache = {};

    # rebuild retval from cache (copy)
    if (exists $self->_schema_cache->{handles}) {
        $cache = $self->_schema_cache->{handles};

        return { map {{
            display_name => $cache->{$_}->{display_name},
            t => $self->source_dispatch_table($c, $_),
        }} keys %$cache };
    }

    MODEL:
    foreach my $m ($c->models) {
        my $model = eval { $c->model($m) };
        next unless eval { $model->isa('Catalyst::Model::DBIC::Schema') };

        # some models are subclasses of others - skip them
        # this is usually the result source models created automagically
        foreach my $s (keys %schema) {
            if (eval { $model->isa($s) }) {
                delete $schema{$s};
            }
            elsif (eval { $c->model($s)->isa($m) }) {
                next MODEL;
            }
        }
        $schema{$m} = 1;
    }

    foreach my $s (keys %schema) {
        my $path = $c->model($s)->schema->storage->dbh->{Name};

        if ($path =~ m/\W/) {
            # SQLite will return a file name as the "database name"
            $path = lc [ reverse split '::', $s ]->[0];
        }

        $display->{$path} = { display_name => make_label($path) };
        $cache->{$path} = {
            model        => $s,
            display_name => $display->{$path}->{display_name},
        }
    }

    # source_dispatch_table needs to see the class-data cache
    $self->_schema_cache->{handles} = $cache;

    # now get data for the sources in each schema
    foreach my $p (keys %$cache) {
        $display->{$p}->{t} = $self->source_dispatch_table($c, $p);
    }

    return $display;
}

# generate SQLT Schema instance representing this data schema
sub schema_metadata {
    my ($self, $c) = @_;
    my $db = $c->stash->{cpac}->{g}->{db};

    return $self->_schema_cache->{sqlt}->{$db}
        if exists $self->_schema_cache->{sqlt}->{$db};

    my $dbic = $c->model(
        $self->_schema_cache->{handles}->{$db}->{model})->schema;
    my $sqlt = SQL::Translator->new(
        parser => 'SQL::Translator::Parser::DBIx::Class',
        parser_args => { dbic_schema => $dbic },
        filters => [
            ['AutoCRUD::StorageEngine::DBIC::ViewsAsTables', $dbic],
            ['AutoCRUD::StorageEngine::DBIC::Relationships', $dbic],
            ['AutoCRUD::StorageEngine::DBIC::DynamicDefault', $dbic],
            ['AutoCRUD::CatalystModel',
                $self->_schema_cache->{handles}->{$db}->{sources}],
            ['AutoCRUD::StorageEngine::DBIC::ProxyColumns', $dbic],
            'AutoCRUD::ColumnsAndPKs',
            'AutoCRUD::DisplayName',
            'AutoCRUD::ExtJSxType',
            ['AutoCRUD::StorageEngine::DBIC::AccessorDisplayName', $dbic],
        ],
        producer => 'SQL::Translator::Producer::POD', # something cheap
    ) or die SQL::Translator->error;

    $sqlt->translate() or die $sqlt->error; # throw result away

    $self->_schema_cache->{sqlt}->{$db} = $sqlt->schema;
    return $sqlt->schema;
}

# find catalyst model serving a DBIC *result source*
sub _find_source_model {
    my ($c, $parent_model, $moniker) = @_;

    foreach my $m ($c->models) {
        my $model = eval { $c->model($m) };
        my $test = eval { $model->result_source->source_name };
        next if !defined $test;

        return $m if $test eq $moniker and $m =~ m/^${parent_model}::/;
    }
    return undef;
}

1;
