package Catmandu::Fix::Datahub::Util;

use strict;

use Exporter qw(import);

our @EXPORT_OK = qw(declare_source walk);

##
# For a source $var, that is a path parameter to a fix,
# use walk() to get the value and return the generated
# $perl code.
# @param $var
# @param $declared_var
# @return $fixer emit code
sub declare_source {
    my ($fixer, $var, $declared_var) = @_;
	
	my $perl = '';

    my $var_path = $fixer->split_path($var);
	my $var_key = pop @$var_path;
	$perl .= walk($fixer, $var_path, $var_key, $declared_var);
	return $perl;
}

##
# Walk through a path ($path) until at
# $key. Set $h = $val in the fixer code.
# $h must be declared before calling walk()
# This has the effect of assigning $val (the value of the leaf
# node you're walking to) to $h, so you can use $h in your fix.
# @param $path
# @param $key
# @param $h
# @return $fixer emit code
sub walk {
	my ($fixer, $path, $key, $h) = @_;

	my $perl = '';
	
	$perl .= $fixer->emit_walk_path(
		$fixer->var,
		$path,
		sub {
			my $var = shift;
			$fixer->emit_get_key(
				$var,
				$key,
				sub {
					my $val = shift;
					"${h} = ${val};";
				}
			);
		}
	);
	
	return $perl;
}

1;
__END__

__END__

=encoding utf-8

=head1 NAME

=for html <a href="https://travis-ci.org/thedatahub/Catmandu-Fix-Datahub"><img src="https://travis-ci.org/thedatahub/Catmandu-Fix-Datahub.svg?branch=master"></a>

Catmandu::Fix::Datahub - Utility functions and generic fixes developed for the Datahub project

=head1 SYNOPSIS

  use Catmandu::Fix::Datahub::Util;

=head1 DESCRIPTION

  use Catmandu::Fix::Datahub::Util;

=over 4

=item C<declare_source($fixer, $var, $declared_var)>

For an item C<$var>, which is a path (as a string) in a Catmandu fix, assign the value at the path to C<$declared_var>,
which is a variable that was previously declared in the fix code:

  my $f_var = $self->fixer->generate_var();
  $code .= "my ${f_var};";
  $code .= declare_source($self->fixer, 'foo.bar', $f_var);

=item C<walk($fixer, $path, $key, $h)>

Walk through a C<$path> (as an arrayref) until at C<$key>. Assign the value of C<$key> to C<$h>.
C<$h> must be declared in the fix code.

  my $f_var = $self->fixer->generate_var();
  $code .= "my ${f_var};";
  $code .= walk($self->fixer, ['foo', 'bar'], $f_var);

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter@packed.beE<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>

=cut
