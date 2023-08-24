package Catmandu::Fix::pica_set;

use Catmandu::Sane;

our $VERSION = '1.17';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Fix::Has;
use PICA::Path;

has path => ( fix_arg => 1 );
has pica_path => (
    fix_arg => 1,
    coerce  => sub { PICA::Path->new( $_[0] ) }
);
has record => ( fix_opt => 1 );

with 'Catmandu::Fix::Builder';

sub _build_fixer {
    my ($self) = @_;

    my $value_getter  = as_path( $self->path )->getter;
    my $record_getter = as_path( $self->record // 'record' )->getter;
    my $pica_path     = $self->pica_path;
    my $subfields     = '[' . ( $pica_path->subfields // '_A-Za-z0-9' ) . ']';
    $subfields = qr{$subfields};

    sub {
        my ($data) = @_;
        my $value = $value_getter->($data)->[0];
        for my $record ( @{ $record_getter->($data) } ) {
            for my $field (@$record) {
                next unless $pica_path->match_field($field);
                for ( my $i = 3 ; $i < @$field ; $i += 2 ) {
                    next unless $field->[ $i - 1 ] =~ $subfields;
                    $field->[$i] = $value;
                }
            }
        }
        $data;
    }
}

1;
__END__

=head1 NAME

Catmandu::Fix::pica_set - sets a new value to an existing subfield

=head1 SYNOPSIS

    # Set value of dc.identifier as new value for subfield 0 in PICA field 003A
    pica_set('dc.identifier', '003A$0');
    
    # same as above, but use another record path ('pica')
    pica_set('dc.identifier', '003A$0', record:'pica');

=head1 DESCRIPTION

This fix sets the value from PATH to a subfield defined through PICA_PATH.

=head1 FUNCTIONS

=head2 pica_set(PATH, PICA_PATH, [OPT1])

=head3 Options

=over
 
=item * record - alternative record key (default is 'record')

=back

=head1 SEE ALSO

See L<Catmandu::Fix::pica_update> and L<Catmandu::Fix::pica_add> for adding new
fields and subfields to a PICA record.

See L<Catmandu::Fix::pica_map> if you want to copy values from a PICA record.

See L<PICA::Path> for a definition of PICA path expressions and L<PICA::Data>
for more methods to process parsed PICA+ records.

=cut
