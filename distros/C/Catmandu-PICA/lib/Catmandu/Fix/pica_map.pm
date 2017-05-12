package Catmandu::Fix::pica_map;

our $VERSION = '0.19';

use Catmandu::Sane;
use Moo;

use Catmandu::Fix::Has;
use PICA::Path;

has pica_path => ( fix_arg => 1 );
has path      => ( fix_arg => 1 );
has record    => ( fix_opt => 1 );
has split     => ( fix_opt => 1 );
has join      => ( fix_opt => 1 );
has value     => ( fix_opt => 1 );
has pluck     => ( fix_opt => 1 );

sub emit {
    my ( $self, $fixer ) = @_;
    my $path       = $fixer->split_path( $self->path );
    my $record_key = $fixer->emit_string( $self->record // 'record' );
    my $join_char  = $fixer->emit_string( $self->join // '' );
    my $pica_path  = PICA::Path->new($self->pica_path); 

    my ($field_regex, $occurrence_regex, $subfield_regex, $from, $length) = @$pica_path;

    my $var  = $fixer->var;
    my $vals = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars( $vals, '[]' );

    my $field_regex_var = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars( $field_regex_var, "qr{$field_regex}" );

    my $subfield_regex_var = $fixer->generate_var;
    $perl .= $fixer->emit_declare_vars( $subfield_regex_var, "qr{$subfield_regex}" );

    my $occurrence_regex_var;
    if (defined $occurrence_regex) {
        $occurrence_regex_var = $fixer->generate_var;
        $perl .= $fixer->emit_declare_vars( $occurrence_regex_var, "qr{$occurrence_regex}" );
    }

    $perl .= $fixer->emit_foreach(
        "${var}->{${record_key}}",
        sub {
            my $var  = shift;
            my $v    = $fixer->generate_var;
            my $perl = "";

            $perl .= "next if ${var}->[0] !~ ${field_regex_var};";

            if (defined $occurrence_regex) {
                $perl .= "next if (!defined ${var}->[1] || ${var}->[1] !~ ${occurrence_regex_var});";
            }

            if ( $self->value ) {
                $perl .= $fixer->emit_declare_vars( $v,
                    $fixer->emit_string( $self->value ) );
            }
            else {
                my $i = $fixer->generate_var;
                my $add_subfields = sub {
                    my $start = shift;
                    if ($self->pluck) {
                        # Treat the subfield_regex as a hash index
                        my $pluck = $fixer->generate_var;
                        return 
                        "my ${pluck}  = {};" .
                        "for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {".
                            "push(\@{ ${pluck}->{ ${var}->[${i}] } }, ${var}->[${i} + 1]);" .
                        "}" .
                        "for my ${i} (split('','${subfield_regex}')) { " .
                            "push(\@{${v}}, \@{ ${pluck}->{${i}} }) if exists ${pluck}->{${i}};" .
                        "}";
                    }
                    else {
                        # Treat the subfield_regex as regex that needs to match the subfields
                        return 
                        "for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {".
                            "if (${var}->[${i}] =~ /${subfield_regex}/) {".
                                "push(\@{${v}}, ${var}->[${i} + 1]);".
                            "}".
                        "}";
                    }
                };
                $perl .= $fixer->emit_declare_vars( $v, "[]" );
                $perl .= $add_subfields->(2);
                $perl .= "if (\@{${v}}) {";
                if ( !$self->split ) {
                    $perl .= "${v} = join(${join_char}, \@{${v}});";
                    if ( defined( my $off = $from ) ) {
                        $perl .= "if (eval { ${v} = substr(${v}, ${off}, ${length}); 1 }) {";
                    }
                }
                $perl .= $fixer->emit_create_path(
                    $fixer->var,
                    $path,
                    sub {
                        my $var = shift;
                        if ( $self->split ) {
                            "if (is_array_ref(${var})) {"
                                . "push \@{${var}}, ${v};"
                                . "} else {"
                                . "${var} = [${v}];" . "}";
                        }
                        else {
                            "if (is_string(${var})) {"
                                . "${var} = join(${join_char}, ${var}, ${v});"
                                . "} else {"
                                . "${var} = ${v};" . "}";
                        }
                    }
                );
                if ( defined($from) ) {
                    $perl .= "}";
                }
                $perl .= "}";
            }
            $perl;
        }
    );

    $perl;
}

1;
__END__

=head1 NAME

Catmandu::Fix::pica_map - copy mab values of one field to a new field

=head1 SYNOPSIS

    # Copy from field 003@ subfield 0 to dc.identifier hash
    pica_map('003A0','dc.identifier');

    # Copy from field 003@ subfield 0 to dc.identifier hash
    pica_map('010@a','dc.language');

    # Copy from field 009Q subfield a to foaf.primaryTopicOf array
    pica_map('009Qa','foaf.primaryTopicOf.$append');

    # Copy from field 028A subfields a and d to dc.creator hash joining them by ' '
    pica_map('028Aad','dcterms.creator', -join => ' ');

    # Copy from field 028A with ocurrance subfields a and d to dc.contributor hash joining them by ' '
    pica_map('028B[01]ad','dcterms.ccontributor', -join => ' ');

=head1 SEE ALSO

See L<PICA::Path> for a definition of PICA path expressions and L<PICA::Data>
for more methods to process parsed PICA+ records.

=cut
