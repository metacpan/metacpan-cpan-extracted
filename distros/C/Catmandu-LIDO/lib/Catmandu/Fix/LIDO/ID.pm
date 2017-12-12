package Catmandu::Fix::LIDO::ID;

use strict;

our $VERSION = '0.10';

use Exporter qw(import);

use Catmandu::Fix::LIDO::Utility qw(walk declare_source);

our @EXPORT_OK = qw(emit_base_id);

##
# Emit the code that generates a lido id node in a path. The node is attached directly to the path, so you
# must specify the name of the id (e.g. lidoRecID) in the $path.
# @param $fixer
# @param $root
# @param $path
# @param $id
# @param $source
# @param $label
# @param $type
# @param $pref
# @return $fixer emit code
sub emit_base_id {
	my ($fixer, $root, $path, $id, $source, $label, $type, $pref) = @_;

	my $new_path = $fixer->split_path($path);
    my $code = '';

	my $f_id = $fixer->generate_var();
	$code .= "my ${f_id};";
	$code .= declare_source($fixer, $id, $f_id);

	my $i_root = $fixer->var;
	if (defined($root)) {
		$i_root = $root;
	}

    $code .= $fixer->emit_create_path(
		$i_root,
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

					if (defined($type)) {
						$a_code .= "'type' => '".$type."',";
					}

					if (defined($pref)) {
						$a_code .= "'pref' => '".$pref."',";
					}

					if (defined($source)) {
						$a_code .= "'source' => '".$source."',";
					}

					if (defined($label)) {
						$a_code .= "'label' => '".$label."',";
					}

					$a_code .= "'_' => ${f_id}";

					$a_code .= "};";

					return $a_code;
				}
			);

			return $r_code;
		}
	);

    return $code;
};

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::LIDO::ID::emit_id

=head1 SYNOPSIS

    emit_id(
        $fixer, # The fixer object from the calling emit function inside the calling Fix (required).
        $root, # The root path (string) from which the path parameter must be created (required).
		$path, # The path (string) for the id - must include the name of the id node (required).
        $id, # The value of the id node, as a string path (required).
        $source, # Source attribute, string.
		$label, # Label attribute, string.
		$type # Type attribute, string.
    )

=head1 DESCRIPTION

This function will generate the necessary emit code to generate a C<id> node in a given path. The node is attached directly to the path, so you must specify the name of the id (e.g. lidoRecID) in the $path.

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