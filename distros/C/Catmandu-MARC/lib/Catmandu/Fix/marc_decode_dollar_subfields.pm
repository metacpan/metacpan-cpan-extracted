package Catmandu::Fix::marc_decode_dollar_subfields;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.254';

sub fix {
	my ($self,$data) = @_;
    return Catmandu::MARC->instance->marc_decode_dollar_subfields($data);
}

=head1 NAME

Catmandu::Fix::marc_decode_dollar_subfields - decode double encoded dollar subfields

=head1 SYNOPSIS

    marc_decode_dollar_subfields()

=head1 DESCRIPTION

In some environments MARC subfields can contain data values that can be interpreted
as subfields itself. E.g. when the 245-$a subfield contains the data:

   My Title $h subsubfield

then the $h = subsubfield will not be accessible with normal MARC processing tools.
Use the 'marc_decode_dollar_subfields()' fix to re-evaluate all the MARC subfields
for these hidden data.

=head1 METHODS

=head2 marc_decode_dollar_subfields()

Decode double encoded dollar subfields into real MARC subfields.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_decode_dollar_subfields as => 'marc_decode_dollar_subfields';

    my $data = { record => [...] };

    $data = marc_decode_dollar_subfields($data);

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
