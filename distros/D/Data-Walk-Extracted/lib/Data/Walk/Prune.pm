package Data::Walk::Prune;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.28.0');
###InternalExtracteDPrunE	warn "You uncovered internal logging statements for Data::Walk::Prune-$VERSION";
###InternalExtracteDPrunE	use Data::Dumper;
use 5.010;
use utf8;
use Moose::Role;
requires qw(
	_get_had_secondary		_process_the_data			_dispatch_method
);
use MooseX::Types::Moose qw( ArrayRef Bool Item HashRef );

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

$| = 1;
my $prune_keys = {
    slice_ref => 'primary_ref',
    tree_ref => 'secondary_ref',
};

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my $prune_dispatch = {######<-----------------------------------------  ADD New types here
    HASH	=> \&_remove_hash_key,
    ARRAY 	=> \&_clear_array_position,
};

my $remember_dispatch = {######<--------------------------------------  ADD New types here
	HASH	=> \&_build_hash_cut,
    ARRAY	=> \&_build_array_cut,
};

my 	$prune_decision_dispatch = {######<-------------------------------  ADD New types here
		HASH	=> sub{ scalar( keys %{$_[1]->{primary_ref}} ) == 0 },
		ARRAY	=> sub{ scalar( @{$_[1]->{primary_ref}} ) == 0 },
		SCALAR	=> sub { return 0 },#No cut signal for SCALARS
		UNDEF	=> sub { return 0 },#No cut signal for UNDEF refs
		name	=> '- Prune - prune_decision_dispatch',
		###### Receives: the current $passed_ref
		###### Returns: pass | fail (Boolean style)
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'prune_memory'	=>(
    isa     	=> Bool,
    writer  	=> 'set_prune_memory',
	reader		=> 'get_prune_memory',
	predicate	=> 'has_prune_memory',
	clearer		=> 'clear_prune_memory',
);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub prune_data{#Used to convert names
    ##### <where> - Passed input  : @_
    my( $self, @args ) = @_;
    ###InternalExtracteDPrunE	warn "Made it to prune_data with input:" . Dumper( @args );
    my  $passed_ref = ( @args == 1 and is_HashRef( $args[0] ) ) ? $args[0] : { @args } ;
    ###InternalExtracteDPrunE	warn "Resolved hashref:" . Dumper( $passed_ref );
    @$passed_ref{ 'before_method', 'after_method' } = # Hash slice
        ( '_prune_before_method', '_prune_after_method' );
	$self->_clear_pruned_positions;
    ###InternalExtracteDPrunE	warn "Start recursive parsing with:" . Dumper( $passed_ref );
    $passed_ref = $self->_process_the_data( $passed_ref, $prune_keys );
    ###InternalExtracteDPrunE	warn "End recursive parsing with:" . Dumper( $passed_ref );
    return $passed_ref->{tree_ref};
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has '_prune_list' =>(
    traits		=> ['Array'],
    isa			=> ArrayRef[ArrayRef[Item]],
    handles => {
        _add_prune_item		=> 'push',
        _next_prune_item	=> 'shift',
    },
    clearer		=> '_clear_prune_list',
    predicate	=> '_has_prune_list',
);

has '_pruned_positions' =>(
    traits  		=> ['Array'],
    isa     		=> ArrayRef[HashRef],
    handles => {
        _remember_prune_item	=> 'push',
		number_of_cuts			=> 'count',
    },
    clearer		=> '_clear_pruned_positions',
    predicate	=> 'has_pruned_positions',
	reader		=> 'get_pruned_positions',
);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _prune_before_method{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrunE	warn "reached _prune_before_method with input" . Dumper( $passed_ref );
    if( !exists $passed_ref->{secondary_ref} ){
        ###InternalExtracteDPrunE	warn "no matching tree_ref element so 'skip'ing the slice node ...";
        $passed_ref->{skip} = 'YES';
    }
	###InternalExtracteDPrunE	warn "skip state: $passed_ref->{skip}";
    return $passed_ref;
}

sub _prune_after_method{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrunE	warn "reached _prune_after_method with input" . Dumper( $passed_ref );
	###InternalExtracteDPrunE	warn "Running the cut test with slice state: $self->_has_prune_list";
	if( $passed_ref->{skip} eq 'NO') {
		###InternalExtracteDPrunE	warn "The node was not skipped ...";
		if( $self->_dispatch_method(
				$prune_decision_dispatch,
				$passed_ref->{primary_type},
				$passed_ref,				) ){
			###InternalExtracteDPrunE	warn "adding prune item:" . Dumper( $passed_ref->{branch_ref}->[-1] );
			$self->_add_prune_item( $passed_ref->{branch_ref}->[-1] );
			###InternalExtracteDPrunE	warn "go back up and prune ...";
		}elsif( $self->_has_prune_list ){
			my  $tree_ref   =
				( exists $passed_ref->{secondary_ref} ) ?
					$passed_ref->{secondary_ref} : undef ;
			###InternalExtracteDPrunE	warn "tree_ref:" . Dumper( $tree_ref );
			while( my $item_ref = $self->_next_prune_item ){
				###InternalExtracteDPrunE	warn "item ref:" . Dumper( $item_ref );
				$tree_ref = $self->_prune_the_item( $item_ref, $tree_ref );
				###InternalExtracteDPrunE	warn "tree ref:" . Dumper( $tree_ref );
				if(	$self->has_prune_memory and
					$self->get_prune_memory 	){
					###InternalExtracteDPrunE	warn "building the rememberance ref ...";
					my $rememberance_ref = $self->_dispatch_method(
							$remember_dispatch,
							$item_ref->[0],
							$item_ref,
					);
					###InternalExtracteDPrunE	warn "current branch ref is:" . Dumper( $passed_ref->{branch_ref} );
					$rememberance_ref = $self->_build_branch(
						$rememberance_ref,
						@{ $passed_ref->{branch_ref}},
					);
					###InternalExtracteDPrunE	warn "rememberance ref:" . Dumper( $rememberance_ref );
					$self->_remember_prune_item( $rememberance_ref );
					###InternalExtracteDPrunE	warn "prune memory:" . Dumper( $self->get_pruned_positions );
				}
			}
			$passed_ref->{secondary_ref} = $tree_ref;
			###InternalExtracteDPrunE	warn "finished pruning at this node - clear the prune list ...";
			$self->_clear_prune_list;
		}
    }
    return $passed_ref;
}

sub _prune_the_item{
    my ( $self, $item_ref, $tree_ref ) = @_;
    ###InternalExtracteDPrunE	warn "reached _prune_the_item with item:" . Dumper( $item_ref );
    ###InternalExtracteDPrunE	warn ".. and tree ref:" . Dumper( $tree_ref );
	$tree_ref = $self->_dispatch_method(
		$prune_dispatch,
		$item_ref->[0],
		$item_ref,
		$tree_ref,
	);
    ###InternalExtracteDPrunE	warn "cut completed succesfully";
    return $tree_ref;
}

sub _remove_hash_key{
    my ( $self, $item_ref, $tree_ref ) = @_;
    ###InternalExtracteDPrunE	warn "reached _remove_hash_key with item:" . Dumper( $item_ref );
    ###InternalExtracteDPrunE	warn ".. and tree ref:" . Dumper( $tree_ref );
    delete $tree_ref->{$item_ref->[1]};
    ###InternalExtracteDPrunE	warn "New tree ref:" . Dumper( $tree_ref );
    return $tree_ref;
}

sub _clear_array_position{
    my ( $self, $item_ref, $tree_ref ) = @_;
    ###InternalExtracteDPrunE	warn "reached _clear_array_position with item:" . Dumper( $item_ref );
    ###InternalExtracteDPrunE	warn ".. and tree ref:" . Dumper( $tree_ref );
    if( $self->change_array_size ){
        ###InternalExtracteDPrunE	warn "splicing out position:" . Dumper( $item_ref->[2] );
        splice( @$tree_ref, $item_ref->[2]);
    }else{
        ###InternalExtracteDPrunE	warn "Setting undef at position:" . Dumper( $item_ref->[2] );
        $tree_ref->[$item_ref->[2]] = undef;
    }
    ###InternalExtracteDPrunE	warn "New tree ref:" . Dumper( $tree_ref );
    return $tree_ref;
}

sub _build_hash_cut{
    my ( $self, $item_ref ) = @_;
    ###InternalExtracteDPrunE	warn "reached _build_hash_cut with item:" . Dumper( $item_ref );
	return { $item_ref->[1] => {} };
}

sub _build_array_cut{
    my ( $self, $item_ref ) = @_;
    ###InternalExtracteDPrunE	warn "reached _build_array_cut with item:" . Dumper( $item_ref );
	my  $array_ref;
	$array_ref->[$item_ref->[2]] = [];
    ###InternalExtracteDPrunE	warn "New item ref:" . Dumper( $item_ref );
	return $item_ref;
}

#########1 Phinish Strong     3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 Main POD starts    3#########4#########5#########6#########7#########8#########9


__END__

=head1 NAME

Data::Walk::Prune - A way to say what should be removed

=head1 SYNOPSIS

	#!perl
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Data::Walk::Extracted;
	use Data::Walk::Prune;
	use Data::Walk::Print;

	my  $edward_scissorhands = build_instance( 
			package => 'Edward::Scissorhands',
			superclasses =>['Data::Walk::Extracted'],
			roles =>[qw( Data::Walk::Print Data::Walk::Prune )],
			change_array_size => 1, #Default
		);
	my  $firstref = {
			Helping => [
				'Somelevel',
				{
					MyKey => {
						MiddleKey => {
							LowerKey1 => 'low_value1',
							LowerKey2 => {
								BottomKey1 => 'bvalue1',
								BottomKey2 => 'bvalue2',
							},
						},
					},
				},
			],
		};
	my	$result = $edward_scissorhands->prune_data(
			tree_ref    => $firstref, 
			slice_ref   => {
				Helping => [
					undef,
					{
						MyKey => {
							MiddleKey => {
								LowerKey1 => {},
							},
						},
					},
				],
			},
		);
	$edward_scissorhands->print_data( $result );

	######################################################################################
	#     Output of SYNOPSIS
	# 01 {
	# 02 	Helping => [
	# 03 		'Somelevel',
	# 04 		{
	# 05 			MyKey => {
	# 06 				MiddleKey => {
	# 07 					LowerKey2 => {
	# 08 						BottomKey1 => 'bvalue1',
	# 09 						BottomKey2 => 'bvalue2',
	# 10 					},
	# 12 				},
	# 13 			},
	# 14 		},
	# 15 	],
	# 16 },
	######################################################################################

=head1 DESCRIPTION

This L<Moose::Role|https://metacpan.org/module/Moose::Manual::Roles> implements the method
L<prune_data|/prune_data( %args )>.  It takes a $tree_ref and a $slice_ref and uses
L<Data::Walk::Extracted|https://metacpan.org/module/Data::Walk::Extracted>.  To remove
portions of the 'tree_ref' defined by an empty hash ref (no keys) or an empty array ref
(no positions) at all required points of the 'slice_ref'.  The 'slice_ref' must match the
tree ref up to each slice point.  If the slice points are on a branch of the slice_ref that
does not exist on the tree_ref then no cut takes place.

=head2 USE

This is a L<Moose::Role|https://metacpan.org/module/Moose::Manual::Roles> specifically
designed to be used with L<Data::Walk::Extracted
|https://metacpan.org/module/Data::Walk::Extracted#Extending-Data::Walk::Extracted>.
It can be combined traditionaly to the ~::Extracted class using L<Moose
|https://metacpan.org/module/Moose::Manual::Roles> methods or for information on how to join
this role to Data::Walk::Extracted at run time see L<Moose::Util
|https://metacpan.org/module/Moose::Util> or L<MooseX::ShortCut::BuildInstance
|https://metacpan.org/module/MooseX::ShortCut::BuildInstance> for more information.

=head1 Attributes

Data passed to -E<gt>new when creating an instance.  For modification of these attributes
see L<Methods|/Methods>.  The -E<gt>new function will either accept fat comma lists or a
complete hash ref that has the possible attributes as the top keys.  Additionally
some attributes that have all the following methods; get_$attribute, set_$attribute,
has_$attribute, and clear_$attribute, can be passed to L<prune_data
|/prune_data( %args )> and will be adjusted for just the run of that
method call.  These are called 'one shot' attributes.  The class and each role (where
applicable) in this package have a list of L<supported one shot attributes
|/Supported one shot attributes>.

=head2 prune_memory

=over

B<Definition:> When running a prune operation any branch called on the pruner
that does not exist in the tree will not be used.  This attribute turns on tracking
of the actual cuts made and stores them for review after the method is complete.
This is a way to know if the cut was actually implemented.

B<Default> undefined

B<Range> 1 = remember the cuts | 0 = don't remember

=back

=head2 (see also)

L<Data::Walk::Extracted|https://metacpan.org/module/Data::Walk::Extracted#Attributes>
- Attributes

=head1 Methods

=head2 prune_data( %args )

=over

B<Definition:> This is a method used to remove targeted parts of a data reference.

B<Accepts:> a hash ref with the keys 'slice_ref' and 'tree_ref' (both required).
The slice ref can contain more than one 'slice' location in the data reference.

=over

B<tree_ref> This is the primary data ref that will be manipulated and returned changed.

B<slice_ref> This is a data ref that will be used to prune the 'tree_ref'.  In general
the slice_ref should match the tree_ref for positions that should remain unchanged.
Where the tree_ref should be trimmed insert either an empty array ref or an empty hash
ref.  If this position represents a value in a hash key => value pair then the hash
key is deleted.  If this position represents a value in an array then the position is
deleted/cleared depending on the attribute L<change_array_size
|https://metacpan.org/module/Data::Walk::Extracted#change_array_size> in
Data::Walk::Extracted.  If the slice ref diverges from the tree ref then no action is
taken past the divergence, even if there is a mandated slice. (no auto vivication occurs!)

B<[attribute name]> - attribute names are accepted with temporary attribute settings.
These settings are temporarily set for a single "prune_data" call and then the original
attribute values are restored.  For this to work the the attribute must meet the
L<necessary criteria|/Attributes>.

=back

B<Example>

	$pruned_tree_ref = $self->prune_data(
		tree_ref => $tree_data,
		slice_ref => $slice_data,
		prune_memory => 0,
	);

B<Returns:> The $tree_ref with any changes

=back

=head2 set_prune_memory( $Bool )

=over

B<Definition:> This will change the setting of the L<prune_memory|/prune_memory>
attribute.

B<Accepts:> 1 = remember | 0 = no memory

B<Returns:> nothing

=back

=head2 get_prune_memory

=over

B<Definition:> This will return the current setting of the L<prune_memory|/prune_memory>
attribute.

B<Accepts:> nothing

B<Returns:> A $Bool value for the current state

=back

=head2 has_prune_memory

=over

B<Definition:> This will indicate if the L<prune_memory|/prune_memory> attribute is set

B<Accepts:> nothing

B<Returns:> A $Bool value 1 = defined, 0 = not defined

=back

=head2 clear_prune_memory

=over

B<Definition:> This will clear the L<prune_memory|/prune_memory> attribute value
(Not the actual prune memory)

B<Accepts:> nothing

B<Returns:> A $Bool value 1 = defined, 0 = not defined

=back

=head2 has_pruned_positions

=over

B<Definition:> This answers if any pruned positions were stored

B<Accepts:> nothing

B<Returns:> A $Bool value 1 = pruned cuts are stored, 0 = no stored cuts

=back

=head2 get_pruned_positions

=over

B<Definition:> This returns an array ref of stored cuts

B<Accepts:> nothing

B<Returns:> an ArrayRef - although the cuts were defined in one data ref
this will return one data ref per cut.  Each ref will go to the root of the
original data ref.

=back

=head2 number_of_cuts

=over

B<Definition:> This returns the number of cuts actually made

B<Accepts:> nothing

B<Returns:> an integer

=back

=head1 Caveat utilitor

=head2 deep cloning

Because this uses Data::Walk::Extracted the final $tree_ref is deep cloned where
the $slice_ref passed through.

=head2 Supported Node types

=over

=item ARRAY

=item HASH

=item SCALAR

=item UNDEF

=back

=head2 Supported one shot attributes

L<explanation|/Attributes>

=over

=item prune_memory

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

B<2.> Support pruning through Objects / Instances nodes

B<3.> Support pruning through CodeRef nodes

B<4.> Support pruning through REF nodes

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

This software is copyrighted (c) 2013 by Jed Lund.

=head1 Dependencies

L<version|https://metacpan.org/module/version>

L<Moose::Role|https://metacpan.org/module/Moose::Role>

=over

B<requires>

=over

=item _process_the_data

=item _dispatch_method

=item _build_branch

=back

=back

L<MooseX::Types::Moose|https://metacpan.org/module/MooseX::Types::Moose>

L<Data::Walk::Extracted|https://metacpan.org/module/Data::Walk::Extracted>

L<Data::Walk::Extracted::Dispatch|https://metacpan.org/module/Data::Walk::Extracted::Dispatch>

=head1 SEE ALSO

=over

L<Smart::Comments|https://metacpan.org/module/Smart::Comments> - is used if the -ENV option is set

L<Data::Walk|https://metacpan.org/module/Data::Walk>

L<Data::Walker|https://metacpan.org/module/Data::Walker>

L<Data::ModeMerge|https://metacpan.org/module/Data::ModeMerge>

L<Data::Walk::Print|https://metacpan.org/module/Data::Walk::Print> - available Data::Walk::Extracted Role

L<Data::Walk::Graft|https://metacpan.org/module/Data::Walk::Graft> - available Data::Walk::Extracted Role

L<Data::Walk::Clone|https://metacpan.org/module/Data::Walk::Clone> - available Data::Walk::Extracted Role

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9
