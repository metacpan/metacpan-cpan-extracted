=head1 NAME

Catmandu::Exporter::MARC::MiJ - Exporter for MARC records to MARC in JSON

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type XML to MARC --type MiJ < /foo/bar.xml

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.xml" , type => 'XML');
    my $exporter = Catmandu->exporter('MARC', file => "bar.json", type => 'MiJ' );

    $exporter->add($importer);
    $exporter->commit;

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

=item encoding

Binmode of the output stream C<fh>. Set to "C<:utf8>" by default.

=back

=head1 METHODS

See L<Catmandu::Exporter>, L<Catmandu::Addable>, L<Catmandu::Fixable>,
L<Catmandu::Counter>, and L<Catmandu::Logger> for a full list of methods.

=head1 FORMAT

The MARC-in-JSON record format contains two fields:

   * 'leader' - the MARC leader
   * 'fields' - an array of MARC fields

Each item in the MARC fields array contains the MARC tag and as value a hash
containing three fields:

   * 'subfields' - an array of MARC subfields
   * 'ind1' - the first indicator of the MARC tag
   * 'ind2' - the second indicator of the MARC tag

Each subfield item is an hash containing the MARC subfield tag and its value.

An example of one MARC record in the MiJ serialization format is given below:

    {
      "leader": "0000cam  2200000   4500",
      "fields": [
        {
          "100": {
            "subfields": [
              {
                "a": "Huberman, Leo,"
              },
              {
                "d": "1903-1968."
              }
            ],
            "ind1": "1",
            "ind2": " "
          }
        },
        {
          "700": {
            "subfields": [
              {
                "a": "Sweezy, Paul M."
              },
              {
                "q": "(Paul Marlor),"
              },
              {
                "d": "1910-2004."
              }
            ],
            "ind1": "1",
            "ind2": " "
          }
        },
        ...
    }

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
package Catmandu::Exporter::MARC::MiJ;
use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different :array :is);
use Moo;
use MARC::Record;
use MARC::Field;
use MARC::File::MiJ;

our $VERSION = '1.251';

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base';

has record               => (is => 'ro' , default => sub { 'record'});
has record_format        => (is => 'ro' , default => sub { 'raw'} );

sub add {
	my ($self, $data) = @_;

    if ($self->record_format eq 'MARC-in-JSON') {
        $data = $self->_json_to_raw($data);
    }

	my $marc = $self->_raw_to_marc_record($data->{$self->record});

	$self->fh->print(MARC::File::MiJ::encode($marc) . "\n");
}

sub commit {
	my ($self) = @_;
	$self->fh->flush;

    1;
}

1;
