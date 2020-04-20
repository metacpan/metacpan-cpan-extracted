package Catmandu::Fix::pica_set;

our $VERSION = '1.02';

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use PICA::Path;

has path      => ( fix_arg => 1 );
has pica_path => ( fix_arg => 1 );
has record    => ( fix_opt => 1 );

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ( $self, $set_value, $fixer ) = @_;

    my $record_key  = $fixer->emit_string( $self->record // 'record' );
    my $pica_path   = PICA::Path->new($self->pica_path);

    my ($field_regex, $occurrence_regex, $subfield_regex) = @$pica_path;

    my $perl = "if (is_string(${set_value})) {";

    my $field_regex_var    = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars( $field_regex_var, "qr{$field_regex}" );

    my $subfield_regex_var    = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars( $subfield_regex_var, "qr{$subfield_regex}" );

    my $occurrence_regex_var;
    if (defined $occurrence_regex) {

        $occurrence_regex_var = $fixer->generate_var;
        $perl .= $fixer->emit_declare_vars( $occurrence_regex_var, "qr{$occurrence_regex}" );
    }

    my $data  = $fixer->var;
    my $added = $fixer->generate_var;

    $perl .= $fixer->emit_declare_vars($added);
    $perl .= $fixer->emit_foreach(
        "${data}->{${record_key}}",
        sub {
            my $var  = shift;
            my $perl = "next if ${var}->[0] !~ ${field_regex_var};";
            if (defined $occurrence_regex) {
                $perl .= "next if (!defined ${var}->[1] || ${var}->[1] !~ ${occurrence_regex_var});";
            }
            my $i  = $fixer->generate_var;
            $perl .= $fixer->emit_declare_vars($i) .
            "for (${i} = 2; ${i} < \@{${var}}; ${i} += 2) {".
                "if (${var}->[${i}] =~ ${subfield_regex_var}) {".
                    "${var}->[${i} + 1] = ${set_value};".
                "}".
            "}";
            $perl;
        }
    );
    $perl .= "}";
}

1;
__END__

=head1 NAME

Catmandu::Fix::pica_set - sets a new value to an existing subfield

=head1 SYNOPSIS

    # Set value of dc.identifier as new value for subfield 0 in PICA field 003A
    pica_set('dc.identifier', '003A0');
    
    # same as above, but use another record path ('pica')
    pica_set('dc.identifier', '003A0', record:'pica');

=head1 DESCRIPTION

This fix sets the value from PATH to a subfield defined through PICA_PATH.

=head1 FUNCTIONS

=head2 pica_set(PATH, PICA_PATH, [OPT1])

=head3 Options

=over
 
=item * record - alternative record key (default is 'record')

=back

=head1 SEE ALSO

See L<Catmandu::Fix::pica_add> for adding new fields and subfields to a PICA record.

See L<Catmandu::Fix::pica_map> if you want to copy values from a PICA record.

See L<PICA::Path> for a definition of PICA path expressions and L<PICA::Data>
for more methods to process parsed PICA+ records.

=cut
