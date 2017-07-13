package Catmandu::Exporter::MARC;
use Catmandu::Sane;
use Catmandu::Util;
use Moo;

our $VERSION = '1.171';

has type           => (is => 'ro' , default => sub { 'ISO' });
has _exporter      => (is => 'ro');

with 'Catmandu::Exporter';

sub BUILD {
    my ($self,$args) = @_;

    my $type = $self->type;

    # keep USMARC temporary as alias for ISO, remove in future version
    # print deprecation warning
    if ($type eq 'USMARC') {
        $type = 'ISO';
        warn( "deprecated", "Oops! Exporter \"USMARC\" is deprecated. Use \"ISO\" instead." );
    }

    my $pkg = Catmandu::Util::require_package($type,'Catmandu::Exporter::MARC');

    delete $args->{file};
    delete $args->{fix};

    $self->{_exporter} = $pkg->new(file => $self->file, %$args);
}

sub add {
    $_[0]->_exporter->add($_[1]);
}

sub commit {
    $_[0]->_exporter->commit;
}

1;

__END__

=head1 NAME

Catmandu::Exporter::MARC - Exporter for MARC records

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type ISO to MARC --type XML < /foo/bar.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'ISO');
    my $exporter = Catmandu->exporter('MARC', file => "marc.xml", type => "XML" );

    $exporter->add($importer);
    $exporter->commit;

=head1 DESCRIPTION

Catmandu::Exporter::MARC is a L<Catmandu::Exporter> to serialize (write) MARC records
to a file or the standard output.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Exporter> (C<file>,
C<fh>, etc.) the exporter can be configured with the following parameters:

The 'type' parameter describes the MARC syntax variant. Supported values include:

=over

=item

ISO: L<Catmandu::Exporter::MARC::ISO> (default)

=item

XML: L<Catmandu::Exporter::MARC::XML>

=item

MARCMaker: L<Catmandu::Exporter::MARC::MARCMaker>

=item

MiJ: L<Catmandu::Exporter::MARC::MiJ> (MARC in JSON)

=item

ALEPHSEQ: L<Catmandu::Exporter::MARC::ALEPHSEQ>

=back

    E.g.

    catmandu convert MARC --type XML to MARC --type ISO < marc.xml > marc.iso

=head1 SEE ALSO

L<Catmandu::Importer::MARC>
