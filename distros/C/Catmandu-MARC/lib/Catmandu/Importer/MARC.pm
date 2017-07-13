package Catmandu::Importer::MARC;
use Catmandu::Sane;
use Catmandu::Util;
use Moo;

our $VERSION = '1.171';

has type           => (is => 'ro' , default => sub { 'ISO' });
has _importer      => (is => 'ro');

with 'Catmandu::Importer';

sub BUILD {
    my ($self,$args) = @_;

    my $type = $self->type;

    # keep USMARC temporary as alias for ISO, remove in future version
    # print deprecation warning
    if ($type eq 'USMARC') {
        $type = 'ISO';
        warn( "deprecated", "Oops! Importer \"USMARC\" is deprecated. Use \"ISO\" instead." );
    }

    if (exists $args->{records}) {
        $type = 'Record';
    }

    my $pkg = Catmandu::Util::require_package($type,'Catmandu::Importer::MARC');

    delete $args->{file};
    delete $args->{type};
    delete $args->{fix};

    $self->{_importer} = $pkg->new(file => $self->file, %$args);
}

sub generator {
    $_[0]->_importer->generator;
}

1;
__END__

=head1 NAME

Catmandu::Importer::MARC - Package that imports MARC data

=head1 SYNOPSIS

    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/bar.mrc');

    my $count = $importer->each(sub {
        my $record = shift;
        # ...
    });

    # import records and apply a fixer
    my $fixer = fixer("marc_map('245a','title')");

    $fixer->fix($importer)->each(sub {
        my $record = shift;
        printf "title: %s\n" , $record->{title};
    });

    # Convert MARC to JSON mapping 245a to a title with the L<catmandu> command line client:

    catmandu convert MARC --fix "marc_map('245a','title')" < /foo/bar.mrc

=head1 DESCRIPTION

Catmandu::Importer::MARC is a L<Catmandu::Importer> to import MARC records from an
external source. Each record is imported as HASH containing two keys:

=over

=item C<_id>

the system identifier of the record (usually the 001 field)

=item C<record>

an ARRAY of ARRAYs containing the record data

=back

=head1 EXAMPLE ITEM

 {
    record => [
      [
        '001',
        undef,
        undef,
        '_',
        'fol05882032 '
      ],
      [
        '245',
        '1',
        '0',
        'a',
        'Cross-platform Perl /',
        'c',
        'Eric F. Johnson.'
      ],
    ],
    _id' => 'fol05882032'
 }

=head1 METHODS

This module inherits all methods of L<Catmandu::Importer> and by this
L<Catmandu::Iterable>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Importer> (C<file>,
C<fh>, etc.) the importer can be configured with the following parameters:


The 'type' parameter describes the MARC syntax variant. Supported values include:

=over

=item

ISO: L<Catmandu::Importer::MARC::ISO> (default)

=item

MicroLIF: L<Catmandu::Importer::MARC::MicroLIF>

=item

MARCMaker: L<Catmandu::Importer::MARC::MARCMaker>

=item

MiJ: L<Catmandu::Importer::MARC::MiJ> (MARC in JSON)

=item

XML: L<Catmandu::Importer::MARC::XML>

=item

RAW: L<Catmandu::Importer::MARC::RAW>

=item

Lint: L<Catmandu::Importer::MARC::Lint>

=item

ALEPHSEQ: L<Catmandu::Importer::MARC::ALEPHSEQ>

=back

    E.g.

    catmandu convert MARC --type XML to MARC --type ISO < marc.xml > marc.iso

=head1 SEE ALSO

L<Catmandu::Exporter::MARC>
