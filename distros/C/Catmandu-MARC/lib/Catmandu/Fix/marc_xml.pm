package Catmandu::Fix::marc_xml;

use Catmandu::Sane;

our $VERSION = '1.271';

use Moo;
use namespace::clean;
use Catmandu::MARC;
use Catmandu::Fix::Has;

has path      => (fix_arg => 1);
has reverse   => (fix_opt => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    if ($self->reverse) {
        "if (is_string(${var})) {" .
           "${var} = Catmandu::MARC->instance->marc_xml(${var}, reverse => 1);" .
        "}";
    }
    else {
        "if (is_array_ref(${var})) {" .
           "${var} = Catmandu::MARC->instance->marc_xml(${var});" .
        "}";
    }
}

=head1 NAME

Catmandu::Fix::marc_xml - transform a Catmandu MARC record into MARCXML

=head1 SYNOPSIS

   # Transforms the 'record' key into a MARCXML string
   marc_xml('record')

   # Transforms the XML in the 'record' key into MARC accessible data
   marc_xml('record',reverse:1)

=head1 DESCRIPTION

Convert MARC data into a MARCXML string

=head1 METHODS

=head2 marc_xml(PATH,[reverse:1])

Transform the MARC record found at PATH to MARC XML. If an
C<reverse> option is given, then XML found at C<PATH> will be transformed
into an internal MARC format. The MARC representation needs to be
stored in the C<record> key to be used with other L<Catmandu::MARC> fixes.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_xml as => 'marc_xml';

    my $data = { record => [...] };

    $data = marc_xml($data);

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
