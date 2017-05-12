=head1 NAME

Class::ParamParser - Provides complex parameter list parsing

=cut

######################################################################

package Class::ParamParser;
require 5.004;

# Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved.  This module
# is free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.  However, I do request that this copyright information and
# credits remain attached to the file.  If you modify this module and
# redistribute a changed version then please attach a note listing the
# modifications.  This module is available "as-is" and the author can not be held
# accountable for any problems resulting from its use.

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '1.041';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	I<none>

=head1 SYNOPSIS

	use Class::ParamParser;
	@ISA = qw( Class::ParamParser );

=head2 PARSING PARAMS INTO NAMED HASH

	sub textfield {
		my $self = shift( @_ );
		my $rh_params = $self->params_to_hash( \@_, 0, 
			[ 'name', 'value', 'size', 'maxlength' ], 
			{ 'default' => 'value' } );
		$rh_params->{'type'} = 'text';
		return( $self->make_html_tag( 'input', $rh_params ) );
	}

	sub textarea {
		my $self = shift( @_ );
		my $rh_params = $self->params_to_hash( \@_, 0, 
			[ 'name', 'text', 'rows', 'cols' ], { 'default' => 'text', 
			'value' => 'text', 'columns' => 'cols' }, 'text', 1 );
		my $ra_text = delete( $rh_params->{'text'} );
		return( $self->make_html_tag( 'textarea', $rh_params, $ra_text ) );
	}

	sub AUTOLOAD {
		my $self = shift( @_ );
		my $rh_params = $self->params_to_hash( \@_, 0, 'text', {}, 'text' );
		my $ra_text = delete( $rh_params->{'text'} );
		$AUTOLOAD =~ m/([^:]*)$/;
		my $tag_name = $1;
		return( $self->make_html_tag( $tag_name, $rh_params, $ra_text ) );
	}

=head2 PARSING PARAMS INTO POSITIONAL ARRAY

	sub property {
		my $self = shift( @_ );
		my ($key,$new_value) = $self->params_to_array(\@_,1,['key','value']);
		if( defined( $new_value ) ) {
			$self->{$key} = $new_value;
		}
		return( $self->{$key} );
	}

	sub make_html_tag {
		my $self = shift( @_ );
		my ($tag_name, $rh_params, $ra_text) = 
			$self->params_to_array( \@_, 1, 
			[ 'tag', 'params', 'text' ],
			{ 'name' => 'tag', 'param' => 'params' } );
		ref($rh_params) eq 'HASH' or $rh_params = {};
		ref($ra_text) eq 'ARRAY' or $ra_text = [$ra_text];
		return( join( '', 
			"<$tag_name", 
			(map { " $_=\"$rh_params->{$_}\"" } keys %{$rh_params}),
			">",
			@{$ra_text},
			"</$tagname>",
		) );
	}

=head1 DESCRIPTION

This Perl 5 object class implements two methods which inherited classes can use
to tidy up parameter lists for their own methods and functions.  The two methods
differ in that one returns a HASH ref containing named parameters and the other
returns an ARRAY ref containing positional parameters.

Both methods can process the same kind of input parameter formats:

=over 4

=item 

I<empty list>

=item 

value

=item 

value1, value2, ...

=item 

name1 => value1, name2 => value2, ...

=item 

-name1 => value1, -NAME2 => value2, ...

=item 

{ -Name1 => value1, NAME2 => value2, ... }

=item 

{ name1 => value1, -Name2 => value2, ... }, valueR

=item 

{ name1 => value1, -Name2 => value2, ... }, valueR1, valueR2, ...

=back

Those examples included single or multiple positional parameters, single or
multiple named parameters, and a HASH ref containing named parameters (with
optional "remaining" values afterwards).  That list of input variations is not
exhaustive.  Named parameters can either be prefixed with "-" or left natural.

We assume that the parameters are named when either they come as a HASH ref or
the first parameter begins with a "-".  We assume that they are positional if
there is an odd number of them.  Otherwise we are in doubt and rely on an
optional argument to the tidying method that tells us which to guess by default.

We assume that any "value" may be an array ref (aka "multiple" values under the
same name) and hence we don't do anything special with them, passing them as is.  
The only exception to this is with "remaining" values; if there is more than one 
of them and the first isn't an array ref, then they are all put in an array ref.

If the source and destination are both positional, then they are identical.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 
Note that this class doesn't have any properties of its own.

=head1 FUNCTIONS AND METHODS

=head2 params_to_hash( SOURCE, DEF, NAMES[, RENAME[, REM[, LC]]] )

See below for argument descriptions.

=cut

######################################################################

sub params_to_hash {
	my ($self, $ra_args, $posit_by_def, $ra_posit_names, $rh_rename, 
		$remaining_param_name, $lc) = @_;

	# Shortcut - no input means no output.
	ref( $ra_args ) eq 'ARRAY' and @{$ra_args} or return( {} );

	# Put named arguments in $rh_args if there are any; put undef otherwise.
	# When the first element of $ra_args is a hash ref, other elems go in @rem.
	my ($rh_args, @rem) = $self->_args_are_named( $ra_args, 1, !$posit_by_def );

	# If the arguments are not named then...
	ref( $rh_args ) eq 'HASH' or do {

		# Shortcut - input is positional but no named translator, so no output.
		ref( $ra_posit_names ) eq 'ARRAY' and @{$ra_posit_names} or return( {} );

		# Translate positional arguments to named and return them.
		ref( $ra_posit_names ) eq 'ARRAY' or $ra_posit_names = [$ra_posit_names];
		return( $self->_posit_to_named( $ra_args, $ra_posit_names ) );
	};

	# Normalize named argument aliases to their standard versions.
	ref( $rh_rename ) eq 'HASH' or $rh_rename = {};
	my %args_out = %{$self->_rename_named_args( $rh_args, $rh_rename, 1, $lc )};

	# Incorporate "remaining" arguments if desired.
	if( @rem and $remaining_param_name ) {
		$args_out{$remaining_param_name} = 
			(ref( $rem[0] ) eq 'ARRAY' or @rem == 1) ? $rem[0] : \@rem;
	}

	# Return named arguments.
	return( \%args_out );
}

######################################################################

=head2 params_to_array( SOURCE, DEF, NAMES[, RENAME[, REM[, LC]]] )

See below for argument descriptions.

=cut

######################################################################

sub params_to_array {
	my ($self, $ra_args, $posit_by_def, $ra_posit_names, $rh_rename, 
		$remaining_param_name, $lc) = @_;

	# Shortcut - no input means no output.
	ref( $ra_args ) eq 'ARRAY' and @{$ra_args} or return( [] );

	# Put named arguments in $rh_args if there are any; put undef otherwise.
	# When the first element of $ra_args is a hash ref, other elems go in @rem.
	my ($rh_args, @rem) = $self->_args_are_named( $ra_args, 1, !$posit_by_def );

	# If the arguments are not named, then return a copy of positional arguments.
	ref( $rh_args ) eq 'HASH' or return( [@{$ra_args}] );  # input = output

	# Shortcut - input is named but no positional translator, so no output.
	ref( $ra_posit_names ) eq 'ARRAY' and @{$ra_posit_names} or return( [] );

	# Normalize named argument aliases to their standard versions.
	ref( $rh_rename ) eq 'HASH' or $rh_rename = {};
	my %args_out = %{$self->_rename_named_args( $rh_args, $rh_rename, 1, $lc )};

	# Incorporate "remaining" arguments if desired.
	if( @rem and $remaining_param_name ) {
		$args_out{$remaining_param_name} = 
			(ref( $rem[0] ) eq 'ARRAY' or @rem == 1) ? $rem[0] : \@rem;
	}

	# Translate named arguments to positional and return them.
	ref( $ra_posit_names ) eq 'ARRAY' or $ra_posit_names = [$ra_posit_names];
	return( $self->_named_to_posit( \%args_out, $ra_posit_names ) );
}

######################################################################

=head1 ARGUMENTS

The arguments for the above methods are the same, so they are discussed together
here:

=over 4

=item 1

The first argument, SOURCE, is an ARRAY ref containing the original parameters
that were passed to the method which calls this one.  It is safe to pass "\@_"
because we don't modify the argument at all.  If SOURCE isn't a valid ARRAY ref
then its default value is [].

=item 1

The second argument, DEF, is a boolean/scalar that tells us whether, when in
doubt over whether SOURCE is in positional or named format, what to guess by
default.  A value of 0, the default, means we guess named, and a value of 1 means
we assume positional.

=item 1

The third argument, NAMES, is an ARRAY ref (or SCALAR) that provides the names to
use when SOURCE and our return value are not in the same format (named or
positional).  This is because positional parameters don't know what their names
are and named parameters (hashes) don't know what order they belong in; the NAMES
array provides the missing information to both.  The first name in NAMES matches
the first value in a positional SOURCE, and so-on.  Likewise, the order of
argument names in NAMES determines the sequence for positional output when the
SOURCE is named.

=item 1

The optional fourth argument, RENAME, is a HASH ref that allows us to interpret a
variety of names from a SOURCE in named format as being aliases for one enother. 
The keys in the hash are names to look for and the values are what to rename them
to.  Keys are matched regardless of whether the SOURCE names have "-" in front
of them or not.  If several SOURCE names are renamed to the same hash value, then
all but one are lost; the SOURCE should never contain more than one alias for the
same parameter anyway.  One way to explicitely delete a parameter is to rename it
with "", as parameters with that name are discarded.

=item 1

The optional fifth argument, REM, is only used in circumstances where the first
element of SOURCE is a HASH ref containing the actual named parameters that
SOURCE would otherwise be.  If SOURCE has extra, "remaining" elements following
the HASH ref, then REM says what its name is.  Remaining parameters with the same
name as normal parameters (post renaming and "-" substitution) take precedence. 
The default value for REM is "", and it is discarded unless renamed.  Note that 
the value returned with REM can be either a single scalar value, when the 
"remaining" is a single scalar value, or an array ref, when there are more than 
one "remaining" or the first "remaining" is an array ref (passed as is).

=item 1

The optional sixth argument, LC, is a boolean/scalar that forces named parameters 
in SOURCE to be lowercased; by default this is false, meaning that the original 
case is preserved.  Use this when you want your named parameters to have 
case-insensitive names, for accurate matching by your own code or RENAME.  If you 
use this, you must provide lowercased keys and values in your RENAME hash, as 
well as lowercased NAMES and REM; none of these are lowercased for you.

=back

=cut

######################################################################
# _args_are_named( ARGS[, USE_DASHES[, GUESS_NAMED]] )
# This private method will check if the incoming argument list, provided in 
# the array ref argument ARGS, appears to be in named format or not.  If it is 
# named then this method will return a hash ref containing the raw named 
# version (true); otherwise, it returns undef (false).  By default, ARGS is 
# known to be named if its first element is a hash ref, and assumed to be 
# positional if the count of arguments is odd.  If neither of those two 
# conditions are true then we have an even argument count and we are in doubt 
# of whether they are named or not.  The argument GUESS_NAMED says what to do 
# in that case; if it is true then we guess named and if it is false then we 
# guess positional.  If the argument USE_DASHES is true then we check the first 
# element in ARGS to see if it begins with a dash, "-", and if it does then we 
# assume that ARGS is named regardless of the count of elements.
# When the first element of ARGS is a hash ref, any other elements of ARGS are 
# also returned as "remaining" values, if they exist, after the hash ref.
# So you can call this like "($rh_named, @rem) = _args_are_named()".

sub _args_are_named {
	my ($self, $ra_args, $use_dashes, $guess_named) = @_;
	if( ref( $ra_args->[0] ) eq 'HASH' ) {
		return( @{$ra_args} );  # literal hash in first return elem
	} elsif( $use_dashes and substr( $ra_args->[0], 0, 1 ) eq '-' ) {
		return( { @{$ra_args} } );  # first element starts with "-"
	} elsif( @{$ra_args} % 2 ) {
		return( undef );  # odd # elements
	} else {
		return( $guess_named ? { @{$ra_args} } : undef );  # even num elements
	}
}

# _posit_to_named( ARGS, POSIT_NAMES )
# This private method will take ARGS in positional format, as an array ref, and 
# return a named version as a hash ref.  POSIT_NAMES is an array ref that is 
# used as a translation table between the two formats.  The elements ot 
# POSIT_NAMES are the new names for arguments at corresponding element numbers 
# in ARGS.  We are checking array lengths below to avoid warnings.

sub _posit_to_named {
	my ($self, $ra_args, $ra_pn) = @_;
	my ($ind_to_use) = sort ($#{$ra_pn}, $#{$ra_args});  # largest common index
	my %args_out = map { ( $ra_pn->[$_] => $ra_args->[$_] ) } (0..$ind_to_use);
	delete( $args_out{''} );  # remove unwanted elements
	return( \%args_out );
}

# _named_to_posit( ARGS, POSIT_NAMES )
# This private method will take ARGS in named format, as an hash ref, and return 
# a positional version as an array ref.  POSIT_NAMES is an array ref that is 
# used as a translation table between the two formats.  The elements ot 
# POSIT_NAMES are matched with keys in ARGS and the values of ARGS are output in 
# corresponding element numbers with POSIT_NAMES.

sub _named_to_posit {
	my ($self, $rh_args, $ra_pn) = @_;
	return( [ map { $rh_args->{$ra_pn->[$_]} } (0..$#{$ra_pn}) ] );
}

# _rename_named_args( ARGS, RENAME[, USE_DASHES[, LOWERCASE]] )
# This private method will take a hash ref as input via ARGS and copy it into a 
# new hash ref, which it returns.  During the copy, hash keys may be renamed in 
# several ways.  If LOWERCASE is true then the key is lowercase.  If USE_DASHES 
# is true then the leading character is removed if it is a dash, "-".  Finally, 
# the keys are looked up using the hash ref RENAME, and if there are matching 
# keys then the associated RENAME values are substituted.  If any key is 
# renamed to the empty string or undef then it is deleted.

sub _rename_named_args {
	my ($self, $rh_args, $rh_rename, $use_dashes, $lowercase) = @_;
	my %args_out = ();
	foreach my $key (sort keys %{$rh_args}) {
		my $value = $rh_args->{$key};
		$lowercase and $key = lc( $key );  # change to lowercase
		$use_dashes and substr( $key, 0, 1 ) eq '-' and 
			$key = substr( $key, 1 );  # remove leading "-"
		exists( $rh_rename->{$key} ) and $key = $rh_rename->{$key};  # chg alias
		$args_out{$key} = $value;
	}
	delete( $args_out{''} );  # remove unwanted elements
	return( \%args_out );
}

######################################################################

1;
__END__

=head1 AUTHOR

Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.  However, I do request that this copyright information and
credits remain attached to the file.  If you modify this module and
redistribute a changed version then please attach a note listing the
modifications.  This module is available "as-is" and the author can not be held
accountable for any problems resulting from its use.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own products or services then I would appreciate
(but not require) it if you send me the website url for said product or
service, so I know who you are.  Also, if you make non-proprietary changes to
the module because it doesn't work the way you need, and you are willing to
make these freely available, then please send me a copy so that I can roll
desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 CREDITS

Thanks to Laurie Shammel <lshammel@imt.net> for alerting me to some warnings 
that occur when converting a positional SOURCE to named where SOURCE has more 
array elements than NAMES.  While the correct result was returned all along, 
warnings can be annoying in this context.

=head1 SEE ALSO

perl(1), HTML::FormTemplate, Class::ParmList, Class::NamedParms, 
Getargs::Long, Params::Validate, CGI.

=cut
