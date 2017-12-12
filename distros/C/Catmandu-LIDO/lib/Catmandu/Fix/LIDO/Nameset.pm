package Catmandu::Fix::LIDO::Nameset;

use Catmandu::Fix::LIDO::Utility qw(walk declare_source);
use Catmandu::Fix::LIDO::Value qw(emit_base_value);

use strict;

our $VERSION = '0.10';

use Exporter qw(import);

our @EXPORT_OK = qw(emit_nameset);

##
# Emit the code that generates a lido nameset node in a path. A nameset consists of appellationValue and sourceAppellation
# The node is attached directly to the path, so you must specify the name of
# the nameset (e.g. titleSet) in the $path.
# @param $fixer
# @param $root
# @param $path
# @param $appellation_value
# @param $appellation_value_lang
# @param $appellation_value_type
# @param $appellation_value_pref
# @param source_appellation
# @param source_appellation_lang
# @return $fixer emit code
sub emit_nameset {
    my ($fixer, $root, $path, $appellation_value, $appellation_value_lang, $appellation_value_type, $appellation_value_pref, $source_appellation, $source_appellation_lang) = @_;
    my $code = '';

    my $new_path = $fixer->split_path($path);


    my $last = pop @$new_path;

    my $value_path = ['appellationValue'];
    my $source_path = ['sourceAppellation'];

    ##
    # Bug #4
    if ($last eq '$append' || $last eq '$prepend' || $last eq '$last' || $last eq '$first') {
        unshift @$value_path, $last;
        if ($last eq '$prepend' || $last eq '$first') {
            unshift @$source_path, '$first';
        } else {
            unshift @$source_path, '$last';
        }
    } else {
        push @$new_path, $last;
    }

    my $f_av = $fixer->generate_var();
    my $f_sa = $fixer->generate_var();
    my $a_root = $fixer->var;
    if (defined($root)) {
        $a_root = $root;
    }

    ##
    # appellationValue
    if (defined($appellation_value)) {
        $code .= "my ${f_av};";
        $code .= declare_source($fixer, $appellation_value, $f_av);
    }

    ##
    # sourceAppellation
    if (defined($source_appellation)) {
        $code .= "my ${f_sa};";
        $code .= declare_source($fixer, $source_appellation, $f_sa);
    }

    $code .= $fixer->emit_create_path(
        $a_root,
        $new_path,
        sub {
            my $r_root = shift;
            my $r_code = '';

            ##
            # appellationValue
            if (defined($appellation_value)) {
                $r_code .= emit_base_value($fixer, $r_root, join('.', @$value_path), $appellation_value,
                $appellation_value_lang, $appellation_value_pref, undef, $appellation_value_type);
            }

            ##
            # sourceAppellation
            if (defined ($source_appellation)) {
                $r_code .= emit_base_value($fixer, $r_root, join('.', @$source_path), $source_appellation,
                $appellation_value_lang);
            }

            return $r_code;
        }
    );

    return $code;
};

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::LIDO::Nameset::emit_nameset

=head1 SYNOPSIS

    emit_nameset(
        $fixer, # The fixer object from the calling emit function inside the calling Fix (required).
        $root, # The root path (string) from which the path parameter must be created (required).
        $path, # The path (string) for the nameset - must include the name of the nameset node (required).
        $appellation_value, # The value of the appellationValue component of the nameset, as a string path (required).
        $appellation_value_lang, # appellationValue.lang attribute, string.
        $appellation_value_type, # appellationValue.type attribute, string.
        $appellation_value_pref, # appellationValue.pref attribute, string.
        $source_appellation, # Value of the sourceAppellation component, as a string path (required).
        $source_appellation_lang # sourceAppellation.lang, string.
    )

=head1 DESCRIPTION

This function will generate the necessary emit code to generate a C<nameset> node, consisting of C<appellationValue> and C<sourceAppellation>, in a given path. The node is attached directly to the path, so you must specify the name of the nameset (e.g. titleSet) in the $path.

=head2 MULTIPLE INSTANCES

Multiple instances can be created in two ways, depending on whether you want to repeat the parent element or not.

If you do not want to repeat the parent element, call the function multiple times with the same C<path>. Multiple C<appellationValue> and C<sourceAppellation> tags will be created on the same level.

If you do want to repeat the parent element (to keep related C<appellationValue> and C<sourceAppellation> together), add an C<$append> to your path for all calls.

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