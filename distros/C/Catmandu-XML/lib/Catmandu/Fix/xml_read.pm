package Catmandu::Fix::xml_read;

our $VERSION = '0.16';

use Catmandu::Sane;
use Moo;
use XML::Struct::Reader;
use XML::LibXML::Reader;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has field      => (fix_arg => 1);
has attributes => (fix_opt => 1); 
has ns         => (fix_opt => 1);
has content    => (fix_opt => 1);
has simple     => (fix_opt => 1);
has root       => (fix_opt => 1);
has depth      => (fix_opt => 1);
has path       => (fix_opt => 1);
has whitespace => (fix_opt => 1);

has _reader => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        XML::Struct::Reader->new(
            map { $_ => $_[0]->$_ } grep { defined $_[0]->$_ }
            qw(attributes ns simple root depth content whitespace)
        );
    }
);

sub emit {    
    my ($self,$fixer) = @_;    

    my $path = $fixer->split_path($self->field);
    my $key = pop @$path;
    
    my $reader = $fixer->capture($self->_reader); 
    my $xpath  = $fixer->capture($self->path);

    return $fixer->emit_walk_path($fixer->var,$path,sub{
        my $var = $_[0];     
        $fixer->emit_get_key($var,$key,sub{
            my $var = $_[0];
            return "my \$stream = XML::LibXML::Reader->new( string => ${var} );".
                "${var} = ${xpath} ? [ ${reader}->readDocument(\$stream, ${xpath}) ] " .
                ": ${reader}->readDocument(\$stream);";
        });
    });
}

1;
__END__

=head1 NAME

Catmandu::Fix::xml_read - parse XML to MicroXML

=head1 SYNOPSIS
     
  # parse XML string given in field 'xml' 
  xml_read(xml)
  xml_read(xml, simple: 1)
  xml_read(xml, attributes: 0)

=head1 DESCRIPTION

This L<Catmandu::Fix> parses XML strings into MicroXML or simple XML with
L<XML::Struct>.

=head1 CONFIGURATION

Parsing can be configured with the following options of L<XML::Struct::Reader>:

=over

=item attributes

Include XML attributes (enabled by default)

=item ns

Define processing of XML namespaces (C<keep> by default)

=item whitespace

Include ignorable whitespace as text elements (disabled by default)

=item simple

Convert to simple key-value structure, as known from L<XML::Simple>

=item root

Keep (and possibly rename) root element when converting to C<simple> form

=item depth

Only transform to a given depth with option C<simple>

=item path

Parse only given elements (and all of its child elements) and return as array.
For instance C<< path => "p" >> in an XHTML document would return a list of
parsed paragraphs (C<< <p>...</p> >>). This option overrides option C<root>.

=item content

Name of text content when converting to C<simple> form 

=back

=head1 SEE ALSO

L<Catmandu::Fix::xml_write>,
L<Catmandu::Fix::xml_simple>
L<Catmandu::Fix::xml_transform>

=cut
