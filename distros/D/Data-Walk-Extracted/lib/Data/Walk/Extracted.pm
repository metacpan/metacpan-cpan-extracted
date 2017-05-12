package Data::Walk::Extracted;
our $AUTHORITY = 'cpan:JANDREW';
use	version 0.77; our $VERSION = version->declare('v0.28.0');
###InternalExtracteD	warn "You uncovered internal logging statements for Data::Walk::Extracted-$VERSION";
###InternalExtracteD	use Data::Dumper;
use 5.010;
use utf8;
use	Moose 2.1803;
use	MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use	Class::Inspector;
use	Scalar::Util qw( reftype );
use	Carp qw( confess );
use	MooseX::Types::Moose qw(
		Str						ArrayRef			HashRef					Int
		Bool					CodeRef				Object
	);
use	lib '../../../lib';
use Data::Walk::Extracted::Dispatch;
use	Data::Walk::Extracted::Types qw( PosInt );
with 'Data::Walk::Extracted::Dispatch';

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

$| = 1;
my 	$wait;
my 	$data_key_tests = {
		required => [ qw(
			primary_ref
		) ],
		at_least_one => [ qw(
			before_method	
			after_method
		) ],
		all_possibilities => {
			secondary_ref => 1,
			branch_ref => 1,
		},
	};
# Adding elements from the first two keys to all ...
for my $key ( @{$data_key_tests->{required}}, @{$data_key_tests->{at_least_one}} ){
	$data_key_tests->{all_possibilities}->{$key} = 1;
}
my	$base_type_ref ={
		SCALAR => 1,
		UNDEF => 1,
	};

my	@data_key_list = qw(
		primary_ref			secondary_ref
	);

my	@lower_key_list = qw(
		primary_type		secondary_type		match				skip
	);

# This is also the order of type investigaiton testing
# This is the maximum list of types -but-
# if the types are also not listed in the appropriate dispatch
# tables, then it still won't parse
my 	$supported_type_list = [ qw(
		UNDEF SCALAR CODEREF OBJECT ARRAY HASH
	) ];######<------------------------------------------------------  ADD New types here

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my  $node_list_dispatch = {######<----------------------------------  ADD New types here
		name 		=> '- Extracted - node_list_dispatch',#Meta data
		HASH		=> sub{ [ keys %{$_[1]} ] },
		ARRAY		=> sub{
			my $list;
			map{ push @$list, 1 } @{$_[1]};
			return $list;
		},
		SCALAR		=> sub{ [ $_[1] ] },
		OBJECT		=> \&_get_object_list,
		###### Receives: a data reference or scalar
		###### Returns: an array reference of list items
	};

my 	$main_down_level_data ={
		###### Purpose: Used to build the generic elements of the next passed ref down
		###### Recieves: the upper ref value
		###### Returns: the lower ref value or undef
		name => '- Extracted - main down level data',
		DEFAULT => sub{ undef },
		before_method => sub{ return $_[1] },
		after_method => sub{ return $_[1] },
		branch_ref => \&_main_down_level_branch_ref,
	};

my	$down_level_tests_dispatch ={
		###### Purpose: Used to test the down level item elements
		###### Recieves: the lower ref
		###### Returns: the lower level test result
		name => '- Extracted - item down level data',
		primary_type => &_item_down_level_type( 'primary_ref' ),
		secondary_type => &_item_down_level_type( 'secondary_ref' ),
		match => \&_ref_matching,
		skip => \&_will_parse_next_ref,
	};

my  $sub_ref_dispatch = {######<------------------------------------  ADD New types here
		name	=> '- Extracted - sub_ref_dispatch',#Meta data
		HASH	=> sub{ return $_[1]->{$_[2]} },
		ARRAY	=> sub{ return $_[1]->[$_[3]] },
		SCALAR	=> sub{ return undef; },
		OBJECT	=> \&_get_object_element,
		###### Receives: a upper data reference, an item, and a position
		###### Returns: a lower array reference
	};

my 	$discover_type_dispatch = {######<-------------------------------  ADD New types here
		UNDEF		=> sub{ !$_[1] },
		SCALAR		=> sub{ is_Str( $_[1] ) },
		ARRAY		=> sub{ is_ArrayRef( $_[1] ) },
		HASH		=> sub{ is_HashRef( $_[1] ) },
		OBJECT		=> sub{ is_Object( $_[1] ) },
		CODEREF		=> sub{ is_CodeRef( $_[1] ) },
	};

my 	$secondary_match_dispatch = {######<-----------------------------  ADD New types here
		name	=> '- Extracted - secondary_match_dispatch',#Meta data
		DEFAULT	=> 	sub{ return 'YES' },
		SCALAR	=> sub{
			return ( $_[1]->{primary_ref} eq $_[1]->{secondary_ref} ) ?
				'YES' : 'NO' ;
		},
		OBJECT	=> sub{
			return ( ref( $_[1]->{primary_ref} ) eq ref( $_[1]->{secondary_ref} ) ) ?
				'YES' : 'NO' ;
		},
		###### Receives: the next $passed_ref, the item, and the item postion
		###### Returns: YES or NO
		######	Non-existent and non matching lower ref types should have already been eliminated
	};

my 	$up_ref_dispatch = {######<--------------------------------------  ADD New types here
		name 	=> '- Extracted - up_ref_dispatch',#Meta data
		HASH	=> \&_load_hash_up,
		ARRAY 	=> \&_load_array_up,
		SCALAR	=> sub{
			### <where> - made it to SCALAR ref upload ...
			$_[3]->{$_[1]} = $_[2]->[1];
			### <where> - returning: $_[3]
			return $_[3];
		},
		OBJECT	=> \&_load_object_up,
		###### Receives: the data ref key, the lower branch_ref element,
		######				and the upper and lower data refs
		###### Returns: the upper data ref
	};

my	$object_extraction_dispatch ={######<----------------------------  ADD New types here
		name	=> '- Extracted - object_extraction_dispatch',
		HASH	=> sub{ return {%{$_[1]}} },
		ARRAY	=> sub{ return [@{$_[1]}] },
		DEFAULT => sub{ return ${$_[1]} },
		###### Receives: an object reference
		###### Returns: a reference or string of the blessed data in the object
	};

my	$secondary_ref_exists_dispatch ={######<-------------------------  ADD New types here
		name => '- Extracted - secondary_ref_exists_dispatch',
		HASH => sub{
			### <where> - passed: @_
			exists $_[1]->{secondary_ref} and
			is_HashRef( $_[1]->{secondary_ref} ) and
			exists $_[1]->{secondary_ref}->{$_[2]}
		},
		ARRAY => sub{
			exists $_[1]->{secondary_ref} and
			is_ArrayRef( $_[1]->{secondary_ref} ) and
			exists $_[1]->{secondary_ref}->[$_[3]]
		},
		SCALAR => sub{ exists $_[1]->{secondary_ref} },
	###### Receives: the upper ref, the current list item, and the current position
	###### Returns: pass or fail (pass means continue)
	};

my  $reconstruction_dispatch = {######<-----------------------------  ADD New types here
		name 	=> 'reconstruction_dispatch',#Meta data
		HASH	=> \&_rebuild_hash_level,
		ARRAY 	=> \&_rebuild_array_level,
	};

#########1 import   2#########3#########4#########5#########6#########7#########8#########9

###InternalExtracteD	sub import {
###InternalExtracteD	    my( $class, @args ) = @_;
###InternalExtracteD			
###InternalExtracteD		# Handle versions (and other nonsense)
###InternalExtracteD		if( $args[0] and $args[0] =~ /^v?\d+\.?\d*/ ){# Version check since import highjacks the built-in
###InternalExtracteD			warn "Running version check on version: $args[0]";
###InternalExtracteD			my $result = $VERSION <=> version->parse( $args[0]);
###InternalExtracteD			warn "Tested against version -$VERSION- gives result: $result";
###InternalExtracteD			if( $result < 0 ){
###InternalExtracteD				confess "Version -$args[0]- requested for Log::Shiras::Switchboard " .
###InternalExtracteD						"- the installed version is: $VERSION";
###InternalExtracteD			}
###InternalExtracteD			shift @args;
###InternalExtracteD		}
###InternalExtracteD		if( @args ){
###InternalExtracteD			confess "Unknown flags passed to Log::Shiras::Switchboard: " . join( ' ', @args );
###InternalExtracteD		}
###InternalExtracteD		
###InternalExtracteD		# Still not sure why this is needed but Unhide wanders off otherwise
###InternalExtracteD		no warnings 'once';
###InternalExtracteD		if($Log::Shiras::Unhide::strip_match) {
###InternalExtracteD			eval 'use Log::Shiras::Unhide';
###InternalExtracteD		}
###InternalExtracteD		use warnings 'once';
###InternalExtracteD	} 

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'sorted_nodes' =>(
	is		=> 'ro',
	isa		=> HashRef,
	traits	=> ['Hash'],
	default	=> sub{ {} },
    handles	=> {
        add_sorted_nodes	=> 'set',
		has_sorted_nodes	=> 'count',
		check_sorted_node	=> 'exists',
		clear_sorted_nodes	=> 'clear',
		remove_sorted_node	=> 'delete',
		_retrieve_sorted_nodes => 'get',
    },
	writer		=> 'set_sorted_nodes',
	reader		=> 'get_sorted_nodes',
);

has 'skipped_nodes' =>(
	is		=> 'ro',
	isa		=> HashRef,
	traits	=> ['Hash'],
	default	=> sub{ {} },
    handles	=> {
        add_skipped_nodes	=> 'set',
		has_skipped_nodes	=> 'count',
		check_skipped_node	=> 'exists',
		clear_skipped_nodes	=> 'clear',
		remove_skipped_node	=> 'delete',
    },
	writer		=> 'set_skipped_nodes',
	reader		=> 'get_skipped_nodes',
);

has 'skip_level' =>(
	is			=> 'ro',
	isa			=> Int,
	predicate	=> 'has_skip_level',
	reader		=> 'get_skip_level',
	writer		=> 'set_skip_level',
	clearer		=> 'clear_skip_level',
);

has 'skip_node_tests' =>(
	is		=> 'ro',
	isa		=> ArrayRef[ArrayRef],
	traits	=> ['Array'],
	reader	=> 'get_skip_node_tests',
	writer	=> 'set_skip_node_tests',
	default	=> sub{ [] },
    handles => {
        add_skip_node_test		=> 'push',
		has_skip_node_tests		=> 'count',
		clear_skip_node_tests	=> 'clear',
    },
);

has 'change_array_size' =>(
    is      	=> 'ro',
    isa     	=> Bool,
	predicate	=> 'has_change_array_size',
	reader		=> 'get_change_array_size',
	writer		=> 'set_change_array_size',
	clearer		=> 'clear_change_array_size',
    default 	=> 1,
);

has 'fixed_primary' =>(
    is      	=> 'ro',
    isa     	=> Bool,
	predicate	=> 'has_fixed_primary',
	reader		=> 'get_fixed_primary',
	writer		=> 'set_fixed_primary',
	clearer		=> 'clear_fixed_primary',
    default 	=> 0,
);

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has '_current_level' =>(
	is			=> 'ro',
	isa			=> PosInt,
	default		=> 0,
	writer		=> '_set_current_level',
	reader		=> '_get_current_level',
);

has '_had_secondary' =>(
    is			=> 'ro',
    isa     	=> Bool,
	writer		=> '_set_had_secondary',
	reader		=> '_get_had_secondary',
	predicate	=> '_has_had_secondary',
    default		=> 0,
);

sub _clear_had_secondary{
	my ( $self, ) = @_;
	### <where> - setting _had_secondary to 0 ...
	$self->_set_had_secondary( 0 );
	return 1;
}

has '_single_pass_attributes' =>(
	is		=> 'ro',
	isa		=> ArrayRef[HashRef],
	traits	=> ['Array'],
	default	=> sub{ [] },
    handles => {
		_levels_of_saved_attributes	=> 'count',
		_add_saved_attribute_level => 'push',
		_get_saved_attribute_level => 'pop',
    },
);

#########1 Methods for Roles  3#########4#########5#########6#########7#########8#########9

sub _process_the_data{#Used to scrub high level input
    ###InternalExtracteD	warn "Made it to _process_the_data";
    ###InternalExtracteD	warn "Passed input:" . Dumper( @_ );
    my ( $self, $passed_ref, $conversion_ref, ) = @_;
    ### <where> - review the ref keys for requirements and conversion ...
	my $return_conversion;
	( $passed_ref, $return_conversion ) =
		$self->_convert_data( $passed_ref, $conversion_ref );
	###InternalExtracteD	warn "new passed_ref:" . Dumper( $passed_ref );
	$self->_has_required_inputs( $passed_ref, $return_conversion );
	$passed_ref = $self->_has_at_least_one_input( $passed_ref, $return_conversion );
	$passed_ref = $self->_manage_the_rest( $passed_ref );
	###InternalExtracteD	warn "Start recursive parsing with:" . Dumper( $passed_ref );
	my $return_ref = $self->_walk_the_data( $passed_ref );
    ###InternalExtracteD	warn "convert the data keys back to the role names";
	( $return_ref, $conversion_ref ) =
		$self->_convert_data( $return_ref, $return_conversion );
    ###InternalExtracteD	warn "restoring instance clone attributes as needed ...";
	$self->_restore_attributes;
	$self->_clear_had_secondary;
	###InternalExtracteD	warn "End recursive parsing with:" . Dumper( $return_ref );
    return $return_ref;
}

sub _build_branch{
    my ( $self, $base_ref, @arg_list ) = @_;
    ###InternalExtracteD	warn "Made it to _build_branch ...";
    ###InternalExtracteD	warn "base ref:" . Dumper( $base_ref );
    ###InternalExtracteD	warn "the passed arguments:" . Dumper( @arg_list );
	if( $arg_list[-1]->[3] == 0 ){
		###InternalExtracteD	warn "zeroth level found:" . Dumper( @arg_list );
		return $base_ref;
	}elsif( @arg_list ){
        my $current_ref  = pop @arg_list;
		$base_ref = $self->_dispatch_method(
			$reconstruction_dispatch ,
			$current_ref->[0],
			$current_ref,
			$base_ref,
		);
		my $answer = $self->_build_branch( $base_ref, @arg_list );
		###InternalExtracteD	warn "back up with:" . Dumper( $answer );
        return $answer;
    }else{
		###InternalExtracteD	warn "reached the bottom - returning:" . Dumper( $base_ref );
		return $base_ref;
    }

}

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _walk_the_data{
    my( $self, $passed_ref ) = @_;
    ###InternalExtracteD	warn "Made it to _walk_the_data with input:" . Dumper( $passed_ref );
	###InternalExtracteD	warn "checking for a before_method ...";
	if( exists $passed_ref->{before_method} ){
		my  $before_method = $passed_ref->{before_method};
		###InternalExtracteD	warn "role has a before_method:" . Dumper( $before_method );
		$passed_ref = $self->$before_method( $passed_ref );
		###InternalExtracteD	warn "completed before_method with current passed ref:" . Dumper( $passed_ref );
	}else{
		###InternalExtracteD	warn "No before_method found";
	}
    ###InternalExtracteD	warn "See if the node should be parsed ...";
	my $list_ref;
    if(	$passed_ref->{skip} eq 'YES' ){
		###InternalExtracteD	warn "Skip condition identified ...";
	}elsif( exists $base_type_ref->{$passed_ref->{primary_type}} ){
		###InternalExtracteD	warn "base type identified as: $passed_ref->{primary_type}";
	}else{
		###InternalExtracteD	warn "get the lower ref list ...";
		$list_ref = $self->_dispatch_method(
						$node_list_dispatch,
						$passed_ref->{primary_type},
						$passed_ref->{primary_ref},
					);
		###InternalExtracteD	warn "sorting the list as needed for:" . Dumper( $list_ref );
		if(	$self->check_sorted_node( $passed_ref->{primary_type} ) ){
			###InternalExtracteD	warn "The list should be sorted ...";
			my $sort_function =
				( is_CodeRef(
					$self->_retrieve_sorted_nodes( $passed_ref->{primary_type} )
				) ) ? ######## ONLY PARTIALLY TESTED !!!! ######
					$self->_retrieve_sorted_nodes( $passed_ref->{primary_type} ) :
					sub{ $a cmp $b } ;
			$list_ref = [ sort $sort_function @$list_ref ];
			if( $passed_ref->{primary_type} eq 'ARRAY' ){
				###InternalExtracteD	warn "This is an array ref and the array ref will be sorted ...";
				$passed_ref->{primary_ref} =
					[sort $sort_function @{$passed_ref->{primary_ref}}];
			}
			###InternalExtracteD	warn "sorted list:" . Dumper( $list_ref );
		}
	}
	if( $list_ref ){
		###InternalExtracteD	warn "climbing up the node tree and running the list:" . Dumper( $list_ref );
		$self->_set_current_level( 1 + $self->_get_current_level );
		###InternalExtracteD	warn "new current level:" . Dumper( $self->_get_current_level );
		my	$lower_ref = $self->_down_load_general( $passed_ref );
		###InternalExtracteD	warn "the core lower ref is:" . Dumper( $lower_ref );
		my	$x = 0;
		for my $item ( @{$list_ref} ){
			###InternalExtracteD	warn "now parsing: $item";
			delete $lower_ref->{secondary_ref};
			$lower_ref = 	$self->_get_lower_refs(
								$passed_ref, $lower_ref, $item,
								$x, $self->_get_current_level,
							);
			###InternalExtracteD	warn "lower ref:" . Dumper( $lower_ref );
			for my $key ( @lower_key_list ){
				###InternalExtracteD	warn "working to load: $key";
				$lower_ref->{$key} = $self->_dispatch_method(
					$down_level_tests_dispatch, $key, $lower_ref,
				);
			}
			###InternalExtracteD	warn "walking the data:" . Dumper( $lower_ref );
			$lower_ref = $self->_walk_the_data( $lower_ref );
			my	$old_branch_ref = pop @{$lower_ref->{branch_ref}};
			###InternalExtracteD	warn "pass any data reference adjustments with branch ref:" . Dumper( $old_branch_ref );
			for my $key ( @data_key_list ){
				###InternalExtracteD	warn "processing: $key";
				if( $key eq 'primary_ref' and
					$self->has_fixed_primary and
					$self->get_fixed_primary 		){
					###InternalExtracteD	warn "the primary ref is fixed and no changes will be passed upwards ...";
				}elsif( exists $lower_ref->{$key} 	){
					###InternalExtracteD	warn "a lower ref was identified and will be passed upwards for: $key";
					$passed_ref = $self->_dispatch_method(
						$up_ref_dispatch,
						$old_branch_ref->[0],
						$key,
						$old_branch_ref,
						$passed_ref,
						$lower_ref,
					);
				}
				###InternalExtracteD	warn "new passed ref:" . Dumper( $passed_ref );
			}
			$x++;
		}
		###InternalExtracteD	warn "climbing back down the node tree from level:" . Dumper( $self->_get_current_level );
		$self->_set_current_level( -1 + $self->_get_current_level );
	}

	###InternalExtracteD	warn "Attempting the after_method ...";
    if( exists $passed_ref->{after_method} ){
        my $after_method = $passed_ref->{after_method};
        ###InternalExtracteD	warn "role has an after_method: $after_method";
        $passed_ref = $self->$after_method( $passed_ref );
        ###InternalExtracteD	warn "returned from after_method:" . Dumper( $passed_ref );
    }else{
        ###InternalExtracteD	warn "No after_method found";
    }
    ###InternalExtracteD	warn "returning passedref:" . Dumper( $passed_ref );
    return $passed_ref;
}

sub _convert_data{
	my ( $self, $passed_ref, $conversion_ref, ) = @_;
	###InternalExtracteD	warn "Reached _convert_data with ref:" . Dumper( $conversion_ref );
	###InternalExtracteD	warn "...for passed ref:" . Dumper( $passed_ref );
	for my $key ( keys %$conversion_ref ){
		if( exists $passed_ref->{$key} ){
			$passed_ref->{$conversion_ref->{$key}} =
				( $passed_ref->{$key} ) ?
					$passed_ref->{$key} : undef;
			delete $passed_ref->{$key};
		}
	}
	###InternalExtracteD	warn "inverting conversion ref ...";
	my  $return_conversion = { reverse %$conversion_ref };
	###InternalExtracteD	warn "passed ref now equals:" . Dumper( $passed_ref );
	return( $passed_ref, $return_conversion );
}

sub _has_required_inputs{
    my ( $self, $passed_ref, $lookup_ref, ) = @_;
	###InternalExtracteD	warn "Reached _has_required_inputs with ref:" . Dumper( $lookup_ref );
	###InternalExtracteD	warn "...for passed ref:" . Dumper( $passed_ref );
    for my $key ( @{$data_key_tests->{required}} ){
		if( !exists $passed_ref->{$key} ){
			confess '-' .
			( ( exists $lookup_ref->{$key} ) ? $lookup_ref->{$key} : $key ) .
			'- is a required key but was not found in the passed ref';
		}
	}
	return 1;
}

sub _has_at_least_one_input{
    my ( $self, $passed_ref, $lookup_ref ) = @_;
	###InternalExtracteD	warn "Reached _has_at_least_one_input with ref:" . Dumper( $lookup_ref );
	###InternalExtracteD	warn "...for passed ref:" . Dumper( $passed_ref );
	my $count;
    for my $key ( @{$data_key_tests->{at_least_one}} ){
		if( !exists $passed_ref->{$key} ){
			push @{$count->{missing}}, (
				( exists $lookup_ref->{$key} ) ?
					$lookup_ref->{$key} : $key
			);
		}elsif( defined $passed_ref->{$key} ){
			$count->{found}++;
		}else{
			push @{$count->{empty}}, (
				( exists $lookup_ref->{$key} ) ?
					$lookup_ref->{$key} : $key
			);
			delete $passed_ref->{$key};
		}
	}
	if( $count->{found} ){
		return $passed_ref;
	}elsif( exists $count->{empty} ){
		confess '-' . (join '- and -', @{$count->{empty}} ) .
			'- must have values for the key(s)';
	}else{
		confess 'One of the keys -' . (join '- or -', @{$count->{missing}} ) .
			'- must be provided with values';
	}
}

sub _manage_the_rest{
    my ( $self, $passed_ref ) = @_;
	###InternalExtracteD	warn "Reached _manage_the_rest with ref:" . Dumper( $passed_ref );
	$passed_ref->{branch_ref} =	$self->_main_down_level_branch_ref(
									$passed_ref->{branch_ref}
								);
	###InternalExtracteD	warn "handle one shot attributes ...";
	my $attributes_at_level = {};
	for my $key ( keys %$passed_ref ){
		if( exists $data_key_tests->{all_possibilities}->{$key} ){
			### <where> - found standard key: $key
		}elsif( $self->meta->find_attribute_by_name( $key )  ){
			###InternalExtracteD	warn "found an attribute: $key";
			$key =~ /^(_)?([^_].*)/;
			my ( $predicate, $writer, $reader, $clearer ) =
					( "has_$2", "set_$2", "get_$2", "clear_$2", );
			if( defined $1 ){
				( $predicate, $writer, $reader, $clearer ) =
					( "_$predicate", "_$writer", "_$reader", "_$clearer" );
			}
			###InternalExtracteD	warn 'Testing for attribute use as a "one-shot" attribute ...';
			for my $method ( $predicate, $reader, $writer, $clearer ){
				if( $self->can( $method ) ){
					### <where> - so far so good for: $method
				}else{
					confess "-$method- is not supported for key -$key- " .
						"so one shot attribute test failed";
				}
			}
			###InternalExtracteD	warn "First save the old settings ...";
			$attributes_at_level->{$key} = ( $self->$predicate ) ?
				$self->$reader : undef;
			###InternalExtracteD	warn "load the new settings:" . Dumper( $passed_ref->{$key} );
			$self->$writer( $passed_ref->{$key} );
			delete $passed_ref->{$key};
		}else{
			confess "-$key- is not an accepted hash key value";
		}
	}
	###InternalExtracteD	warn "attribute storage:" . Dumper( $attributes_at_level );
	$self->_add_saved_attribute_level( $attributes_at_level );
	###InternalExtracteD	warn "setting the secondary flag as needed ...";
	if( exists $passed_ref->{secondary_ref} ){
		$self->_set_had_secondary( 1 );
	}
	###InternalExtracteD	warn "setting the remaining keys ...";
	for my $key ( @lower_key_list ){
		###InternalExtracteD	warn "working to load: $key";
		$passed_ref->{$key} =	$self->_dispatch_method(
			$down_level_tests_dispatch, $key, $passed_ref,
		);
	}
	###InternalExtracteD	warn "current passed ref:" . Dumper( $passed_ref );
	###InternalExtracteD	warn "self:" . Dumper( $self );
    return $passed_ref;
}

sub _main_down_level_branch_ref{
    my ( $self, $value ) = @_;
    ###InternalExtracteD	warn "reached _main_down_level_branch_ref ...";
	$value //= [ [ 'SCALAR', undef, 0, 0, ] ];
	###InternalExtracteD	warn "using: $value";
	my	$return;
	map{ push @$return, $_ } @$value;
	###InternalExtracteD	warn "returning:" . Dumper( $return );
	return $return;
}

sub _get_object_list{
    my ( $self, $data_reference ) = @_;
    ###InternalExtracteD	warn "Made it to _get_object_list with reference:" . Dumper( $data_reference );
	my $list_ref;
	if( scalar( @{$self->_get_object_attributes( $data_reference )} ) ){
		###InternalExtracteD	warn "found attributes ...";
		push @$list_ref, 'attributes';
	}
	if( scalar( @{$self->_get_object_methods( $data_reference )} ) ){
		### <where> - found methods ...
		push @$list_ref, 'methods';
	}
	###InternalExtracteD	warn "final list:" . Dumper( $list_ref );
	return $list_ref;
}

sub _down_load_general{
	my( $self, $upper_ref, ) = @_;
	###InternalExtracteD	warn "reached _down_load_general with upper ref:" . Dumper( $upper_ref );
	my $lower_ref;
	for my $key ( keys %$upper_ref ){
		my $return = 	$self->_dispatch_method(
							$main_down_level_data, $key, $upper_ref->{$key},
						);
		$lower_ref->{$key} = $return if defined $return;
	}
	###InternalExtracteD	warn "returning lower_ref:" . Dumper(  $lower_ref );
	return $lower_ref;
}

sub _restore_attributes{
    my ( $self, ) = @_;
	my ( $answer, ) = (0, );
    ###InternalExtracteD	warn "reached _restore_attributes ...";
	my 	$attribute_ref = $self->_get_saved_attribute_level;
	for my $attribute ( keys %$attribute_ref ){
		###InternalExtracteD	warn "restoring: $attribute";
		$attribute =~ /^(_)?([^_].*)/;
		my ( $writer, $clearer ) = ( "set_$2", "clear_$2", );
		if( defined $1 ){
			( $writer, $clearer ) = ( "_$writer", "_$clearer" );
		}
		###InternalExtracteD	warn "possible clearer: $clearer";
		###InternalExtracteD	warn "possible writer: $writer";
		$self->$clearer;
		if( defined $attribute_ref->{$attribute} ){
			###InternalExtracteD	warn "resetting attribute value:" . Dumper( $attribute_ref->{$attribute} );
			$self->$writer( $attribute_ref->{$attribute} );
		}
		###InternalExtracteD	warn "finished restoring: $attribute";
	}
	return 1;
}

sub _item_down_level_type{
	my ( $key	) = @_;
	return sub{
		my ( $self, $passed_ref, ) = @_;
		return $self->_extracted_ref_type(
			$key, $passed_ref,
		);
	}
}

sub _extracted_ref_type{
    my ( $self, $ref_key, $passed_ref, ) = @_;
    ###InternalExtracteD	warn "made it to _extracted_ref_type ...";
    my $ref_type;
	if( exists $passed_ref->{$ref_key} ){
		$ref_type = ref $passed_ref->{$ref_key};
		if( exists $discover_type_dispatch->{$ref_type} ){
			###InternalExtracteD	warn "confirmed ref: $ref_type";
		}else{
			CHECKALLTYPES: for my $key ( @$supported_type_list ){
				###InternalExtracteD	warn "testing: $key";
				if( $self->_dispatch_method(
						$discover_type_dispatch,
						$key,
						$passed_ref->{$ref_key},
					) 							){
					###InternalExtracteD	warn "found a match for: $key";
					$ref_type = $key;
					last CHECKALLTYPES;
				}
				###InternalExtracteD	warn "no match ...";
			}
		}
	}else{
		$ref_type = 'DNE';
	}
	###InternalExtracteD	warn "ref type is: $ref_type";
	if( !$ref_type ){
		confess "Attempting to parse the unsupported node type -" .
			( ref $passed_ref ) . "-";
	}
    ###InternalExtracteD	warn "returning: $ref_type";
    return $ref_type;
}

sub _ref_matching{
	my ( $self, $passed_ref, ) = @_;
	###InternalExtracteD	warn "reached _ref_matching for type: $passed_ref->{branch_ref}->[-1]->[0]";
	###InternalExtracteD	warn "passed items:" . Dumper( $passed_ref );
	my	$match = 'NO';
	if( $passed_ref->{secondary_type} eq 'DNE' ){
		###InternalExtracteD	warn "nothing to match ...";
	}elsif( $passed_ref->{secondary_type} ne $passed_ref->{primary_type} ){
		###InternalExtracteD	warn "failed a type match ...";
	}else{
		###InternalExtracteD	warn "The obvious match issues pass - testing deeper ...";
		$match = $self->_dispatch_method(
			$secondary_match_dispatch, $passed_ref->{primary_type},
			$passed_ref, @{$passed_ref->{branch_ref}->[-1]}[1,2],
		);
	}
	###InternalExtracteD	warn "returning: $match";
	return $match;
}

sub _will_parse_next_ref{
    my ( $self, $passed_ref, ) = @_;
    ###InternalExtracteD	warn "Made it to _will_parse_next_ref for ref:" . Dumper( $passed_ref );
	my  $skip = 'NO';
	if(	$self->has_skipped_nodes and
		$self->check_skipped_node( $passed_ref->{primary_type} ) ){
		###InternalExtracteD	warn "skipping the current nodetype: $passed_ref->{primary_type}";
		$skip = 'YES';
	}elsif($self->has_skip_level and
			$self->get_skip_level ==
			( ( $passed_ref->{branch_ref}->[-1]->[3] ) + 1 ) ){
		###InternalExtracteD	warn "skipping the level:" . ( $passed_ref->{branch_ref}->[-1]->[3] + 1 );
		$skip = 'YES';
	}elsif( $self->has_skip_node_tests ){
		my	$current_branch = $passed_ref->{branch_ref}->[-1];
		###InternalExtracteD	warn "found skip tests:" . Dumper( $self->get_skip_node_tests );
		SKIPNODE: for my $test ( @{$self->get_skip_node_tests} ){
			###InternalExtracteD	warn "running test: $test";
			$skip = $self->_general_skip_node_test(
						$test, $current_branch,
					);
			last SKIPNODE if $skip eq 'YES';
		}
	}
	###InternalExtracteD	warn "returning skip eq: $skip";
	return $skip;
}

sub _general_skip_node_test{
    my ( $self, $test_ref, $branch_ref, ) = @_;
	my	$match_level= 0;
    ###InternalExtracteD	warn "reached _general_skip_node_test for test_ref:" . Dumper( $test_ref );
	###InternalExtracteD	warn ".. and branch_ref:" . Dumper( $branch_ref );
	my $item = $branch_ref->[1];
	###InternalExtracteD	warn "item:" . Dumper( $item );
	$match_level++ if
		(	$test_ref->[0] eq $branch_ref->[0] );
	###InternalExtracteD	warn "match level after type match: $match_level";
	$match_level++ if
		(
			( $test_ref->[1] eq 'ARRAY' ) or
			( $test_ref->[1] =~ /^(any|all)$/i	) or
			( $item and
				(
					$test_ref->[1] eq $item or
					$test_ref->[1] =~ /$item/
				)
			)
		);
	###InternalExtracteD	warn "match level after item match: $match_level";
	$match_level++ if
		(	$test_ref->[2] =~ /^(any|all)$/i or
			( 	is_Num( $test_ref->[2] ) and
				$test_ref->[2] == $branch_ref->[2] ) );
	###InternalExtracteD	warn "match level after position match: $match_level";
	$match_level++ if
		(	$test_ref->[3] =~ /^(any|all)$/i or
			( 	is_Num( $test_ref->[3] ) and
				$test_ref->[3] == $branch_ref->[3] ) );
	###InternalExtracteD	warn "match level after depth match: $match_level";
	my	$answer = ( $match_level == 4 ) ? 'YES' : 'NO' ;
	###InternalExtracteD	warn "answer: $answer";
	return $answer;
}

sub _get_lower_refs{
	my ( $self, $upper_ref, $lower_ref, $item, $position, $level ) = @_;
	###InternalExtracteD	warn "reached _get_lower_refs for:" . Dumper( @_[1 .. 5] );
	for my $key ( @data_key_list ){
		###InternalExtracteD	warn "running key: $key";
		my $test = 1;
		if( $key eq 'secondary_ref' ){
			###InternalExtracteD	warn "secondary ref check ...";
			$test = $self->_dispatch_method(
						$secondary_ref_exists_dispatch,
						$upper_ref->{primary_type},
						$upper_ref, $item, $position,
					);
			###InternalExtracteD	warn "secondary ref exists result: $test";
		}
		if(	$test ){
			###InternalExtracteD	warn "loading lower ref needed ...";
			$lower_ref->{$key} = $self->_dispatch_method(
				$sub_ref_dispatch,
				$upper_ref->{primary_type},
				$upper_ref->{$key}, $item, $position,
			);
		}
		###InternalExtracteD	warn "lower_ref:" . Dumper( $lower_ref );
	}
	push @{$lower_ref->{branch_ref}}, [
		$upper_ref->{primary_type},
		$item, $position, $level,
	];
	###InternalExtracteD	warn "returning:" . Dumper( $lower_ref );
	return $lower_ref;
}

sub _get_object_element{
    my ( $self, $data_reference, $item, $position, ) = @_;
    ###InternalExtracteD	warn "Made it to _get_object_attributes for:" . Dumper( @_[1 .. 3] );
	my $item_ref;
	if( $item eq 'attributes' ){
		my $scalar_util_val = reftype( $data_reference );
		$scalar_util_val //= 'DEFAULT';
		###InternalExtracteD	warn "Scalar-Util-reftype: $scalar_util_val";
		$item_ref = $self->_dispatch_method(
			$object_extraction_dispatch,
			$scalar_util_val,
			$data_reference,
		);
	}if( $item eq 'methods' ){
		$item_ref = Class::Inspector->function_refs(
			ref $data_reference
		);
	}else{
		confess "Get -$item- element not written yet";
	}
	###InternalExtracteD	warn "the attribute list is:" . Dumper( $item_ref );
	return $item_ref;
}

sub _load_hash_up{
    my ( $self, $key, $branch_ref_item, $passed_ref, $lower_passed_ref, ) = @_;
    ###InternalExtracteD	warn "Made it to _load_hash_up for the: $key";
	###InternalExtracteD	warn "the branch ref is:" . Dumper( $branch_ref_item );
	###InternalExtracteD	warn "additional passed info:" . Dumper( @_[3, 4] );
	$passed_ref->{$key}->{$branch_ref_item->[1]} =
		$lower_passed_ref->{$key};
	###InternalExtracteD	warn "the new passed_ref is:" . Dumper( $passed_ref );
	return $passed_ref;
}

sub _load_array_up{
    my ( $self, $key, $branch_ref_item, $passed_ref, $lower_passed_ref, ) = @_;
    ###InternalExtracteD	warn "Made it to _load_array_up for the: $key";
	###InternalExtracteD	warn "the branch ref is:" . Dumper( $branch_ref_item );
	###InternalExtracteD	warn "lower ref:". Dumper( $lower_passed_ref );
	$passed_ref->{$key}->[$branch_ref_item->[2]] =
		$lower_passed_ref->{$key};
	###InternalExtracteD	warn "the new passed_ref is:" . Dumper( $passed_ref );
	return $passed_ref;
}

sub _rebuild_hash_level{
    my ( $self, $item_ref, $base_ref, ) = @_;
	###InternalExtracteD	warn "Made it to _rebuild_hash_level for item ref:" . Dumper(  $item_ref );
    ###InternalExtracteD	warn ".. and base ref:" . Dumper( $base_ref );
	return { $item_ref->[1] => $base_ref };
}

sub _rebuild_array_level{
    my ( $self, $item_ref, $base_ref, ) = @_;
    ###InternalExtracteD	warn "Made it to _rebuild_array_level for item ref:" . Dumper(  $item_ref );
    ###InternalExtracteD	warn ".. and base ref:" . Dumper( $base_ref );
	my  $array_ref = [];
	$array_ref->[$item_ref->[2]] = $base_ref;
	return $array_ref;
}

#########1 Phinish Strong     3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#########1 Main POD starts    3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Data::Walk::Extracted - An extracted dataref walker

=begin html

<a href="https://www.perl.org">
	<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="perl version">
</a>

<a href="https://travis-ci.org/jandrew/Data-Walk-Extracted">
	<img alt="Build Status" src="https://travis-ci.org/jandrew/Data-Walk-Extracted.png?branch=master" alt='Travis Build'/>
</a>

<a href='https://coveralls.io/r/jandrew/Data-Walk-Extracted?branch=master'>
	<img src='https://coveralls.io/repos/jandrew/Data-Walk-Extracted/badge.svg?branch=master' alt='Coverage Status' />
</a>

<a href='https://github.com/jandrew/Data-Walk-Extracted'>
	<img src="https://img.shields.io/github/tag/jandrew/Data-Walk-Extracted.svg?label=github version" alt="github version"/>
</a>

<a href="https://metacpan.org/pod/Data::Walk::Extracted">
	<img src="https://badge.fury.io/pl/Data-Walk-Extracted.svg?label=cpan version" alt="CPAN version" height="20">
</a>

<a href='http://cpants.cpanauthors.org/dist/Data-Walk-Extracted'>
	<img src='http://cpants.cpanauthors.org/dist/Data-Walk-Extracted.png' alt='kwalitee' height="20"/>
</a>

=end html

=head1 SYNOPSIS

This is a contrived example!  For a more functional (complex/useful) example see the
roles in this package.

	package Data::Walk::MyRole;
	use Moose::Role;
	requires '_process_the_data';
	use MooseX::Types::Moose qw(
			Str
			ArrayRef
			HashRef
		);
	my $mangle_keys = {
		Hello_ref => 'primary_ref',
		World_ref => 'secondary_ref',
	};

	#########1 Public Method      3#########4#########5#########6#########7#########8

	sub mangle_data{
		my ( $self, $passed_ref ) = @_;
		@$passed_ref{ 'before_method', 'after_method' } =
			( '_mangle_data_before_method', '_mangle_data_after_method' );
		### Start recursive parsing
		$passed_ref = $self->_process_the_data( $passed_ref, $mangle_keys );
		### End recursive parsing with: $passed_ref
		return $passed_ref->{Hello_ref};
	}

	#########1 Private Methods    3#########4#########5#########6#########7#########8

	### If you are at the string level merge the two references
	sub _mangle_data_before_method{
		my ( $self, $passed_ref ) = @_;
		if(
			is_Str( $passed_ref->{primary_ref} ) and
			is_Str( $passed_ref->{secondary_ref} )		){
			$passed_ref->{primary_ref} .= " " . $passed_ref->{secondary_ref};
		}
		return $passed_ref;
	}

	### Strip the reference layers on the way out
	sub _mangle_data_after_method{
		my ( $self, $passed_ref ) = @_;
		if( is_ArrayRef( $passed_ref->{primary_ref} ) ){
			$passed_ref->{primary_ref} = $passed_ref->{primary_ref}->[0];
		}elsif( is_HashRef( $passed_ref->{primary_ref} ) ){
			$passed_ref->{primary_ref} = $passed_ref->{primary_ref}->{level};
		}
		return $passed_ref;
	}

	package main;
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	my 	$AT_ST = build_instance(
			package		=> 'Greeting',
			superclasses	=> [ 'Data::Walk::Extracted' ],
			roles		=> [ 'Data::Walk::MyRole' ],
		);
	print $AT_ST->mangle_data( {
			Hello_ref =>{ level =>[ { level =>[ 'Hello' ] } ] },
			World_ref =>{ level =>[ { level =>[ 'World' ] } ] },
		} ) . "\n";



	#################################################################################
	#     Output of SYNOPSIS
	# 01:Hello World
	#################################################################################

=head1 DESCRIPTION

This module takes a data reference (or two) and
L<recursivly|http://en.wikipedia.org/wiki/Recursion_(computer_science)>
travels through it(them).  Where the two references diverge the walker follows the
primary data reference.  At the L<beginning|/Assess and implement the before_method>
and L<end|/Assess and implement the after_method> of each branch or L<node|/node>
in the data the code will attempt to call a L<method|/Extending Data::Walk::Extracted>
on the remaining unparsed data.

=head2 Acknowledgement of MJD

This is an implementation of the concept of extracted data walking from
L<Higher-Order-Perl|http://hop.perl.plover.com/book/> Chapter 1 by
L<Mark Jason Dominus|https://metacpan.org/author/MJD>.  I<The book is well worth the
money!>  With that said I diverged from MJD purity in two ways. This is object oriented
code not functional code. Second, when taking action the code will search for class
methods provided by (your) role rather than acting on passed closures.  There is clearly
some overhead associated with both of these differences.  I made those choices consciously
and if that upsets you L<do not hassle MJD|/AUTHOR>!

=head2 What is the unique value of this module?

With the recursive part of data walking extracted the various functionalities desired
when walking the data can be modularized without copying this code.  The Moose
framework also allows diverse and targeted data parsing without dragging along a
L<kitchen sink|http://en.wiktionary.org/wiki/everything_but_the_kitchen_sink> API
for every use of this class.

=head2 Extending Data::Walk::Extracted

B<All action taken during the data walking must be initiated by implementation of action
methods that do not exist in this class>.  It usually also makes sense to build an
initial action method as well.  The initial action method can do any data-preprocessing
that is useful as well as providing the necessary set up for the generic walker.  All
of these elements can be combined with this class using a L<Moose role
|https://metacpan.org/module/Moose::Manual::Roles>, by
L<extending the class|https://metacpan.org/module/Moose::Manual::Classes>, or it can be
joined to the class at run time. See L<MooseX::ShortCut::BuildInstance
|https://metacpan.org/module/MooseX::ShortCut::BuildInstance>.  or L<Moose::Util
|https://metacpan.org/module/Moose::Util> for more class building information.  See the
L<parsing flow|/Recursive Parsing Flow> to understand the details of how the methods are
used.  See L<methods used to write roles|/Methods used to write roles> for the available
methods to implement the roles.

Then, L<Write some tests for your role!|http://www.perlmonks.org/?node_id=918837>

=head1 Recursive Parsing Flow

=head2 Initial data input and scrubbing

The primary input method added to this class for external use is refered to as
the 'action' method (ex. 'mangle_data').  This action method needs to receive
data and organize it for sending to the L<start method
|/_process_the_data( $passed_ref, $conversion_ref )> for the generic data walker.
I<Remember if more than one role is added to Data::Walk::Extracted
for a given instance then all methods should be named with consideration for other
(future?) method names.  The '$conversion_ref' allows for muliple uses of the core
data walkers generic functions.  The $conversion_ref is not passed deeper into the
recursion flow.>

=head2 Assess and implement the before_method

The class next checks for an available 'before_method'.  Using the test;

	exists $passed_ref->{before_method};

If the test passes then the next sequence is run.

	$method = $passed_ref->{before_method};
	$passed_ref = $self->$method( $passed_ref );

If the $passed_ref is modified by the 'before_method' then the recursive parser will
parse the new ref and not the old one.  The before_method can set;

	$passed_ref->{skip} = 'YES'

Then the flow checks for the need to investigate deeper.

=head2 Test for deeper investigation

The code now checks if deeper investigation is required checking both that the 'skip' key
= 'YES' in the $passed_ref or if the node is a L<base ref type|/base node type>.
If either case is true the process jumps to the L<after method
|/Assess and implement the after_method> otherwise it begins to investigate the next
level.

=head2 Identify node elements

If the next level in is not skipped then a list is generated for all L<paths|/node>
in the node. For example a 'HASH' node would generate a list of hash keys for that node.
SCALAR nodes will generate a list with only one element containing the scalar contents.
UNDEF nodes will generate an empty list.

=head2 Sort the node as required

If the list L<should be sorted|/sorted_nodes>
then the list is sorted. B<ARRAYS are hard sorted.> I<This means that the actual items in
the (primary) passed data ref are permanantly sorted.>

=head2 Process each element

For each identified element of the node a new $data_ref is generated containing data that
represents just that sub element.  The secondary_ref is only constructed if it has a
matching type and element to the primary ref.  Matching for hashrefs is done by key
matching only.  Matching for arrayrefs is done by position exists testing only.  I<No
position content compare is done!> Scalars are matched on content.  The list of items
generated for this element is as follows;

=over

B<before_method =E<gt>> --E<gt>name of before method for this role hereE<lt>--

B<after_method =E<gt>> --E<gt>name of after method for this role hereE<lt>--

B<primary_ref =E<gt>> the piece of the primary data ref below this element

B<primary_type =E<gt>> the lower primary (walker)
L<ref type|/_extracted_ref_type( $test_ref )>

B<match =E<gt>> YES|NO (This indicates if the secondary ref meets matching critera)

B<skip =E<gt>> YES|NO Checks L<the three skip attributes|/skipped_nodes> against
the lower primary_ref node.  This can also be set in the 'before_method' upon arrival
at that node.

B<secondary_ref =E<gt>> if match eq 'YES' then built like the primary ref

B<secondary_type =E<gt>> if match eq 'YES' then calculated like the primary type

B<branch_ref =E<gt>> L<stack trace|/A position trace is generated>

=back

=head2 A position trace is generated

The current node list position is then documented and pushed onto the array at
$passed_ref->{branch_ref}.  The array reference stored in branch_ref can be
thought of as the stack trace that documents the node elements directly between the
current position and the initial (or zeroth) level of the parsed primary data_ref.
Past completed branches and future pending branches are not maintained.  Each element
of the branch_ref contains four positions used to describe the node and selections
used to traverse that node level.  The values in each sub position are;

	[
		ref_type, #The node reference type
		the list item value or '' for ARRAYs,
			#key name for hashes, scalar value for scalars
		element sequence position (from 0),
			#For hashes this is only relevent if sort_HASH is called
		level of the node (from 0),
			`#The zeroth level is the initial data ref
	]

=head2 Going deeper in the data

The down level ref is then passed as a new data set to be parsed and it starts
at the L<before_method|/Assess and implement the before_method> again.

=head2 Actions on return from recursion

When the values are returned from the recursion call the last branch_ref element is
L<pop|http://perldoc.perl.org/functions/pop.html>ed off and the returned data ref
is used to L<replace|/fixed_primary> the sub elements of the primary_ref and secondary_ref
associated with that list element in the current level of the $passed_ref.  If there are
still pending items in the node element list then the program L<processes them too
|/Process each element>


=head2 Assess and implement the after_method

After the node elements have all been processed the class checks for an available
'after_method' using the test;

	exists $passed_ref->{after_method};

If the test passes then the following sequence is run.

	$method = $passed_ref->{after_method};
	$passed_ref = $self->$method( $passed_ref );

If the $passed_ref is modified by the 'after_method' then the recursive parser will
parse the new ref and not the old one.

=head2 Go up

The updated $passed_ref is passed back up to the L<next level
|/Actions on return from recursion>.

=head1 Attributes

Data passed to -E<gt>new when creating an instance.  For modification of these attributes
see L<Public Methods|/Public Methods>.  The -E<gt>new function will either accept fat
comma lists or a complete hash ref that has the possible attributes as the top keys.
Additionally some attributes that have the following prefixed methods; get_$name, set_$name,
clear_$name, and has_$name can be passed to L<_process_the_data
|/_process_the_data( $passed_ref, $conversion_ref )> and will be adjusted for just the
run of that method call.  These are called L<one shot|/Supported one shot attributes>
attributes.  Nested calls to _process_the_data will be tracked and the attribute will
remain in force until the parser returns to the calling 'one shot' level.  Previous
attribute values are restored after the 'one shot' attribute value expires.

=head2 sorted_nodes

=over

B<Definition:> If the primary_type of the L<$element_ref|/Process each element>
is a key in this attribute hash ref then the node L<list|/Identify node elements> is
sorted. If the value of that key is a CODEREF then the sort L<sort
|http://perldoc.perl.org/functions/sort.html> function will called as follows.

	@node_list = sort $coderef @node_list

I<For the type 'ARRAY' the node is sorted (permanantly) by the element values.  This
means that if the array contains a list of references it will effectivly sort against
the ASCII of the memory pointers.  Additionally the 'secondary_ref' node is not
sorted, so prior alignment may break.  In general ARRAY sorts are not recommended.>

B<Default> {} #Nothing is sorted

B<Range> This accepts a HashRef.

B<Example:>

	sorted_nodes =>{
		ARRAY	=> 1,#Will sort the primary_ref only
		HASH	=> sub{	$b cmp $a }, #reverse sort the keys
	}

=back

=head2 skipped_nodes

=over

B<Definition:> If the primary_type of the L<$element_ref|/Process each element>
is a key in this attribute hash ref then the 'before_method' and 'after_method' are
run at that node but no L<parsing|/Identify node elements> is done.

B<Default> {} #Nothing is skipped

B<Range> This accepts a HashRef.

B<Example:>

	sorted_nodes =>{
		OBJECT => 1,#skips all object nodes
	}

=back

=head2 skip_level

=over

B<Definition:> This attribute is set to skip (or not) node parsing at the set level.
Because the process doesn't start checking until after it enters the data ref
it effectivly ignores a skip_level set to 0 (The base node level).  I<The test checks
against the value in last position of the prior L<trace|/A position trace is generated>
array ref + 1>.

B<Default> undef = Nothing is skipped

B<Range> This accepts an integer

=back

=head2 skip_node_tests

=over

B<Definition:> This attribute contains a list of test conditions used to skip
certain targeted nodes.  The test can target an array position, match a hash key, even
restrict the test to only one level.  The test is run against the latest
L<branch_ref|/A position trace is generated> element so it skips the node below the
matching conditions not the node at the matching conditions.  Matching is done with
'=~' and so will accept a regex or a string.  The attribute contains an ArrayRef of
ArrayRefs.  Each sub_ref contains the following;

=over

B<$type> - This is any of the L<identified|/_extracted_ref_type( $test_ref )>
reference node types

B<$key> - This is either a scalar or regex to use for matching a hash key

B<$position> - This is used to match an array position.  It can be an integer or 'ANY'

B<$level> - This restricts the skipping test usage to a specific level only or 'ANY'

=back

B<Example:>

	[
		[ 'HASH', 'KeyWord', 'ANY', 'ANY'],
		# Skip the node below the value of any hash key eq 'Keyword'
		[ 'ARRAY', 'ANY', '3', '4'], ],
		# Skip the node stored in arrays at position three on level four
	]

B<Range> An infinite number of skip tests added to an array

B<Default> [] = no nodes are skipped

=back

=head2 change_array_size

=over

B<Definition:> This attribute will not be used by this class directly.  However
the L<Data::Walk::Prune|https://metacpan.org/module/Data::Walk::Prune#prune_data-args>
role may share it with other roles in the future so it is placed here so there will be
no conflicts.  This is usually used to define whether an array size shinks when an element
is removed.

B<Default> 1 (This probably means that the array will shrink when a position is removed)

B<Range> Boolean values.

=back

=head2 fixed_primary

=over

B<Definition:> This means that no changes made at lower levels will be passed
upwards into the final ref.

B<Default> 0 = The primary ref is not fixed (and can be changed) I<0 -E<gt> effectively
deep clones the portions of the primary ref that are traversed.>

B<Range> Boolean values.

=back

=head1 Methods

=head2 Methods used to write roles

These are methods that are not meant to be exposed to the final user of a composed role and
class but are used by the role to excersize the class.

=head3 _process_the_data( $passed_ref, $conversion_ref )

=over

B<Definition:> This method is the gate keeper to the recursive parsing of
Data::Walk::Extracted.  This method ensures that the minimum requirements for the recursive
data parser are met.  If needed it will use a conversion ref (also provided by the caller) to
change input hash keys to the generic hash keys used by this class.  This function then
calls the actual recursive function.  For an overview of the recursive steps see the
L<flow outline|/Recursive Parsing Flow>.

B<Accepts:> ( $passed_ref, $conversion_ref )

=over

B<$passed_ref> this ref contains key value pairs as follows;

=over

B<primary_ref> - a dataref that the walker will walk - required

=over

review the $conversion_ref functionality in this function for renaming of this key.

=back

B<secondary_ref> - a dataref that is used for comparision while walking. - optional

=over

review the $conversion_ref functionality in this function for renaming of this key.

=back

B<before_method> - a method name that will perform some action at the beginning
of each node - optional

B<after_method> - a method name that will perform some action at the end
of each node - optional

B<[attribute name]> - L<supported|/Supported one shot attributes> attribute names are
accepted with temporary attribute settings here.  These settings are temporarily set for
a single "_process_the_data" call and then the original attribute values are restored.

=back

B<$conversion_ref> This allows a public method to accept different key names for the
various keys listed above and then convert them later to the generic terms used by this class.
- optional

B<Example>

	$passed_ref ={
		print_ref =>{
			First_key => [
				'first_value',
				'second_value'
			],
		},
		match_ref =>{
			First_key 	=> 'second_value',
		},
		before_method	=> '_print_before_method',
		after_method	=> '_print_after_method',
		sorted_nodes	=>{ Array => 1 },#One shot attribute setter
	}

	$conversion_ref ={
		primary_ref	=> 'print_ref',# generic_name => role_name,
		secondary_ref	=> 'match_ref',
	}

=back

B<Returns:> the $passed_ref (only) with the key names restored to the ones passed to this
method using the $conversion_ref.

=back

=head3 _build_branch( $seed_ref, @arg_list )

=over

B<Definition:> There are times when a role will wish to reconstruct the data branch
that lead from the 'zeroth' node to where the data walker is currently at.  This private
method takes a seed reference and uses data found in the L<branch ref
|/A position trace is generated> to recursivly append to the front of the seed until a
complete branch to the zeroth node is generated.  I<The branch_ref list must be
explicitly passed.>

B<Accepts:> a list of arguments starting with the $seed_ref to build from.
The remaining arguments are just the array elements of the 'branch ref'.

B<Example:>

	$ref = $self->_build_branch(
		$seed_ref,
		@{ $passed_ref->{branch_ref}},
	);

B<Returns:> a data reference with the current path back to the start pre-pended
to the $seed_ref

=back

=head3 _extracted_ref_type( $test_ref )

=over

B<Definition:> In order to manage data types necessary for this class a data
walker compliant 'Type' tester is provided.  This is necessary to support a few non
perl-standard types not generated in standard perl typing systems.  First, 'undef'
is the UNDEF type.  Second, strings and numbers both return as 'SCALAR' (not '' or undef).
B<Much of the code in this package runs on dispatch tables that are built around these
specific type definitions.>

B<Accepts:> It receives a $test_ref that can be undef.

B<Returns:> a data walker type or it confesses.

=back

=head3 _get_had_secondary

=over

B<Definition:> during the initial processing of data in
L<_process_the_data|/_process_the_data( $passed_ref, $conversion_ref )> the existence
of a passed secondary ref is tested and stored in the attribute '_had_secondary'.  On
occasion a role might need to know if a secondary ref existed at any level if it it is
not represented at the current level.

B<Accepts:> nothing

B<Returns:> True|1 if the secondary ref ever existed

=back

=head3 _get_current_level

=over

B<Definition:> on occasion you may need for one of the methods to know what
level is currently being parsed.  This will provide that information in integer
format.

B<Accepts:> nothing

B<Returns:> the integer value for the level

=back

=head2 Public Methods

=head3 add_sorted_nodes( NODETYPE => 1, )

=over

B<Definition:> This method is used to add nodes to be sorted to the walker by
adjusting the attribute L<sorted_nodes|/sorted_nodes>.

B<Accepts:> Node key => value pairs where the key is the Node name and the value is
1.  This method can accept multiple key => value pairs.

B<Returns:> nothing

=back

=head3 has_sorted_nodes

=over

B<Definition:> This method checks if any sorting is turned on in the attribute
L<sorted_nodes|/sorted_nodes>.

B<Accepts:> Nothing

B<Returns:> the count of sorted node types listed

=back

=head3 check_sorted_nodes( NODETYPE )

=over

B<Definition:> This method is used to see if a node type is sorted by testing the
attribute L<sorted_nodes|/sorted_nodes>.

B<Accepts:> the name of one node type

B<Returns:> true if that node is sorted as determined by L<sorted_nodes|/sorted_nodes>

=back

=head3 clear_sorted_nodes

=over

B<Definition:> This method will clear all values in the attribute
L<sorted_nodes|/sorted_nodes>.  I<and therefore turn off all cleared sorts>.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 remove_sorted_node( NODETYPE1, NODETYPE2, )

=over

B<Definition:> This method will clear the key / value pairs in L<sorted_nodes|/sorted_nodes>
for the listed items.

B<Accepts:> a list of NODETYPES to delete

B<Returns:> In list context it returns a list of values in the hash for the deleted
keys. In scalar context it returns the value for the last key specified

=back

=head3 set_sorted_nodes( $hashref )

=over

B<Definition:> This method will completely reset the attribute L<sorted_nodes|/sorted_nodes> to
$hashref.

B<Accepts:> a hashref of NODETYPE keys with the value of 1.

B<Returns:> nothing

=back

=head3 get_sorted_nodes

=over

B<Definition:> This method will return a hashref of the attribute L<sorted_nodes|/sorted_nodes>

B<Accepts:> nothing

B<Returns:> a hashref

=back

=head3 add_skipped_nodes( NODETYPE1 => 1, NODETYPE2 => 1 )

=over

B<Definition:> This method adds additional skip definition(s) to the
L<skipped_nodes|/skipped_nodes> attribute.

B<Accepts:> a list of key value pairs as used in 'skipped_nodes'

B<Returns:> nothing

=back

=head3 has_skipped_nodes

=over

B<Definition:> This method checks if any nodes are set to be skipped in the
attribute L<skipped_nodes|/skipped_nodes>.

B<Accepts:> Nothing

B<Returns:> the count of skipped node types listed

=back

=head3 check_skipped_node( $string )

=over

B<Definition:> This method checks if a specific node type is set to be skipped in
the L<skipped_nodes|/skipped_nodes> attribute.

B<Accepts:> a string

B<Returns:> Boolean value indicating if the specific $string is set

=back

=head3 remove_skipped_nodes( NODETYPE1, NODETYPE2 )

=over

B<Definition:> This method deletes specificily identified node skips from the
L<skipped_nodes|/skipped_nodes> attribute.

B<Accepts:> a list of NODETYPES to delete

B<Returns:> In list context it returns a list of values in the hash for the deleted
keys. In scalar context it returns the value for the last key specified

=back

=head3 clear_skipped_nodes

=over

B<Definition:> This method clears all data in the L<skipped_nodes|/skipped_nodes> attribute.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 set_skipped_nodes( $hashref )

=over

B<Definition:> This method will completely reset the attribute L<skipped_nodes|/skipped_nodes> to
$hashref.

B<Accepts:> a hashref of NODETYPE keys with the value of 1.

B<Returns:> nothing

=back

=head3 get_skipped_nodes

=over

B<Definition:> This method will return a hashref of the attribute L<skipped_nodes|/skipped_nodes>

B<Accepts:> nothing

B<Returns:> a hashref

=back

=head3 set_skip_level( $int )

=over

B<Definition:> This method is used to reset the L<skip_level|/skip_level>
attribute after the instance is created.

B<Accepts:> an integer (negative numbers and 0 will be ignored)

B<Returns:> nothing

=back

=head3 get_skip_level()

=over

B<Definition:> This method returns the current L<skip_level|/skip_level>
attribute.

B<Accepts:> nothing

B<Returns:> an integer

=back

=head3 has_skip_level()

=over

B<Definition:> This method is used to test if the L<skip_level|/skip_level> attribute is set.

B<Accepts:> nothing

B<Returns:> $Bool value indicating if the 'skip_level' attribute has been set

=back

=head3 clear_skip_level()

=over

B<Definition:> This method clears the L<skip_level|/skip_level> attribute.

B<Accepts:> nothing

B<Returns:> nothing (always successful)

=back

=head3 set_skip_node_tests( ArrayRef[ArrayRef] )

=over

B<Definition:> This method is used to change (completly) the 'skip_node_tests'
attribute after the instance is created.  See L<skip_node_tests|/skip_node_tests> for an example.

B<Accepts:> an array ref of array refs

B<Returns:> nothing

=back

=head3 get_skip_node_tests()

=over

B<Definition:> This method returns the current master list from the
L<skip_node_tests|/skip_node_tests> attribute.

B<Accepts:> nothing

B<Returns:> an array ref of array refs

=back

=head3 has_skip_node_tests()

=over

B<Definition:> This method is used to test if the L<skip_node_tests|/skip_node_tests> attribute
is set.

B<Accepts:> nothing

B<Returns:> The number of sub array refs there are in the list

=back

=head3 clear_skip_node_tests()

=over

B<Definition:> This method clears the L<skip_node_tests|/skip_node_tests> attribute.

B<Accepts:> nothing

B<Returns:> nothing (always successful)

=back

=head3 add_skip_node_tests( ArrayRef1, ArrayRef2 )

=over

B<Definition:> This method adds additional skip_node_test definition(s) to the the
L<skip_node_tests|/skip_node_tests> attribute list.

B<Accepts:> a list of array refs as used in 'skip_node_tests'.  These are 'pushed
onto the existing list.

B<Returns:> nothing

=back

=head3 set_change_array_size( $bool )

=over

B<Definition:> This method is used to (re)set the L<change_array_size|/change_array_size> attribute
after the instance is created.

B<Accepts:> a Boolean value

B<Returns:> nothing

=back

=head3 get_change_array_size()

=over

B<Definition:> This method returns the current state of the L<change_array_size|/change_array_size>
attribute.

B<Accepts:> nothing

B<Returns:> $Bool value representing the state of the 'change_array_size'
attribute

=back

=head3 has_change_array_size()

=over

B<Definition:> This method is used to test if the L<change_array_size|/change_array_size>
attribute is set.

B<Accepts:> nothing

B<Returns:> $Bool value indicating if the 'change_array_size' attribute
has been set

=back

=head3 clear_change_array_size()

=over

B<Definition:> This method clears the L<change_array_size|/change_array_size> attribute.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 set_fixed_primary( $bool )

=over

B<Definition:> This method is used to change the L<fixed_primary|/fixed_primary> attribute
after the instance is created.

B<Accepts:> a Boolean value

B<Returns:> nothing

=back

=head3 get_fixed_primary()

=over

B<Definition:> This method returns the current state of the L<fixed_primary|/fixed_primary>
attribute.

B<Accepts:> nothing

B<Returns:> $Bool value representing the state of the 'fixed_primary' attribute

=back

=head3 has_fixed_primary()

=over

B<Definition:> This method is used to test if the L<fixed_primary|/fixed_primary> attribute is set.

B<Accepts:> nothing

B<Returns:> $Bool value indicating if the 'fixed_primary' attribute has been set

=back

=head3 clear_fixed_primary()

=over

B<Definition:> This method clears the L<fixed_primary|/fixed_primary> attribute.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head1 Definitions

=head2 node

Each branch point of a data reference is considered a node.  The possible paths
deeper into the data structure from the node are followed 'vertically first' in
recursive parsing.  The original top level reference is considered the 'zeroth'
node.

=head2 base node type

Recursion 'base' node L<types|/_extracted_ref_type( $test_ref )> are considered
to not have any possible deeper branches.  Currently that list is SCALAR and UNDEF.

=head2 Supported node walking types

=over

=item ARRAY

=item HASH

=item SCALAR

=item UNDEF

I<Other node support>

Support for Objects is partially implemented and as a consequence '_process_the_data'
won't immediatly die when asked to parse an object.  It will still die but on a
dispatch table call that indicates where there is missing object support, not at the
top of the node.  This allows for some of the L<skip attributes|/skipped_nodes> to
use 'OBJECT' in their definitions.

=back

=head2 Supported one shot attributes

L<explanation|/Attributes>

=over

=item sorted_nodes

=item skipped_nodes

=item skip_level

=item skip_node_tests

=item change_array_size

=item fixed_primary

=back

=head2 Dispatch Tables

This class uses the role L<Data::Walk::Extracted::Dispatch
|https://metacpan.org/module/Data::Walk::Extracted::Dispatch> to implement dispatch
tables.  When there is a decision point, that role is used to make the class
extensible.

=head1 Caveat utilitor

This is not an extention of L<Data::Walk|https://metacpan.org/module/Data::Walk>

The core class has no external effect.  All output comes from
L<additions to the class|/Extending Data::Walk::Extracted>.

This module uses the 'L<defined or|http://perldoc.perl.org/perlop.html#Logical-Defined-Or>'
(  //= ) and so requires perl 5.010 or higher.

This is a L<Moose|https://metacpan.org/module/Moose::Manual> based data handling class.
Many coders will tell you Moose and data manipulation don't belong together.  They are
most certainly right in speed intensive circumstances.

Recursive parsing is not a good fit for all data since very deep data structures will
fill up a fair amount of memory!  Meaning that as the module recursively parses through
the levels it leaves behind snapshots of the previous level that allow it to keep
track of it's location.

The passed data references are effectivly deep cloned during this process.  To leave
the primary_ref pointer intact see L<fixed_primary|/fixed_primary>

=head1 Build/Install from Source

B<1.> Download a compressed file with the code

B<2.> Extract the code from the compressed file.  If you are using tar this should work:

        tar -zxvf Data-Walk-Extracted-v0.xx.xx.tar.gz

B<3.> Change (cd) into the extracted directory

B<4.> Run the following commands

=over

(For Windows find what version of make was used to compile your perl)

	perl  -V:make

(then for Windows substitute the correct make function (ex. s/make/dmake/g))

=back

	>perl Makefile.PL

	>make

	>make test

	>make install # As sudo/root

	>make clean

=head1 SUPPORT

=over

L<github Data-Walk-Extracted/issues|https://github.com/jandrew/Data-Walk-Extracted/issues>

=back

=head1 TODO

=over

B<1.> provide full recursion through Objects

B<2.> Support recursion through CodeRefs (Closures)

B<3.> Add a Data::Walk::Diff Role to the package

B<4.> Add a Data::Walk::Top Role to the package

B<5.> Add a Data::Walk::Thin Role to the package

B<6.> Convert test suite to Test2 direct usage

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

L<5.010|http://perldoc.perl.org/perl5100delta.html> (for use of
L<defined or|http://perldoc.perl.org/perlop.html#Logical-Defined-Or> //)

L<utf8>

L<Class::Inspector>

L<Scalar::Util>

L<Carp> - confess

L<Moose> - 2.1803

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<MooseX::Types::Moose>

L<Class::Inspector>

L<Scalar::Util> - reftype

L<MooseX::Types::Moose>

L<Data::Walk::Extracted::Types>

L<Data::Walk::Extracted::Dispatch>

=back

=head1 SEE ALSO

=over

L<Log::Shiras::Unhide> - Can use to unhide '###InternalExtracteD' tags

L<Log::Shiras::TapWarn> - to manage the output of exposed '###InternalExtracteD' lines

L<Data::Walk>

L<Data::Walker>

L<Data::Dumper> - Dumper

L<YAML> - Dump

L<Data::Walk::Print> - available Data::Walk::Extracted Role

L<Data::Walk::Prune> - available Data::Walk::Extracted Role

L<Data::Walk::Graft> - available Data::Walk::Extracted Role

L<Data::Walk::Clone> - available Data::Walk::Extracted Role

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9
