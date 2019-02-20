package Catmandu::Fix::marc_in_json;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.241';

has reverse => (fix_opt => 1);

# Transform a raw MARC array into MARC-in-JSON
# See Ross Singer work at:
#  http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
sub fix {
    my ($self, $data) = @_;

    if ($self->reverse) {
        return Catmandu::MARC->instance->marc_json_to_record($data);
    }
    else {
        return Catmandu::MARC->instance->marc_record_to_json($data);
    }
}

=head1 NAME

Catmandu::Fix::marc_in_json - transform a Catmandu MARC record into MARC-in-JSON

=head1 SYNOPSIS

   # Transform a Catmandu MARC 'record' into a MARC-in-JSON record
   marc_in_json()

   # Reverse, transform a MARC-in-JSON record into a Catmandu MARC record
   marc_in_json(reverse:1)

=head1 DESCRIPTION

Convert the MARC record into MARC-in-JSON format

=head1 METHODS

=head2 marc_in_json( [OPT1:VAL, OPT2: VAL])

Convert a Catmandu MARC record into the MARC-in-JSON format.

=head1 OPTIONS

=head2 reverse: 0|1

Convert a MARC-in-JSON record back into the Catmandu MARC format.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_in_json as => 'marc_in_json';

    my $data = { record => [...] };

    $data = marc_in_json($data);

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
