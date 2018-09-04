package Datahub::Factory::Importer::KMSKA;

use Datahub::Factory::Sane;

our $VERSION = '1.00';

use Moo;
use Catmandu;
use Config::Simple;
use Datahub::Factory::Importer::KMSKA::TMS::Index;
use namespace::clean;

with 'Datahub::Factory::Importer';

has db_host     => (is => 'ro', required => 1);
has db_name     => (is => 'ro', required => 1);
has db_user     => (is => 'ro', required => 1);
has db_password => (is => 'ro', required => 1);
has generate_temp_tables => (is => 'ro', default => 1);

sub _build_importer {
    my $self = shift;
    my $dsn = sprintf('dbi:mysql:%s', $self->db_name);

    my $query = 'select * from CITvgsrpObjTombstoneD_RO;';
    my $importer = Catmandu->importer('DBI', dsn => $dsn, host => $self->db_host, user => $self->db_user, password => $self->db_password, query => $query, encoding => ':iso-8859-1');

    if ($self->generate_temp_tables) {
        $self->prepare();
    }

    return $importer
}

sub prepare {
    my $self = shift;
    # Create temporary tables
    $self->logger->info('Adding "classifications" temporary table.');
    $self->__classifications();
    $self->logger->info('Adding "periods" temporary table.');
    $self->__period();
    $self->logger->info('Adding "dimensions" temporary table.');
    $self->__dimensions();
    $self->logger->info('Adding "subjects" temporary table.');
    $self->__subjects();
    $self->logger->info('Adding "constituents" temporary table.');
    $self->__constituents();
    $self->logger->info('Adding "datapids" temporary table.');
    $self->__datapids();
    $self->logger->info('Adding "representationpids" temporary table.');
    $self->__representationpids();
    $self->logger->info('Adding "workpids" temporary table.');
    $self->__workpids();
}

sub prepare_call {
    my ($self, $import_query, $store_table) = @_;
    my $importer = Catmandu->importer(
        'DBI',
        dsn      => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password,
        query    => $import_query
    );
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/tms_import.%s.sqlite', $store_table),
    );
   $importer->each(sub {
            my $item = shift;
            my $bag = $store->bag();
            # first $bag->get($item->{'_id'})
            $bag->add($item);
        });
}

sub merge_call {
    my ($self, $query, $key, $out_name) = @_;
    my $importer = Catmandu->importer(
        'DBI',
        dsn      => sprintf('dbi:mysql:%s', $self->db_name),
        host     => $self->db_host,
        user     => $self->db_user,
        password => $self->db_password,
        query    => $query
    );
    my $merged = {};
    $importer->each(sub {
        my $item = shift;
        my $objectid = $item->{'objectid'};
        if (exists($merged->{$objectid})) {
            push @{$merged->{$objectid}->{$key}}, $item;
        } else {
            $merged->{$objectid} = {
                $key => [$item]
            };
        }
    });
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/tms_import.%s.sqlite', $out_name),
    );
    while (my ($object_id, $data) = each %{$merged}) {
        $store->bag->add({
            '_id' => $object_id,
            $key => $data->{$key}
        });
    }
}

sub __constituents {
    my $self = shift;
    $self->prepare_call('SELECT * FROM vconstituents', 'constituents');
}

sub __classifications {
    my $self = shift;
    $self->prepare_call('SELECT * FROM vclassifications', 'classifications');
}

sub __period {
    my $self = shift;
    $self->prepare_call('SELECT * FROM vperiods', 'periods');
}

sub __datapids {
    my $self = shift;
    $self->prepare_call('SELECT * FROM vdatapids', 'datapids');
}

sub __workpids {
    my $self = shift;
    $self->prepare_call('SELECT * FROM vworkpids', 'workpids');
}

sub __representationpids {
    my $self = shift;
    $self->prepare_call('SELECT * FROM vperiods', 'representationpids');
}

sub __dimensions {
    my $self = shift;
    $self->merge_call('SELECT * FROM vdimensions', 'dimensions', 'dimensions');
}

sub __subjects {
    my $self = shift;
    $self->merge_call('SELECT * FROM vsubjects', 'subjects', 'subjects');
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::KMSKA - Import data from the L<TMS|http://www.gallerysystems.com/products-and-services/tms/> instance of the L<KMSKA|http://kmska.be/nl/>

=head1 SYNOPSIS

    use Datahub::Factory::Importer::KMSKA;
    use Data::Dumper qw(Dumper);

    my $kmska = Datahub::Factory::Importer::KMSKA->new(
        db_host     => 'localhost',
        db_name     => 'kmska',
        db_user     => 'kmska',
        db_password => 'kmska'
    );

    $kmska->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::KMSKA uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from a local instance of L<TMS|http://www.gallerysystems.com/products-and-services/tms/> as it is configured in
the L<KMSKA|http://kmska.be/nl/>. This module does not give you access to the database of the museum, but
allows you to pull and parse data from it if you already have access. For a more generic interface to TMS,
see L<Datahub::Factory::Importer::TMS>. Both modules require however that the TMS database is stored in a MySQL
(or equivalent) system. It will not work with MS SQL (which TMS uses).

=head1 PARAMETERS

=over

=item C<db_host>

Host (IP or FQDN) of the MySQL database.

=item C<db_name>

Name of the MySQL database.

=item C<db_user>

Username to connect to the database.

=item C<db_password>

Password for the user.

=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Datahub::Factory>
L<Datahub::Factory::Importer::TMS>
L<Catmandu>

=cut
