package Catmandu::Exporter::MARC::XML;
use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different :array :is);
use Moo;

our $VERSION = '1.16';

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base', 'Catmandu::Buffer';

has record               => (is => 'ro' , default => sub { 'record'});
has record_format        => (is => 'ro' , default => sub { 'raw'} );
has skip_empty_subfields => (is => 'ro' , default => sub { 1 });
has collection           => (is => 'ro' , default => sub { 1 });
has xml_declaration      => (is => 'ro' , default => sub { 1 });
has pretty               => (is => 'rw' , default => sub { 0 });
has _n                   => (is => 'rw' , default => sub { 0 });

sub _line {
    my ($self, $indent, $line) = @_;
    if ($self->pretty) {
        my $pre = "   " x $indent;
        $self->buffer_add( $pre.$line."\n" );
    } else {
        $self->buffer_add( $line );
    }
}

sub add {
    my ($self, $data) = @_;

 	if ($self->_n == 0) {
    	if ($self->xml_declaration) {
            $self->buffer_add( Catmandu::Util::xml_declaration );
    	}

    	if ($self->collection) {
            $self->_line(0,'<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">');
    	}

    	$self->_n(1);
    }

    my $indent = $self->collection ? 1 : 0;

    if ($self->record_format eq 'MARC-in-JSON') {
        $data = $self->_json_to_raw($data);
    }

    if ($self->collection) {
        $self->_line($indent,'<marc:record>');
    }
    else {
        $self->_line($indent,'<marc:record xmlns:marc="http://www.loc.gov/MARC21/slim">');
    }

    my $record = $data->{$self->record};

    for my $field (@$record) {
        my ($tag, $ind1, $ind2, @data) = @$field;

        $ind1 = ' ' unless defined $ind1;
        $ind2 = ' ' unless defined $ind2;

        @data = $self->_clean_raw_data($tag,@data) if $self->skip_empty_subfields;

        next if $tag eq 'FMT';
        next if @data == 0;

        if ($tag eq 'LDR') {
            $self->_line($indent+1,'<marc:leader>' . xml_escape($data[1]) . '</marc:leader>');
        }
        elsif ($tag =~ /^00/) {
            $self->_line($indent+1,'<marc:controlfield tag="' . xml_escape($tag) . '">' . xml_escape($data[1]) . '</marc:controlfield>');
        }
        else {
            $self->_line($indent+1,'<marc:datafield tag="' . xml_escape($tag) . '" ind1="' . $ind1 . '" ind2="' . $ind2 . '">');
            while (@data) {
                my ($code, $val) = splice(@data, 0, 2);
                next unless $code =~ /[A-Za-z0-9]/;
                $self->_line($indent+2,'<marc:subfield code="' . $code . '">' . xml_escape($val) . '</marc:subfield>');
            }
            $self->_line($indent+1,'</marc:datafield>');
        }
    }

    $self->_line($indent,'</marc:record>');

    $self->fh->print( join('', @{ $self->buffer } ) );
    $self->clear_buffer;
}

sub commit {
    my ($self) = @_;

    if($self->collection){
        $self->fh->print('</marc:collection>');
    }

    $self->fh->flush;
}

1;
__END__

=head1 NAME

Catmandu::Exporter::MARC::XML - Exporter for MARC records to MARCXML

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC to MARC --type XML < /foo/data.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'ISO');
    my $exporter = Catmandu->exporter('MARC', file => "marc.xml", type => 'XML' );

    $exporter->add($importer);
    $exporter->commit;

=head1 DESCRIPTION

This L<Catmandu::Exporter::MARC> serializes MARC records as XML.

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path or file handle. Alternatively a
scalar reference can be passed to write to a string and a code reference can be
used to write to a callback function.

=item fh

Write the output to an L<IO::Handle>. If not specified,
L<Catmandu::Util::io|Catmandu::Util/IO-functions> is used to create the output
handle from the C<file> argument or by using STDOUT.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to exported items.

=item record

the key containing the marc record (default: 'record')

=item record_format

Optionally set to 'MARC-in-JSON' when the input format is in MARC-in-JSON

=item collection

add a marc:collection header when true (default: true)

=item xml_declaration

add a xml declaration when true (default: true)

=item skip_empty_subfields

skip fields which don't contain any data (default: false)

=item pretty

pretty-print XML

=back

=head1 METHODS

See L<Catmandu::Exporter>, L<Catmandu::Addable>, L<Catmandu::Fixable>,
L<Catmandu::Counter>, and L<Catmandu::Logger> for a full list of methods.

=head1 SEE ALSO

L<Catmandu::Importer::MARC::XML>

=cut

