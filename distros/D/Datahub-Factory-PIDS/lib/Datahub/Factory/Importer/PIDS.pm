package Datahub::Factory::Importer::PIDS;

our $VERSION = '0.0.1';

use strict;
use warnings;

use Moo;
use Catmandu;

use WebService::Rackspace::CloudFiles;
use File::Basename qw(fileparse);

has username       => (is => 'ro', required => 1);
has api_key        => (is => 'ro', required => 1);
has container_name => (is => 'ro', default => 'datahub');

has client    => (is => 'lazy');
has container => (is => 'lazy');

sub _build_client {
    my $self = shift;
    return WebService::Rackspace::CloudFiles->new(
        user => $self->username,
        key  => $self->api_key
    );
}

sub _build_container {
    my $self = shift;
    return $self->client->container(name => $self->container_name);
}

sub get_object {
    my ($self, $object_name) = @_;
    my $object = $self->container->object(name => $object_name);
    my $file_name = $object_name;
    $file_name =~ s/[^A-Za-z0-9\-\.]/./g;
    $object->get_filename(sprintf('/tmp/%s', $file_name));
    return sprintf('/tmp/%s', $file_name);
}

sub temporary_table {
    my ($self, $csv_location, $id_column) = @_;
    my $store_table = fileparse($csv_location, '.csv');

    my $importer = Catmandu->importer(
        'CSV',
        file => $csv_location
    );
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/import.%s.sqlite', $store_table),
    );
    $importer->each(sub {
            my $item = shift;
            if (defined ($id_column)) {
                $item->{'_id'} = $item->{$id_column};
            }
            my $bag = $store->bag();
            # first $bag->get($item->{'_id'})
            $bag->add($item);
        });
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::PIDS - Insert PIDS from an external source

=head1 SYNOPSIS

    use Datahub::Factory::Importer::PIDS;
    use Data::Dumper qw(Dumper);

    my $pids = Datahub::Factory::Importer::PIDS->new(
        username       => 'datahub',
        api_key        => 'datahub',
        container_name => 'datahub'
    );

    $pids->temporary_table($pids->get_object('test.csv'), 'id');

=head1 DESCRIPTION

The module uses L<Catmandu> to create a SQLite database from a CSV containing an export
of the L<Resolver|https://github.com/PACKED-vzw/resolver> that can be used in Catmandu fixes
to insert PIDS (Persistent Identifiers).

The CSV's are stored on a protected Rackspace cloud files instance.

It has absolutely no use outside of the L<Datahub|https://github.com/thedatahub/> use case.

=head1 PARAMETERS

=over

=item C<username>

Rackspace Cloud Files username to access the files.

=item C<api_key>

API key for the Cloud Files user.

=item C<container_name>

Name of the container where the files are stored. Optional, defaults to I<datahub>.

=back

=head1 METHODS

=over

=item C<get_object($filename)>

Get the object called C<$filename> from the Cloud files instance and store it in C</tmp>.
Only accepts CSV's.

Returns the local path of the object it just fetched.

=item C<temporary_table($csv_location, $id_column)>

Create a SQLite database (in C</tmp>) that stores the CSV that is stored in C<$csv_location>.
Create an C<_id> column (as expected by L<Catmandu::Fix::lookup_in_store>) in the database
from the column in the CSV called C<$id_column>.

Returns nothing.

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
L<Catmandu>

=cut