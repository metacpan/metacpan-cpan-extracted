package Datahub::Factory::Importer::JSON;

use Datahub::Factory::Sane;

our $VERSION = '1.74';

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Importer';

has file_name => (is => 'ro', required => 1);

sub _build_importer {
    my $self = shift;

    my $importer = Catmandu->importer('JSON', file => $self->file_name);

    return $importer;
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::JSON - Import data from JSON flat file data dumps

=head1 SYNOPSIS

    use Datahub::Factory;
    use Data::Dumper qw(Dumper);

    my $json = Datahub::Factory->importer('JSON')->new(
        file_name => '/tmp/export.json',
    );

    $json->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::JSON uses L<Catmandu|http://librecat.org/Catmandu/> to fetch a list of records from an JSON flat file data dump. It returns an L<Importer|Catmandu::Importer>.

=head1 PARAMETERS

=over

=item C<file_name>

Location of the JSON flat file data dump.

=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHOR

Matthias Vandermaesen E<lt>matthias dot vandermaesen at vlaamsekunstcollectie.be E<gt>

=head1 COPYRIGHT

Copyright 2017- Vlaamsekunscollectie vzw, PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Datahub::Factory>
L<Catmandu>

=cut
