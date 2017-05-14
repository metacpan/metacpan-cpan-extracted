
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself

use Carp qw(croak);

package Data::Type::Tied;

	use strict;

	use Exporter;

	use subs qw(typ untyp istyp);

	our %EXPORT_TAGS = 
        ( 
	  'all' => [qw(typ untyp istyp)],
	);
	
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	
	our @EXPORT = ();

	require Tie::Scalar;

	our @ISA = qw(Tie::StdScalar Exporter);

	our $behaviour = { exceptions => 1, warnings => 1 };

	our $_tie_registry = {};

	sub TIESCALAR
	{
		ref( $_[1] ) || die;

		$_[1]->isa( 'Data::Type::Object::Interface' ) || die;

		Data::Type::printfln "TIESC '%s'", ref( $_[1] ) if $Data::Type::DEBUG;

	    return bless [ undef, $_[1] ], $_[0];
	}

	sub STORE
	{
		my $this = shift;

		my $value = shift || undef;

		Data::Type::printfln "STORE '%s' into %s typed against '%s'", $value, $this, ref( $this->[1] ) if $Data::Type::DEBUG;

		Data::Type::try
		{
			Data::Type::valid( $value, $this->[1] );
		}
		catch Data::Type::Exception Data::Type::with
		{
			my $e = shift;

			warn sprintf "type conflict: '%s' is not %s at %s line %d\n", $value, $this->[1]->info, $e->file, $e->line if $Data::Type::Tied::behaviour->{warnings};

			$e->value = $value;

			throw $e if $Data::Type::Tied::behaviour->{exceptions};
		};

		$this->[0] = $value;
	}

	sub FETCH
	{
		my $this = shift;

		Data::Type::printfln "FETCH $this '%s' ", $this->[0] if $Data::Type::DEBUG;

		return $this->[0];
	}

	sub DESTROY
	{
		no warnings;

		undef ${ $_[0] };
	}	

	sub typ
	{
		my $type = shift;

		foreach my $xref ( @_ )
		{
			ref($xref) or ::croak( sprintf "typ: %s reference detected, instead of a reference.", lc( ref($xref) || 'no' ) );

			$type->isa( 'Data::Type::Object::Interface' ) or ::croak( sprintf "typed( ref, TYPE ) expects a Data::Type TYPE as second argument. You supplied '%s' which is not.", $type );

			tie $$xref, 'Data::Type::Tied', $type;

			$_tie_registry->{$xref+0} = ref( $type );
		}

		return 1;
	}

	sub istyp
	{
		no warnings;

		return $_tie_registry->{ $_[0]+0 } if exists $_tie_registry->{ $_[0]+0 };
	}

	sub untyp
	{
		untie $$_ for @_;

		delete $_tie_registry->{$_+0} for @_;
	}
1;

=head1 NAME

Data::Type::Tied - bind variables to datatypes

=head1 DESCRIPTION

=head1 SYNOPSIS

  use Data::Type::Tied qw(:all);

  try
  {
    typ STD::ENUM( qw(DNA RNA) ), \( my $a, my $b );

    print "a is typ'ed" if istyp( $a );

    $a = 'DNA';	# $alias only accepts 'DNA' or 'RNA'
    $a = 'RNA';
    $a = 'xNA'; # throws exception

    untyp( $alias );
  }
  catch Data::Type::Exception with
  {
    printf "Expected '%s' %s at %s line %s\n", $e->value, $e->type->info, $e->file, $e->line;
  };

=head1 TYPE BINDING

A tie-interface for Data::Type's is introduced via C<typ()>. Once a variable is typ'ed, C<valid()> is called in the background for every fetch on the value.

=head2 FUNCTIONS

=head3 typ( $type, @ref_variables )

Once an invalid value was assigned to a C<typ>'ed var an exception gets thrown, so place your code in a try+catch block to handle that correctly. To unglue a variable from its type use C<untyp()> (see below). C<@ref_variables> may be a list of references which suite to the $type used. Mostly its a reference to a scalar.

  try
  {
    typ EMAIL( 1 ), \( my $typed_var, my $typed_etc, .. );     # \( ... ) returns an array of references to its elements (perlreftut)

    $typed_var = 'john@doe.de'; # ok

    $typed_var = 'faked&fake.de'; # throws exception

  }
  ...

[Advanced Note] C<typ> adds all references to a central registry and then C<tie>s them to L<Data::Type::Tied>. So don't use C<tie> directly, otherwise the other functions are confused and wont work.

=head3 $scalar = istyp( $type )

C<typ>'d variables obscure themselfs, istyp() reveals $typed_var 's type. It does this via maintaining an internal registry of all typ'd varaibles.

	if( $what = istyp( $type ) )
	{
		print "variable \$type is tied to $what";
	}

[Note] It is a synonym to B<tied>. See L<perltie>.

=head3 untyp( $sref )

Takes the typ constrains from a variable (like untie).

	untyp( $sref );

[Note] It is nearly a synonym to L<untie>, but also updates the internal registry.

=head1 EXPORT

None per default.

=head2 FUNCTIONS

B<':all'> loads qw(typ untyp istyp).


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>


=cut

