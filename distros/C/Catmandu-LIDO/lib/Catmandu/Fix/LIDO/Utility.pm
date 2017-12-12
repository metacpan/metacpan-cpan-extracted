package Catmandu::Fix::LIDO::Utility;

use strict;

our $VERSION = '0.10';

use Exporter qw(import);
use String::Util qw(trim);

our @EXPORT_OK = qw(walk declare_source);

##
# For a source $var, that is a path parameter to a fix,
# use walk() to get the value and return the generated
# $perl code.
# @param $fixer
# @param $var
# @param $declared_var
# @return $fixer emit code
sub declare_source {
	my ( $fixer, $var, $declared_var ) = @_;

	my $perl = '';

	my $var_path = $fixer->split_path ( $var );
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
# @param $fixer
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
