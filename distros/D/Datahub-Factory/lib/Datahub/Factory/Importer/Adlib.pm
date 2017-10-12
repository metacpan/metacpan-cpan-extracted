package Datahub::Factory::Importer::Adlib;

use Datahub::Factory::Sane;

our $VERSION = '1.72';

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Importer';

has file_name => (is => 'ro', required => 1);
has data_path => (is => 'ro', default => sub { return 'recordList.record.*'; });

sub _build_importer {
    my $self = shift;
    my $importer = Catmandu->importer('XML', file => $self->file_name, data_path => $self->data_path);
    return $importer;
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::Adlib - Import data from L<Adlib|http://www.adlibsoft.nl/> data dumps

=head1 SYNOPSIS

    use Datahub::Factory;
    use Data::Dumper qw(Dumper);

    my $adlib = Datahub::Factory->importer('Adlib')->new(
        file_name => '/tmp/export.xml',
        data_path => 'recordList.record.*'
    );

    $adlib->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::Adlib uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records
from an AdlibXML data dump. It returns an L<Importer|Catmandu::Importer>.

=head1 PARAMETERS

=over

=item C<file_name>

Location of the Adlib XML data dump. It expects AdlibXML.

=item C<data_path>

Optional parameter that indicates where the records are in the XML tree. It uses L<Catmandu::Fix|https://github.com/LibreCat/Catmandu/wiki/Fixes-Cheat-Sheet> syntax.
By default, records are in the C<recordList.record.*> path.

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
