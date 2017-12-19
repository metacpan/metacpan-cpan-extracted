package Catmandu::Fix::marc_xml;

use Catmandu::Sane;
use Moo;
use Catmandu::MARC;
use Catmandu::Fix::Has;
use Clone qw(clone);

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.231';

has path  => (fix_arg => 1);

# Transform a raw MARC array into MARCXML
sub fix {
    my ($self, $data) = @_;
    my $path = $self->{path};

    return $data unless exists $data->{$path};

    if ($path eq 'record') {
        my $xml = Catmandu::MARC->instance->marc_xml($data);
        $data->{$path} = $xml;
    }
    elsif (exists $data->{record}) {
        my $copy           = clone($data->{record});
        $data->{record}    = $data->{$path};
        my $xml = Catmandu::MARC->instance->marc_xml($data);
        $data->{$path}     = $xml;
        $data->{record}    = $copy;
    }
    else {
        $data->{record}    = $data->{$path};
        my $xml = Catmandu::MARC->instance->marc_xml($data);
        $data->{$path}     = $xml;
        delete $data->{record};
    }

    $data;
}

=head1 NAME

Catmandu::Fix::marc_xml - transform a Catmandu MARC record into MARCXML

=head1 SYNOPSIS

   # Transforms the 'record' key into a MARCXML string
   marc_xml('record')

=head1 DESCRIPTION

Convert MARC data into a MARCXML string

=head1 METHODS

=head2 marc_xml(PATH)

Transform the MARC record found at PATH to MARC XML.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_xml as => 'marc_xml';

    my $data = { record => [...] };

    $data = marc_xml($data);

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
