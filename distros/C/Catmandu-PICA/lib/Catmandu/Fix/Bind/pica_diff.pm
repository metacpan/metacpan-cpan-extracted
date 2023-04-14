package Catmandu::Fix::Bind::pica_diff;

our $VERSION = '1.13';

use Moo;
use Catmandu::Sane;
use PICA::Data qw(pica_fields pica_annotation pica_title pica_diff);
use Scalar::Util 'reftype';

with 'Catmandu::Fix::Bind', 'Catmandu::Fix::Bind::Group';

sub bind {
    my ( $self, $data, $code ) = @_;
    return if reftype( $data->{record} ) ne 'ARRAY';

    my $ppn    = pica_fields( $data->{record}, '003@' );
    my $before = [ map { [@$_] } @{ $data->{record} } ];

    $code->($data);
    my $diff   = pica_diff( $before, $data->{record} );
    my $fields = [ map { [@$_] } @{ $diff->{record} } ];

    # Add record identifier
    if (@$fields) {
        if ( $fields->[0][0] =~ /^0/ && @$ppn ) {
            pica_annotation( $ppn->[0], ' ' );
            unshift @$fields, @$ppn;
        }
    }

    $data->{record} = $fields;
    return $data;
}

1;
__END__

=head1 NAME

Catmandu::Fix::Bind::pica_diff - a binder that tracks changes in PICA records

=head1 SYNOPSIS

  do pica_diff()
    pica_set(foo,021A$a)
    pica_add(foo,010@$x)
  end
 
=head1 DESCRIPTION

This binder replaces a record with a L<PICA Patch|https://format.gbv.de/pica/patch>
record of changes applied to the original record. If the record is not changed inside
the C<do pica_diff()> section, the result will be an empty record.

The original record must be limited to fields of one level. Field C<003@> is included
in the resulting patch record for level 0, if found.

=cut
