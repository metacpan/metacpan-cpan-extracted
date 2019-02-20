package Catmandu::Importer::MARC;
use Catmandu::Sane;
use Catmandu::Util;
use Moo;

our $VERSION = '1.241';

has type           => (is => 'ro' , default => sub { 'ISO' });
has skip_errors    => (is => 'ro');
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
    my  ($self) = @_;

    if ($self->skip_errors) {
      my $gen = $self->_importer->generator;
      my $nr  = 0;
      sub {
        my $item = 0;
        do {
          $nr++;
          try {
            $item = $gen->();
          } catch {
            $self->log->error("error at record $nr : $_");
          };
        } while (defined($item) && $item == 0);
        $item;
      };
    }
    else {
      $self->_importer->generator;
    }
}

1;
__END__

=head1 NAME

Catmandu::Importer::MARC - Package that imports MARC data

=head1 SYNOPSIS

    # On the command line

    # Convert MARC to JSON (default)
    $ catmandu convert MARC < /foo/bar.mrc

    # Convert MARC to MARC
    $ catmandu convert MARC to MARC < /foo/bar.mrc > /foo/output.mrc

    # Add fixes
    $ catmandu convert MARC to MARC --fix myfixes.txt < /foo/bar.mrc > /foo/output.mrc

    # Create a list of titles
    $ catmandu convert MARC to TSV --fix "marc_map(245,title); retain(title)" < /foo/bar.mrc

    # Convert MARC XML
    $ catmandu convert MARC --type XML < /foo/bar.xml

    # Convert ALEPH sequential
    $ catmandu convert MARC --type ALEPHSEQ < /foo/bar.aleph

    # Convert on format to another format
    $ catmandu convert MARC --type ISO to MARC --type ALEPHSEQ < /foo/bar.mrc > /foo/bar.aleph

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

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item type

The MARC format to parse. The following MARC parsers are available:

  ISO: L<Catmandu::Importer::MARC::ISO> (default) - a strict ISO 2709 parser
  RAW: L<Catmandu::Importer::MARC::RAW> - a loose ISO 2709 parser that skips faulty records
  ALEPHSEQ: L<Catmandu::Importer::MARC::ALEPHSEQ> - a parser for Ex Libris Aleph sequential files
  Lint: L<Catmandu::Importer::MARC::Lint> - a MARC syntax checker
  MicroLIF: L<Catmandu::Importer::MARC::MicroLIF> - a parser for the MicroLIF format
  MARCMaker: L<Catmandu::Importer::MARC::MARCMaker> - a parser for MARCMaker/MARCBreaker records
  MiJ: L<Catmandu::Importer::MARC::MiJ> (MARC in JSON) - a parser for the MARC-in-JSON format
  XML: L<Catmandu::Importer::MARC::XML> - a parser for the MARC XML format

=item skip_errors

If set, then any errors when parsing MARC input will be skipped and ignored. Use the
debug setting of catmandu to view all error messages:

  $ catmandu -D convert MARC --skip_errors 1 < /foo/bar.mrc

=item <other>

Every MARC importer can have its own options. Check the documentation of the specific importer.

=back

=head1 SEE ALSO

L<Catmandu::Exporter::MARC>
