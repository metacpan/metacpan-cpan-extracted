=head1 NAME

Catmandu::Exporter::MARC::ISO - Exporter for MARC records to ISO

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type ISO to MARC --type XML < /foo/bar.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'ISO');
    my $exporter = Catmandu->exporter('MARC', file => "/foo/bar.xml", type => 'XML' );

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

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
package Catmandu::Exporter::MARC::ISO;
use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different :array :is);
use Moo;
use MARC::Record;
use MARC::Field;
use MARC::File::USMARC;

our $VERSION = '1.11';

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base';

has record               => (is => 'ro' , default => sub { 'record'});
has record_format        => (is => 'ro' , default => sub { 'raw'} );

sub add {
	my ($self, $data) = @_;

    if ($self->record_format eq 'MARC-in-JSON') {
        $data = $self->_json_to_raw($data);
    }

	my $marc = $self->_raw_to_marc_record($data->{$self->record});

	$self->fh->print(MARC::File::USMARC::encode($marc));
}

sub commit {
	my ($self) = @_;
	$self->fh->flush;
}

1;
