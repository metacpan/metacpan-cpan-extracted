package Catmandu::Fix::pica_map;

our $VERSION = '1.04';

use Catmandu::Sane;
use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Fix::Has;
use PICA::Data qw(pica_match);

with 'Catmandu::Fix::Builder';

has pica_path     => ( fix_arg => 1 );
has path          => ( fix_arg => 1 );
has split         => ( fix_opt => 1 );
has join          => ( fix_opt => 1 );
has value         => ( fix_opt => 1 );
has pluck         => ( fix_opt => 1 );
has nested_arrays => ( fix_opt => 1 );

sub _build_fixer {
    my ($self) = @_;

    my $path    = as_path( $self->path );
    my $key     = $path->split_path->[-1];
    my $creator = $path->creator;

    my %opt = (
        'join'          => $self->join          // '',
        'split'         => $self->split         // 0,
        'pluck'         => $self->pluck         // 0,
        'nested_arrays' => $self->nested_arrays // 0,
        'value'         => $self->value,
        'force_array' => ( $key =~ /^(\$.*|[0-9]+)$/ ) ? 1 : 0,
    );

    sub {
        my $data = $_[0];
        my $matches = pica_match( $data, $self->pica_path, %opt );
        if ( defined $matches ) {
            $matches = [$matches]
                if !ref($matches) || ( $opt{split} && !$opt{force_array} );
            while (@$matches) {
                $data = $creator->( $data, shift @$matches );
            }

        }
        return $data;
        }
}

1;

__END__

=head1 NAME

Catmandu::Fix::pica_map - copy pica values of one field to a new field

=head1 SYNOPSIS

    # Copy from field 021A all subfields to field dc_title
    pica_map(021A, dc_title);

    # Copy from field 021A subfield a to field dc_title
    pica_map(021Aa, dc_title);

    # Copy from field 021A subfield a and d to field dc_title and join them 
    pica_map(021Aad, dc_title, join:' / ');
 
    # Copy from field 021A subfield d and a in given order to field dc_title 
    pica_map(021Ada, dc_title, pluck:1);

    # Copy from field 021A subfield a and d to field dc_title and append them to an array
    pica_map(021Ada, dc_title.$append);

    # Copy from field 021A all subfields to field dc_title and split them to an array
    pica_map(021Ada, dc_title, split:1);

    # Copy from all fields 005A all subfields to field bibo_issn and split them to an array of arrays
    pica_map(005A, bibo_issn, split:1, nested_arrays:1);

    # Copy from field 144Z with occurrence 01 subfield a to dc_subject
    pica_map('144Z[01]a','dc_subject');

=head1 SEE ALSO

See L<PICA::Path> for a definition of PICA path expressions and mapping rules or test files for more examples. See L<PICA::Data>
for more methods to process parsed PICA+ records.

=cut
