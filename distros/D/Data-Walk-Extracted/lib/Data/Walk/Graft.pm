package Data::Walk::Graft;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.28.0');
###InternalExtracteDGrafT	warn "You uncovered internal logging statements for Data::Walk::Graft-$VERSION";
###InternalExtracteDGrafT	use Data::Dumper;
use 5.010;
use utf8;
use Moose::Role;
requires qw(
	_get_had_secondary		_process_the_data			_dispatch_method
);
use MooseX::Types::Moose qw( Bool ArrayRef HashRef );
use Carp qw( cluck );

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

$| = 1;
my $graft_keys = {
    scion_ref => 'primary_ref',
    tree_ref => 'secondary_ref',
};

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'graft_memory' =>(
    isa			=> Bool,
    writer		=> 'set_graft_memory',
	reader		=> 'get_graft_memory',
	predicate	=> 'has_graft_memory',
	clearer		=> 'clear_graft_memory',
);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub graft_data{#Used to convert names
    my ( $self, @args ) = @_;
    ###InternalExtracteDGrafT	warn "Made it to graft_data with input:" . Dumper( @args );
    my  $passed_ref = ( @args == 1 and is_HashRef( $args[0] ) ) ? $args[0] : { @args } ;
    ###InternalExtracteDGrafT	warn "reconciled hashref:" . Dumper( $passed_ref );
	if( $passed_ref->{scion_ref} ){
		$passed_ref->{before_method} = '_graft_before_method';
		$self->_clear_grafted_positions;
		###InternalExtracteDGrafT	warn "Start recursive parsing with:" . Dumper( $passed_ref );
		$passed_ref = $self->_process_the_data( $passed_ref, $graft_keys );
	}else{
		cluck "No scion was provided to graft";
	}
	###InternalExtracteDGrafT	warn "End recursive parsing with:" . Dumper( $passed_ref );
	return $passed_ref->{tree_ref};
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has '_grafted_positions' =>(
    traits  	=> ['Array'],
    isa     	=> ArrayRef[HashRef],
    handles => {
        _remember_graft_item	=> 'push',
		number_of_scions		=> 'count',
    },
    clearer		=> '_clear_grafted_positions',
    predicate   => 'has_grafted_positions',
	reader		=> 'get_grafted_positions',
);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _graft_before_method{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDGrafT	warn "reached _graft_before_method with input:" . Dumper( $passed_ref );
	if(	$passed_ref->{primary_type} eq 'SCALAR' and
		$passed_ref->{primary_ref} eq 'IGNORE' ){
		###InternalExtracteDGrafT	warn "nothing to see here! IGNOREing ...";
		$passed_ref->{skip} = 'YES';
    }elsif( $self->_check_graft_state( $passed_ref ) ){
        ###InternalExtracteDGrafT	warn "Found a difference - adding new element ...";
		###InternalExtracteDGrafT	warn "can deep clone: " . ( $self->can( 'deep_clone' ) );
		my 	$clone_value = ( $self->can( 'deep_clone' ) ) ?
				$self->deep_clone( $passed_ref->{primary_ref} ) :
				'CRAZY' ;#$passed_ref->{primary_ref} ;
		###InternalExtracteDGrafT	warn "clone value: $clone_value";
			$passed_ref->{secondary_ref} = $clone_value;
		if( $self->has_graft_memory ){
			###InternalExtracteDGrafT	warn "recording the most recent grafted scion ...";
			###InternalExtracteDGrafT	warn "current branch ref is:" . Dumper( $passed_ref->{branch_ref} );
			$self->_remember_graft_item(
				$self->_build_branch(
					$clone_value,
					( ( is_ArrayRef( $clone_value ) ) ? [] : {} ),
					@{$passed_ref->{branch_ref}},
				)
			);
			###InternalExtracteDGrafT	warn "graft memory:" . Dumper( $self->get_grafted_positions );
		}else{
			###InternalExtracteDGrafT	warn "forget this graft - whats done is done ...";
		}
        $passed_ref->{skip} = 'YES';
    }else{
        ###InternalExtracteDGrafT	warn "no action required - continue on";
    }
	###InternalExtracteDGrafT	warn "the current passed ref is:" . Dumper( $passed_ref );
    return $passed_ref;
}

sub _check_graft_state{
	my ( $self, $passed_ref ) = @_;
	my	$answer = 0;
	###InternalExtracteDGrafT	warn "reached _check_graft_state with passed_ref:" . Dumper( $passed_ref );
	if( $passed_ref->{match} eq 'NO' ){
		###InternalExtracteDGrafT	warn "found possible difference ...";
		if(	( $passed_ref->{primary_type} eq 'SCALAR' ) and
			$passed_ref->{primary_ref} =~ /IGNORE/i			){
			###InternalExtracteDGrafT	warn "IGNORE case found ...";
		}else{
			###InternalExtracteDGrafT	warn "grafting now ...";
			$answer = 1;
		}
	}
	###InternalExtracteDGrafT	warn "the current answer is: $answer";
	return $answer;
}

#########1 Phinish Strong     3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 Main POD starts    3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Data::Walk::Graft - A way to say what should be added

=head1 SYNOPSIS

	#!perl
	use Data::Walk::Extracted;
	use Data::Walk::Graft;
	use Data::Walk::Print;
	use MooseX::ShortCut::BuildInstance qw( build_instance );

	my  $gardener = build_instance( 
			package => 'Jordan::Porter',
			superclasses =>['Data::Walk::Extracted'],
			roles =>[qw( Data::Walk::Graft Data::Walk::Clone Data::Walk::Print )],
			sorted_nodes =>{
				HASH => 1,
			},# For demonstration consistency
			#Until Data::Walk::Extracted and ::Graft support these types
			#(watch Data-Walk-Extracted on github)
			skipped_nodes =>{ 
				OBJECT => 1,
				CODEREF => 1,
			},
			graft_memory => 1,
		);
	my  $tree_ref = {
			Helping =>{
				KeyTwo => 'A New Value',
				KeyThree => 'Another Value',
				OtherKey => 'Something',
			},
			MyArray =>[
				'ValueOne',
				'ValueTwo',
				'ValueThree',
			],
		};
	$gardener->graft_data(
		scion_ref =>{
			Helping =>{
				OtherKey => 'Otherthing',
			},
			MyArray =>[
				'IGNORE',
				{
					What => 'Chicken_Butt!',
				},
				'IGNORE',
				'IGNORE',
				'ValueFive',
			],
		},
		tree_ref  => $tree_ref,
	);
	$gardener->print_data( $tree_ref );
	print "Now a list of -" . $gardener->number_of_scions . "- grafted positions\n";
	$gardener->print_data( $gardener->get_grafted_positions );

	#####################################################################################
	#     Output of SYNOPSIS
	# 01 {
	# 02 	Helping => {
	# 03 		KeyThree => 'Another Value',
	# 04 		KeyTwo => 'A New Value',
	# 05 		OtherKey => 'Otherthing',
	# 06 	},
	# 07 	MyArray => [
	# 08 		'ValueOne',
	# 09 		{
	# 10 			What => 'Chicken_Butt!',
	# 11 		},
	# 12 		'ValueThree',
	# 13 		undef,
	# 14 		'ValueFive',
	# 15 	],
	# 16 },
	# 17 Now a list of -3- grafted positions
	# 18 [
	# 19 	{
	# 20 		Helping => {
	# 21 			OtherKey => 'Otherthing',
	# 22 		},
	# 23 	},
	# 24 	{
	# 25 		MyArray => [
	# 26 			undef,
	# 27 			{
	# 28 				What => 'Chicken_Butt!',
	# 29 			},
	# 30 		],
	# 31 	},
	# 32 	{
	# 33 		MyArray => [
	# 34 			undef,
	# 35 			undef,
	# 36 			undef,
	# 37 			undef,
	# 38 			'ValueFive',
	# 39 		],
	# 40 	},
	# 41 ],
	#####################################################################################

=head1 DESCRIPTION

This L<Moose::Role> contains methods for adding a new branch ( or three ) to an existing 
data ref.  The method used to do this is L<graft_data|/graft_data( %args|$arg_ref )> using
L<Data::Walk::Extracted>.  Grafting is accomplished by sending a $scion_ref that has 
additions that need to be made to a $tree_ref.  Anything in the scion ref that does not 
exist in the tree ref is grafted to the tree ref.  I<Anytime the scion_ref is different 
from the tree_ref the scion_ref branch will replace the tree_ref branch!>

=head2 USE

This is a L<Moose::Role|https://metacpan.org/module/Moose::Manual::Roles> specifically
designed to be used with L<Data::Walk::Extracted
|Data::Walk::Extracted/Extending Data::Walk::Extracted>.  It can be combined traditionaly 
to the ~::Extracted class using L<Moose> or at run time. see L<Moose::Util> and 
L<MooseX::ShortCut::BuildInstance> for more information.

=head2 Deep cloning the graft

In general grafted data refs are subject to external modification by changing the data
in that ref from another location of the code.  This module assumes that you don't want
to do that!  As a consequence it checks to see if a 'deep_clone' method has been provided to
the class that consumes this role.  If so it calls that method on the data ref to be
grafted.  One possiblity is to add the Role L<Data::Walk::Clone> to your object so that 
a deep_clone method is automatically available (all compatability testing complete).  If 
you choose to add your own deep_clone method it will be called like this;

	my $clone_value = ( $self->can( 'deep_clone' ) ) ?
				$self->deep_clone( $scion_ref ) : $scion_ref ;

Where $self is the active object instance.

=head2 Grafting unsupported node types

If you want to add data from another ref to a current ref and the add ref contains nodes
that are not supported then you need to L<skip|Data::Walk::Extracted/skipped_nodes> those 
nodes in the cloning process.

=head1 Attributes

Data passed to -E<gt>new when creating an instance.  For modification of these attributes
see L<Methods|/Methods>.  The -E<gt>new function will either accept fat comma lists or a
complete hash ref that has the possible attributes as the top keys.  Additionally
some attributes that have all the following methods; get_$attribute, set_$attribute,
has_$attribute, and clear_$attribute, can be passed to L<graft_data
|/graft_data( %args|$arg_ref )> and will be adjusted for just the run of that
method call.  These are called 'one shot' attributes.  The class and each role (where
applicable) in this package have a list of L<supported one shot attributes
|/Supported one shot attributes>.

=head2 graft_memory

=over

B<Definition:> When running a 'graft_data' operation any branch of the $scion_ref
that does not terminate past the end of the tree ref or differ from the tree_ref
will not be used.  This attribute turns on tracking of the actual grafts made and
stores them for review after the method is complete.  This is a way to know if a graft
was actually implemented.  The potentially awkward wording of the associated methods
is done to make this an eligible 'one shot' attribute.

B<Default> undefined = don't remember the grafts

B<Range> 1 = remember the grafts | 0 = don't remember

=back

=head2 (see also)

L<Data::Walk::Extracted|https://metacpan.org/module/Data::Walk::Extracted#Attributes>
Attributes

=head1 Methods

=head2 graft_data( %args|$arg_ref )

=over

B<Definition:> This is a method to add defined elements to targeted parts of a data
reference.

B<Accepts:> a hash ref with the keys 'scion_ref' and 'tree_ref'.  The scion
ref can contain more than one place that will be grafted to the tree data.

=over

B<tree_ref> This is the primary data ref that will be manipulated and returned
changed.  If an empty 'tree_ref' is passed then the 'scion_ref' is returned in it's
entirety.

B<scion_ref> This is a data ref that will be used to graft to the 'tree_ref'.
For the scion ref to work it must contain the parts of the tree ref below the new
scions as well as the scion itself.  During data walking when a difference is found
graft_data will attempt to clone the remaining untraveled portion of the 'scion_ref'
and then graft the result to the 'tree_ref' at that point.  Any portion of the tree
ref that differs from the scion ref at that point will be replaced.  If L<graft_memory
|/graft_memory> is on then a full recording of the graft with a map to the data root
will be saved in the object.  The word 'IGNORE' can be used in either an array position
or the value for a key in a hash ref.  This tells the program to ignore differences (in
depth) past that point.  For example if you wish to change the third element of an array
node then placing 'IGNORE' in the first two positions will cause 'graft_data' to skip the
analysis of the first two branches.  This saves replicating deep references in the
scion_ref while also avoiding a defacto 'prune' operation.  If an array position in the
scion_ref is set to 'IGNORE' in the 'scion_ref' but a graft is made below the node with
IGNORE then the grafted tree will contain 'IGNORE' in that element of the array (not
undef).  Any positions that exist in the tree_ref that do not exist in the scion_ref
will be ignored.  If an empty 'scion_ref' is sent then the code will L<cluck
|https://metacpan.org/module/Carp> and then return the 'tree_ref'.

B<[attribute name]> - attribute names are accepted with temporary attribute settings.
These settings are temporarily set for a single "graft_data" call and then the original
attribute values are restored.  For this to work the the attribute must meet the
L<necessary criteria|/Attributes>.

B<Example>

	$grafted_tree_ref = $self->graft_data(
		tree_ref => $tree_data,
		scion_ref => $addition_data,
		graft_memory => 0,
	);

=back

B<Returns:> The $tree_ref with any changes (possibly deep cloned)

=back

=head2 has_graft_memory

=over

B<Definition:> This will indicate if the attribute L<graft_memory|/graft_memory> is active

B<Accepts:> nothing

B<Returns:> 1 or 0

=back

=head2 set_graft_memory( $Bool )

=over

B<Definition:> This will set the L<graft_memory|/graft_memory> attribute

B<Accepts:> 1 or 0

B<Returns:> nothing

=back

=head2 get_graft_memory

=over

B<Definition:> This will return the current value for the L<graft_memory|/graft_memory> attribute.

B<Accepts:> nothing

B<Returns:> 1 or 0

=back

=head2 clear_graft_memory

=over

B<Definition:> This will clear the L<graft_memory|/graft_memory> attribute.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head2 number_of_scions

=over

B<Definition:> This will return the number of scion points grafted in the most recent
graft action if the L<graft_memory|/graft_memory> attribute is on.

B<Accepts:> nothing

B<Returns:> a positive integer

=back

=head2 has_grafted_positions

=over

B<Definition:> This will indicate if any grafted positions were saved.

B<Accepts:> nothing

B<Returns:> 1 or 0

=back

=head2 get_grafted_positions

=over

B<Definition:> This will return any saved grafted positions.

B<Accepts:> nothing

B<Returns:> an ARRAY ref of grafted positions.  This will include
one full data branch to the root for each position actually grafted.

=back

=head1 Caveat utilitor

=head2 Supported Node types

=over

=item ARRAY

=item HASH

=item SCALAR

=item Other node support

Support for Objects is partially implemented and as a consequence graft_data won't
immediatly die when asked to graft an object.  It will still die but on a dispatch table
call that indicates where there is missing object support not at the top of the node.

=back

=head2 Supported one shot attributes

L<explanation|/Attributes>

=over

=item graft_memory

=back

=head1 GLOBAL VARIABLES

=over

B<$ENV{Smart_Comments}>

The module uses L<Smart::Comments|https://metacpan.org/module/Smart::Comments> if the '-ENV'
option is set.  The 'use' is encapsulated in an if block triggered by an environmental
variable to comfort non-believers.  Setting the variable $ENV{Smart_Comments} in a BEGIN
block will load and turn on smart comment reporting.  There are three levels of 'Smartness'
available in this module '###',  '####', and '#####'.

=back

=head1 SUPPORT

=over

L<github Data-Walk-Extracted/issues|https://github.com/jandrew/Data-Walk-Extracted/issues>

=back

=head1 TODO

=over

B<1.> Add L<Log::Shiras|https://metacpan.org/module/Log::Shiras> debugging in exchange for
L<Smart::Comments|https://metacpan.org/module/Smart::Comments>

B<2.> Support grafting through class instance nodes (can - should you even do this?)

B<3.> Support grafting through CodeRef nodes (can - should you even do this?)

B<4.> Support grafting through REF nodes

B<5.> A possible depth check to ensure the scion is deeper than the tree_ref

=over

Implemented with an attribute that turns the feature on and off.  The goal
would be to eliminate unintentional swapping of small branches for large branches.
This feature has some overhead downside and may not be usefull so I'm not sure
if it makes sence yet.

=back

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2012, 2016 by Jed Lund.

=head1 Dependencies

=over

L<version>

L<Moose::Role>

=over

B<requires>

=over

=item _process_the_data

=item _dispatch_method

=item _build_branch

=back

=back

L<MooseX::Types::Moose>

L<Data::Walk::Extracted>

L<Data::Walk::Extracted::Dispatch>

L<Carp> - cluck

=back

=head1 SEE ALSO

=over

L<Log::Shiras::Unhide> - Can use to unhide '###InternalExtracteDGrafT' tags

L<Log::Shiras::TapWarn> - to manage the output of exposed '###InternalExtracteDGrafT' lines

L<Data::Dumper> - used in the '###InternalExtracteDGrafT' lines

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9
