# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

	# See Class::Maker for the packages

1;

__END__

=pod

=head1 SYNOPSIS

	{
		package Human::Role;

		Class::Maker::class
		{
			public =>
			{
				string => [qw( name desc )],
			},

			default =>
			{
				name => 'Role Name',

				desc => 'Role Descrition',
			},
		};

		sub anew : method
		{
			my $this = shift;

			return $this->new( name => $_[0] );
		}

	}

	{
		package Human::Role::Simple;

		@ISA = qw(Human::Role);

		sub new : method
		{
			my $this = shift;

			return $this->SUPER::new( name => $_[0] );
		}
	}

=head1 reflect

	Now a Class::Maker::Reflex object is returned (btw it is not created with Class::Maker):

		->{parents} = href with all ->{isa} classes reflexes (only if $DEEP is true).

		->{methods} = aref of ': method' functions of that package

		->{def} = the original class definition (undef if not created with Class::Maker)

		->{isa} = the actual @ISA value of the class package

		->{name} = name of the reflected class

=cut

=head1 find

Returns a snapshot aref to all instances (objects) of a class in a given package.

CAVEAT: It only finds instance variables not created with 'my'

Example:

		# finds all objects which are return true for ->isa( 'Human' ) in the 'main' package

	my $aref_humans = Class::Maker::Reflection::find( 'main' => 'Human' );

Comment:

This function is extremly inefficient, because it is traversing the complete symbol table instead of
maintaning a registry of the classes/objects. This seems the lessest error-prone approach, and the time
will show if there will be need for efficients.

=cut

=head1 Function B<classes>

	classes( fakultativ $scalref_mainpackage, [ $package ], .. );

 Purpose

	Traverses the symbol table and find "reflectable" classes.	Returns a list of hash references containing:

		"package_identifier" => $HREF_CLASS_HASH

	Meaning it gets references to the reflection of the class.

	{ 'main::MyClass' => $href_myclass }, { 'main::YourClass' => $href_yclass }, ..

=cut
