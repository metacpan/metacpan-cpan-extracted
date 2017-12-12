package Catmandu::Fix::LIDO::Value;

use Catmandu::Fix::LIDO::Utility qw(walk declare_source);

use strict;

our $VERSION = '0.10';

use Exporter qw(import);

our @EXPORT_OK = qw(emit_base_value emit_simple_value);


##
# Provide emit code to generate a simple LIDO node consisting of a key => value pair, with optional attributes.
# The key must be part of the $path.
# This function must be used when the node can not be repeated.
# @param $fixer
# @param $root
# @param $path
# @param $value
# @param $lang
# @param $pref
# @param $label
# @param $type
# @param $is_string
# @return $fixer emit code
sub emit_simple_value {
    my ($fixer, $root, $path, $value, $lang, $pref, $label, $type, $is_string) = @_;

    my $new_path = $fixer->split_path($path);
    my $code = '';
    my $f_val = $fixer->generate_var();

    if (!defined($is_string)) {
        $is_string = 0;
    }

    if ($is_string == 0) {
        $code .= "my ${f_val};";
        $code .= declare_source($fixer, $value, $f_val);
    }

    my $v_root = $fixer->var;
    if (defined($root)) {
        $v_root = $root;
    }

    $code .= $fixer->emit_create_path(
        $v_root,
        $new_path,
        sub {
            my $r_root = shift;
            my $r_code = '';

            $r_code .= "${r_root} = {";

            if (defined($lang)) {
                $r_code .= "'lang' => '".$lang."',";
            }
            if (defined ($pref)) {
                $r_code .= "'pref' => '".$pref."',";
            }
            if (defined ($label)) {
                $r_code .= "'label' => '".$label."',";
            }
            if (defined ($type)) {
                $r_code .= "'type' => '".$type."',";
            }
            if ($is_string == 0) {
                $r_code .= "'_' => ${f_val}";
            } else {
                $r_code .= "'_' => '".$value."'";
            }

            $r_code .= "};";

            return $r_code;
        }
    );

    return $code;
}

##
# Provide emit code to generate a simple LIDO node consisting of a key => value pair, with optional attributes.
# The key must be part of the $path.
# This function must be used when the node can be repeated.
# @param $fixer
# @param $root
# @param $path
# @param $value
# @param $lang
# @param $pref
# @param $label
# @param $type
# @param $is_string
# @return $fixer emit code
sub emit_base_value {
    my ($fixer, $root, $path, $value, $lang, $pref, $label, $type, $is_string) = @_;

    my $new_path = $fixer->split_path($path);
    my $code = '';
    my $f_val = $fixer->generate_var();

    if (!defined($is_string)) {
        $is_string = 0;
    }

    if ($is_string == 0) {
        $code .= "my ${f_val};";
        $code .= declare_source($fixer, $value, $f_val);
    }

    my $v_root = $fixer->var;
    if (defined ($root)) {
        $v_root = $root;
    }

    $code .= $fixer->emit_create_path(
        $v_root,
        $new_path,
        sub {
            my $r_root = shift;
            my $r_code = '';

            $r_code .= $fixer->emit_create_path(
                $r_root,
                ['$append'],
                sub {
                    my $a_root = shift;
                    my $a_code = '';
                    $a_code .= "${a_root} = {";
                    if (defined($lang)) {
                        $a_code .= "'lang' => '".$lang."',";
                    }
                    if (defined ($pref)) {
                        $a_code .= "'pref' => '".$pref."',";
                    }
                    if (defined ($label)) {
                        $a_code .= "'label' => '".$label."',";
                    }
                    if (defined ($type)) {
                        $a_code .= "'type' => '".$type."',";
                    }
                    if ($is_string == 0) {
                        $a_code .= "'_' => ${f_val}";
                    } else {
                        $a_code .= "'_' => '".$value."'";
                    }
                    $a_code .= "};";
                    return $a_code;
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

Catmandu::Fix::LIDO::Value::emit_value & Catmandu::Fix::LIDO::Value::emit_simple_value

=head1 SYNOPSIS

C<emit_value> and C<emit_simple_value> have the same calling syntax.

    emit_value(
        $fixer, # The fixer object from the calling emit function inside the calling Fix (required).
        $root, # The root path (string) from which the path parameter must be created (required).
        $path, # The path (string) for the value - must include the name of the value node (required).
        $value, # Path (string) to the value of the component (required).
        $lang, # xml:lang attribute, string.
        $pref, # pref attribute, string.
        $label, # label attribute, string
        $source, # source attribute, string.
        $type, # type attribute, string.
        $is_string # set to 1 if $value is not a path, but a string, so $value is directly interpolated in the emit code.
    )

=head1 DESCRIPTION

C<emit_value> and C<emit_simple_value> will generate the necessary emit code to generate a node in a given path. The node is attached directly to the path, so you must specify the name of the node (e.g. category) in the $path.

Use C<emit_value> when the node is repeatable and C<emit_simple_value> when it isn't.

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