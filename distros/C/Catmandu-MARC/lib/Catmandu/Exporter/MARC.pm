package Catmandu::Exporter::MARC;
use Catmandu::Sane;
use Catmandu::Util;
use Moo;

our $VERSION = '1.241';

has type           => (is => 'ro' , default => sub { 'ISO' });
has skip_errors    => (is => 'ro');
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
  my ($self) = @_;

  if ($self->skip_errors) {
    eval {
      $self->_exporter->add($_[1]);
    };

    if ($@) {
      $self->log->error("error at record " . $self->count . " : $@");
    }
  }
  else {
    $self->_exporter->add($_[1]);
  }
}

sub commit {
    $_[0]->_exporter->commit;
}

1;

__END__

=head1 NAME

Catmandu::Exporter::MARC - Exporter for MARC records

=head1 SYNOPSIS

  # Convert MARC to MARC
  $ catmandu convert MARC to MARC < /foo/bar.mrc > /foo/output.mrc

  # Add fixes
  $ catmandu convert MARC to MARC --fix myfixes.txt < /foo/bar.mrc > /foo/output.mrc

  # Convert on format to another format
  $ catmandu convert MARC --type ISO to MARC --type ALEPHSEQ < /foo/bar.mrc > /foo/bar.aleph

=head1 DESCRIPTION

Catmandu::Exporter::MARC is a L<Catmandu::Exporter> to serialize (write) MARC records
to a file or the standard output.

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path or file handle.  Alternatively a
scalar reference can be passed to write to a string and a code reference can be
used to write to a callback function.

=item fh

Write the output to an L<IO::Handle>. If not specified,
L<Catmandu::Util::io|Catmandu::Util/IO-functions> is used to create the output
handle from the C<file> argument or by using STDOUT.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to exported items.

=item type

The MARC format to parse. The following MARC parsers are available:

  ISO: L<Catmandu::Importer::MARC::ISO> (default) - a strict ISO 2709 exporter
  ALEPHSEQ: L<Catmandu::Importer::MARC::ALEPHSEQ> - an exporter for Ex Libris Aleph sequential files
  MARCMaker: L<Catmandu::Importer::MARC::MARCMaker> - an exporter for MARCMaker/MARCBreaker records
  MiJ: L<Catmandu::Importer::MARC::MiJ> (MARC in JSON) - an export for the MARC-in-JSON format
  XML: L<Catmandu::Importer::MARC::XML> - an exporter for the MARC XML format

=item skip_errors

If set, then any errors when parsing MARC output will be skipped and ignored. Use the
debug setting of catmandu to view all error messages:

  $ catmandu -D convert MARC to MARC --skip_errors 1 --fix myfixes.txt < /foo/bar.mrc

=item <other>

Every MARC importer can have its own options. Check the documentation of the specific importer.

=back

=head1 SEE ALSO

L<Catmandu::Importer::MARC>
