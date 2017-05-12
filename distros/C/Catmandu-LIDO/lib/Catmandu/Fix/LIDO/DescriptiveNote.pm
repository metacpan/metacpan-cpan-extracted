package Catmandu::Fix::LIDO::DescriptiveNote;

use Catmandu::Fix::LIDO::Utility qw(walk declare_source);
use Catmandu::Fix::LIDO::Value qw(emit_base_value);

use strict;

our $VERSION = '0.09';

use Exporter qw(import);

our @EXPORT_OK = qw(emit_descriptive_note);

##
# Emit the code that generates a descriptiveNoteValue.
# @param $fixer
# @param $root
# @param $path
# @param $value
# @param $lang
# @param $label
# @return $fixer emit code
sub emit_descriptive_note{
    my ($fixer, $root, $path, $value, $lang, $label) = @_;
    my $code = '';

    my $new_path = $fixer->split_path($path);

    my $v_root = $fixer->var;
    if (defined($root)) {
        $v_root = $root;
    }

    my $f_value = $fixer->generate_var();
    $code .= "my ${f_value};";
    $code .= declare_source($fixer, $value, $f_value);

    $code .= $fixer->emit_create_path(
        $v_root,
        $new_path,
        sub {
            my $r_root = shift;
            my $r_code = '';

            $r_code .= $fixer->emit_create_path(
                $r_root,
                ['$append', 'descriptiveNoteValue', '$append'],
                sub {
                    my $dn_root = shift;

                    my $dn_code = '';

                    $dn_code .= "${dn_root} = {";

                    if (defined($lang)) {
                        $dn_code .= "'lang' => '".$lang."',";
                    }

                    if (defined($label)) {
                        $dn_code .= "'label' => '".$label."',";
                    }

                    $dn_code .= "'_' => ${f_value}";

                    $dn_code .= "};";

                    return $dn_code;
                }
            );

            return $r_code;
        }
    );

    return $code;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::LIDO::DescriptiveNote::emit_descriptive_note

=head1 SYNOPSIS

    emit_descriptive_note(
        $fixer, # The fixer object from the calling emit function inside the calling Fix (required).
        $root, # The root path (string) from which the path parameter must be created (required).
        $path, # The path (string) for the descriptiveNoteValue (required).
        $value, # The value of the descriptiveNoteValue, as a string path (required).
        $lang, # Language attribute, string.
        $label # Label attribute, string.
    )

=head1 DESCRIPTION

This function will generate the necessary emit code to generate a C<descriptiveNoteValue> in a given path.

=head2 MULTIPLE INSTANCES

To add multiple C<descriptiveNoteValue>'s at the same location (e.g. C<descriptiveMetadata.objectDescriptionWrap.objectDescriptionSet>), simply call the function multiple times with the same path. A new parent (e.g. C<objectDescriptionSet>) will be created for every new C<descriptiveNoteValue>, per the standard.

=head1 SEE ALSO

L<Catmandu::LIDO> and L<Catmandu>

=head1 AUTHORS

=over

=item Pieter De Praetere, C<< pieter at packed.be >>

=back

=head1 CONTRIBUTORS

=over

=item Pieter De Praetere, C<< pieter at packed.be >>

=item Matthias Vandermaesen, C<< matthias.vandermaesen at vlaamsekunstcollectie.be >>

=back

=head1 COPYRIGHT AND LICENSE

The Perl software is copyright (c) 2016 by PACKED vzw and VKC vzw.
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=encoding utf8

=cut