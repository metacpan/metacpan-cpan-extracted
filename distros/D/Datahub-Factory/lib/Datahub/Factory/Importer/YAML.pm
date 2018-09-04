package Datahub::Factory::Importer::YAML;

use Datahub::Factory::Sane;

our $VERSION = '1.74';

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Importer';

has file_name => (is => 'ro', required => 1);

sub _build_importer {
    my $self = shift;

    my $importer = Catmandu->importer('YAML', file => $self->file_name);

    return $importer;
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::YAML - Import data from YAML data dumps

=head1 SYNOPSIS

    use Datahub::Factory;
    use Data::Dumper qw(Dumper);

    my $yaml = Datahub::Factory->importer('YAML')->new(
        file_name => '/tmp/export.yaml',
    );

    $yaml->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::YAML uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records from an YAML data dump. It returns an L<Importer|Catmandu::Importer>.

=head1 PARAMETERS

=over

=item C<file_name>

Location of the YAML data dump.

=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHOR

Tine Robbe E<lt>tine dot robbe at vlaamsekunstcollectie.be E<gt>

=head1 COPYRIGHT

Copyright 2017- Vlaamsekunscollectie vzw, PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Datahub::Factory>
L<Catmandu>

=cut