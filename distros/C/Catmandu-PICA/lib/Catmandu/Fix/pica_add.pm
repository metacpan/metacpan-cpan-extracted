package Catmandu::Fix::pica_add;

our $VERSION = '0.24';

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use PICA::Path;

has path      => ( fix_arg => 1 );
has pica_path => ( fix_arg => 1 );
has record    => ( fix_opt => 1 );
has force_new => ( fix_opt => 1 );

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ( $self, $add_value, $fixer ) = @_;

    my $record_key  = $fixer->emit_string( $self->record // 'record' );
    my $pica_path   = PICA::Path->new($self->pica_path);

    my ($field, $occurrence, $subfield) = map {
        defined $_ ? do {
            s/^\(\?[^:]*:(.*)\)$/$1/;
            s/\./*/g;
            $_ } : undef
        } ($pica_path->[0], $pica_path->[1], $pica_path->[2]);


    my ($field_regex, $occurrence_regex) = @$pica_path;

    $subfield   = $fixer->emit_string( $subfield );
    $field      = $fixer->emit_string( $field );
    $occurrence = $fixer->emit_string( $occurrence // '' );

    my $subfields = $fixer->generate_var;
    my $sf_data   =  $fixer->generate_var;
    my $i         =  $fixer->generate_var;
    my $value     =  $fixer->generate_var;

    my $perl = $fixer->emit_declare_vars( $value ) .
        "if ( defined ${add_value} && ${subfield} ne '[_A-Za-z0-9]') { ".
        "${value} = ${add_value};" .
        "if ( is_string(${value}) || ${value} eq '' ) { ${value} = [ ${value} ] }; " .
        "if (ref(${value}) eq 'ARRAY') { " .
        $fixer->emit_declare_vars( $i, 0 ) .
        $fixer->emit_declare_vars( $subfields ) .
        $fixer->emit_declare_vars( $sf_data ) .
        "\@${subfields} = split //, substr(${subfield}, 1, length(${subfield}) -2);" .
        "\@${sf_data} = map { defined ${value}->[${i}] ? " .
        "(\$_ => ${value}->[${i}++]) : () } \@${subfields};";

    my $field_regex_var    = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars( $field_regex_var, "qr{$field_regex}" );

    my $occurrence_regex_var;
    if (defined $occurrence_regex) {
        $occurrence_regex_var = $fixer->generate_var;
        $perl .= $fixer->emit_declare_vars( $occurrence_regex_var, "qr{$occurrence_regex}" );
    }

    my $data  = $fixer->var;
    my $added = $fixer->generate_var;

    $perl .= $fixer->emit_declare_vars($added);

    unless ($self->force_new) {
        $perl .= $fixer->emit_foreach(
            "${data}->{${record_key}}",
            sub {
                my $var  = shift;
                my $perl = "next if ${var}->[0] !~ ${field_regex_var};";
                if (defined $occurrence_regex) {
                    $perl .= "next if (!defined ${var}->[1] || ${var}->[1] !~ ${occurrence_regex_var});";
                }
                $perl .= "push \@{${var}}, \@${sf_data}; ${added} = 1;";
            }
        );
    }

    $perl .= "push(\@{ ${data}->{${record_key}} }, " .
        "[${field}, ${occurrence}, \@${sf_data} ]) unless defined ${added} } };";
}

1;
__END__

=head1 NAME

Catmandu::Fix::pica_add - add new subfields to record

=head1 SYNOPSIS

    # Copy value of dc.identifier to PICA field 003A as subfield 0
    pica_add('dc.identifier', '003A0');
    
    # Same as above, but use another record path ('pica')
    pica_add('dc.identifier', '003A0', record:'pica');
    
    # force the creation of a new field 003A
    pica_add('dc.identifier', '003A0', force_new:1);
    
    # Add multiple subfields
    # "dc": {"subjects": ["foo", "bar"]}
    pica_add('dc.subjects', '004Faf')

=head1 DESCRIPTION

This fix adds subfields with value of PATH to the PICA field. The value of PATH must be either
a scalar or an array.

If PICA field does not exist, it will be created.

=head1 FUNCTIONS

=head2 pica_add(PATH, PICA_PATH, [OPTIONS])

=head3 Options

=over

=item * record - alternative record key (default is 'record')

=item * force_new - force the creation of a new field

=back

=head1 SEE ALSO

See L<Catmandu::Fix::pica_set> for setting a new value to an existing subfield.

See L<Catmandu::Fix::pica_map> if you want to copy values from a PICA record.

See L<PICA::Path> for a definition of PICA path expressions and L<PICA::Data>
for more methods to process parsed PICA+ records.

=cut
