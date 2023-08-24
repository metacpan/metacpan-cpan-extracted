package Catmandu::Fix::pica_append;

use Catmandu::Sane;

our $VERSION = '1.17';

use Moo;
use Catmandu::Fix::Has;
use PICA::Path;
use Scalar::Util 'reftype';
use PICA::Data 'pica_parser';

with 'Catmandu::Fix::Inlineable';

has fields => (
    fix_arg => 1,
    coerce  => sub {
        my $record = pica_parser( plain => \$_[0], strict => 1 )->next;
        return $record ? $record->{record} : [];
    }
);

sub fix {
    my ( $self, $data ) = @_;

    if ( $data->{record} ) {
        return $data if reftype( $data->{record} ) ne 'ARRAY';
    }
    else {
        $data->{record} = [];
    }

    push @{ $data->{record} }, @{ $self->fields };

    return $data;
}

1;
__END__

=head1 NAME

Catmandu::Fix::pica_append - parse and append full PICA fields

=head1 SYNOPSIS

    pica_append('021A $abook$hto read');
    
=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 pica_append(PICA)

Add one or more PICA+ fields given in PICA Plain syntax. 

=head1 SEE ALSO

See L<Catmandu::Fix::pica_update> and L<Catmandu::Fix::pica_add> to add
subfield values to existing fields and optionally add non-existing fields.

=cut
