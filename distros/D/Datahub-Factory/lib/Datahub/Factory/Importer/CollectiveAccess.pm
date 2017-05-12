package Datahub::Factory::Importer::CollectiveAccess;

use strict;
use warnings;

use Moo;
use Catmandu;

with 'Datahub::Factory::Importer';

has endpoint   => (is => 'ro', required => 1);
has username   => (is => 'ro', required => 1);
has password   => (is => 'ro', required => 1);
has field_list => (is => 'ro', default => sub {
    return [
		'ca_objects.object_id',
		'ca_objects.preferred_labels',
		'ca_objects.description',
		'ca_objects.subtitle',
		'ca_objects.geonames',
		'ca_objects.lcsh_terms',
		'ca_objects.colour',
		'ca_objects.contentActivity',
		'ca_objects.contentConcept',
		'ca_objects.contentDescription',
		'ca_objects.dimensions.dimensions_width',
		'ca_objects.dimensions.dimensions_height',
		'ca_objects.dimensions.dimensions_depth',
		'ca_objects.dimensions.circumference',
		'ca_objects.dimensions.dimensions_type',
		'ca_objects.materialInfo.materialInfostyle',
		'ca_objects.objectProductionDate',
		'ca_objects.techniqueInfo.techniqueInfodatePeriod',
		'ca_objects.dateText',
		'ca_objects.objectName.objectObjectName',
		'ca_objects.objectWorkPid.objectWorkPidDomain',
		'ca_objects.objectWorkPid.objectWorkPidID',
		'ca_objects.objectRecordPid.objectRecordPidDomain',
		'ca_objects.objectRecordPid.objectRecordPidID',
		'ca_entities.entity_id',
		'ca_entities.relationship_type_code'
    ];
});

sub _build_importer {
    my $self = shift;
    my $ca = Catmandu->store('CA',
        username   => $self->username,
        password   => $self->password,
        url        => $self->endpoint,
        field_list => $self->field_list
    );
    return $ca->bag;
}

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::CollectiveAccess - Import data from a L<CollectiveAccess|http://collectiveaccess.org/> instance

=head1 SYNOPSIS

    use Datahub::Factory::Importer::CollectiveAccess;
    use Data::Dumper qw(Dumper);

    my $ca = Datahub::Factory::Importer::CollectiveAccess->new(
    );

    $ca->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::CollectiveAccess uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from a  L<CollectiveAccess|http://collectiveaccess.org/> instance. It returns an L<Importer|Catmandu::Importer>.

=head1 PARAMETERS

=over


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
L<Catmandu>

=cut