package Data::Walk::Print;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.28.0');
###InternalExtracteDPrinT	warn "You uncovered internal logging statements for Data::Walk::Print-$VERSION";
###InternalExtracteDPrinT	use Data::Dumper;
use 5.010;
use utf8;
use Moose::Role;
requires qw(
	_get_had_secondary		_process_the_data			_dispatch_method
);
use MooseX::Types::Moose qw( Str Bool HashRef Num );

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

$| = 1;
my $print_keys = {
    print_ref => 'primary_ref',
    match_ref => 'secondary_ref',
};

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my	$before_pre_string_dispatch ={######<-----------------------------  ADD New types here
		HASH => \&_before_hash_pre_string,
		ARRAY => \&_before_array_pre_string,
		DEFAULT => sub{ 0 },
		name => 'print - before pre string dispatch',
		###### Receives: the current $passed_ref and the last branch_ref array
		###### Returns: nothing
		###### Action: adds the necessary pre string and match string
		######           for the currently pending position
	};


my 	$before_method_dispatch ={######<----------------------------------  ADD New types here
		HASH => \&_before_hash_printing,
		ARRAY => \&_before_array_printing,
		OBJECT => \&_before_object_printing,
		DEFAULT => sub{ 0 },
		name => 'print - before_method_dispatch',
		###### Receives: the passed_ref
		###### Returns: 1|0 if the string should be printed
		###### Action: adds the necessary before string and match string to the currently
		######           pending line
	};

my 	$after_method_dispatch ={######<-----------------------------------  ADD New types here
		UNDEF => \&_after_undef_printing,
		SCALAR => \&_after_scalar_printing,
		HASH => \&_after_hash_printing,
		ARRAY => \&_after_array_printing,
		OBJECT => \&_after_object_printing,
		name => 'print - after_method_dispatch',
		###### Receives: the passed_ref
		###### Returns: 1|0 if the string should be printed
		###### Action: adds the necessary after string and match string to the currently
		######           pending line
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'match_highlighting' =>(
    is      	=> 'ro',
    isa     	=> Bool,
    writer  	=> 'set_match_highlighting',
	predicate	=> 'has_match_highlighting',
	reader		=> 'get_match_highlighting',
	clearer		=> 'clear_match_highlighting',
    default 	=> 1,
);

has 'to_string' =>(
    is      	=> 'ro',
    isa     	=> Bool,
	reader		=> 'get_to_string',
    writer  	=> 'set_to_string',
	predicate	=> 'has_to_string',
	clearer		=> 'clear_to_string',
    default 	=> 0,
);


#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub print_data{
    my ( $self, @args )= @_;
    ###InternalExtracteDPrinT	warn "Made it to print with input" . Dumper( @args );
    my  $passed_ref =
            @args == 1 ? 
				( is_HashRef( $args[0] ) ? 
					( !exists $args[0]->{print_ref} ? { print_ref => $args[0] } : $args[0] ) :
					{ print_ref => $args[0] } 													) :
                { @args } ;
	###InternalExtracteDPrinT	warn "Resolved hashref:" . Dumper( $passed_ref );
    @$passed_ref{ 'before_method', 'after_method' } =
        ( '_print_before_method', '_print_after_method' );
    ###InternalExtracteDPrinT	warn "Start recursive parsing with:" . Dumper( $passed_ref );
    $passed_ref = $self->_process_the_data( $passed_ref, $print_keys );
    ###InternalExtracteDPrinT	warn "End recursive parsing with:" . Dumper( $passed_ref );
	my $return = ( $self->get_to_string ) ? $self->_get_final_string : 1;
	$self->_clear_final_string;
    return $return;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has '_pending_string' =>(
    isa         => Str,
    writer      => '_set_pending_string',
    clearer     => '_clear_pending_string',
    predicate   => '_has_pending_string',
	reader		=> '_get_pending_string',
);

has '_match_string' =>(
    isa         => Str,
    writer      => '_set_match_string',
    clearer     => '_clear_match_string',
    predicate   => '_has_match_string',
	reader		=> '_get_match_string',
);

has '_final_string' =>(
    isa         => Str,
    traits  	=> ['String'],
    writer      => '_set_final_string',
    clearer     => '_clear_final_string',
    predicate   => '_has_final_string',
	reader		=> '_get_final_string',
    handles => {
        _add_to_final_string => 'append',
    },
    default => q{},
);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _print_before_method{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached before_method with input:" . Dumper( $passed_ref );
	my ( $should_print );
	if( 	$self->get_match_highlighting and
			!$self->_has_match_string 			){
		$self->_set_match_string( '#<--- ' );
	}
	###InternalExtracteDPrinT	warn "add before pre-string ...";
	if( $self->_get_current_level ){
		###InternalExtracteDPrinT	warn "only available at level 1 + ...";
		$self->_dispatch_method(
			$before_pre_string_dispatch,
			$passed_ref->{branch_ref}->[-1]->[0],
			$passed_ref,
			$passed_ref->{branch_ref}->[-1],
		);
	}
	###InternalExtracteDPrinT	warn "printing reference bracket ...";
	if( $passed_ref->{skip} eq 'NO' ){
		$should_print = $self->_dispatch_method(
			$before_method_dispatch,
			$passed_ref->{primary_type},
			$passed_ref,
		);
	}else{
		###InternalExtracteDPrinT	warn "Found a skip - handling it in the after_method ...";
	}
	###InternalExtracteDPrinT	warn "print as needed ...";
    if( $should_print ){
		###InternalExtracteDPrinT	warn "found a line that should print ...";
        $self->_print_pending_string;
    }
    ###InternalExtracteDPrinT	warn "leaving before_method";
	return $passed_ref;
}

sub _print_after_method{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached the print after_method with input:" . Dumper( $passed_ref );
	my  $should_print = $self->_dispatch_method(
		$after_method_dispatch,
		$passed_ref->{primary_type},
		$passed_ref,
	);
	###InternalExtracteDPrinT	warn "Testing should Print with: $should_print";
    if( $should_print ){
		###InternalExtracteDPrinT	warn "found a line that should print ...";
        $self->_print_pending_string;
    }
    ###InternalExtracteDPrinT	warn "after_method complete returning:" . Dumper( $passed_ref );
    return $passed_ref;
}

sub _add_to_pending_string{
    my ( $self, $string ) = @_;
    ###InternalExtracteDPrinT	warn "reached _add_to_pending_string with: $string";
    $self->_set_pending_string(
        (($self->_has_pending_string) ?
            $self->_get_pending_string : '') .
        ( ( $string ) ? $string : '' )
    );
    return 1;
}

sub _add_to_match_string{
    my ( $self, $string ) = @_;
    ###InternalExtracteDPrinT	warn "reached _add_to_match_string with: $string";
    $self->_set_match_string(
        (($self->_has_match_string) ?
            $self->_get_match_string : '') .
        ( ( $string ) ? $string : '' )
    );
    return 1;
}

sub _print_pending_string{
    my ( $self, $input ) = @_;
    ###InternalExtracteDPrinT	warn "reached print pending string with input:" . Dumper( $input );
	###InternalExtracteDPrinT	warn "match_highlighting set ?:" . $self->has_match_highlighting;
	###InternalExtracteDPrinT	warn "match_highlighting on:" . $self->get_match_highlighting if $self->has_match_highlighting;
	###InternalExtracteDPrinT	warn "secondary_ref exists:" . $self->_get_had_secondary;
	###InternalExtracteDPrinT	warn "has pending match string:" . $self->_has_match_string;
    if( $self->_has_pending_string ){
        my	$new_string = $self->_add_tabs( $self->_get_current_level );
			$new_string .= $self->_get_pending_string;
			$new_string .= $input if $input;
            if(	$self->has_match_highlighting and
                $self->get_match_highlighting and
                $self->_get_had_secondary and
                $self->_has_match_string        ){
                ###InternalExtracteDPrinT	warn "match_highlighting on - adding match string";
                $new_string .= $self->_get_match_string;
            }
            $new_string .= "\n";
        ###InternalExtracteDPrinT	warn "printing string: $new_string";
		if( $self->get_to_string ){
			$self->_add_to_final_string( $new_string );
		}else{
			print  $new_string;
		}
    }
    $self->_clear_pending_string;
    $self->_clear_match_string;
    return 1;
}

sub _before_hash_pre_string{
    my ( $self, $passed_ref, $branch_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached _before_hash_pre_string with:" . Dumper( $passed_ref );
	$self->_add_to_pending_string( $branch_ref->[1] . ' => ' );
	$self->_add_to_match_string(
		( $passed_ref->{secondary_type} ne 'DNE' ) ?
			'Hash Key Match - ' : 'Hash Key Mismatch - '
	);
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	###InternalExtracteDPrinT	warn "current match string:" . $self->_get_match_string;
}

sub _before_array_pre_string{
    my ( $self, $passed_ref, $branch_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached _before_array_pre_string with:" . Dumper( $passed_ref );
	$self->_add_to_match_string(
		( $passed_ref->{secondary_type} ne 'DNE' ) ?
			'Position Exists - ' : 'No Matching Position - '
	);
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	###InternalExtracteDPrinT	warn "current match string:" . $self->_get_match_string;
}

sub _before_hash_printing{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached _before_hash_printing ...";
	$self->_add_to_pending_string( '{' );
	$self->_add_to_match_string(
		( $passed_ref->{secondary_type} eq 'HASH' ) ?
			'Ref Type Match' : 'Ref Type Mismatch'
	);
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	###InternalExtracteDPrinT	warn "current match string:" . $self->_get_match_string;
    return 1;
}

sub _before_array_printing{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached _before_array_printing with:" . Dumper( $passed_ref );
	$self->_add_to_pending_string( '[' );
	$self->_add_to_match_string(
		( $passed_ref->{secondary_type} eq 'ARRAY' ) ?
			'Ref Type Match' : 'Ref Type Mismatch'
	);
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	###InternalExtracteDPrinT	warn "current match string:" . $self->_get_match_string;
    return 1;
}

sub _before_object_printing{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached _before_object_printing with:" . Dumper( $passed_ref );
	$self->_add_to_pending_string( 'BLESS : [' );
	$self->_add_to_match_string(
		( $passed_ref->{secondary_type} eq 'ARRAY' ) ?
			'Ref Type Match' : 'Ref Type Mismatch'
	);
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	###InternalExtracteDPrinT	warn "current match string:" . $self->_get_match_string;
    return 1;
}

sub _after_scalar_printing{
    my ( $self, $passed_ref, ) = @_;
    ###InternalExtracteDPrinT	warn "reached _after_scalar_printing with:" . Dumper( $passed_ref );
	$self->_add_to_pending_string(
		(
			( is_Num( $passed_ref->{primary_ref} )  ) ?
				$passed_ref->{primary_ref} :
				"'$passed_ref->{primary_ref}'"
		) . ','
	);
	$self->_add_to_match_string(
		( $passed_ref->{match} eq 'YES' ) ?
			'Scalar Value Matches' :
			'Scalar Value Does NOT Match'
	);
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	###InternalExtracteDPrinT	warn "current match string:" . $self->_get_match_string;
	return 1;
}

sub _after_undef_printing{
    my ( $self, $passed_ref, ) = @_;
    ###InternalExtracteDPrinT	warn "reached _after_scalar_printing with:" . Dumper( $passed_ref );
	$self->_add_to_pending_string(
		"undef,"
	);
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	return 1;
}

sub _after_array_printing{
    my ( $self, $passed_ref ) = @_;
    ###InternalExtracteDPrinT	warn "reached _after_array_printing with:" . Dumper( $passed_ref );
	if( $passed_ref->{skip} eq 'YES' ){
		$self->_add_to_pending_string( $passed_ref->{primary_ref} . ',' );
	}else{
		$self->_add_to_pending_string( '],' );
	}
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	return 1;
}

sub _after_hash_printing{
    my ( $self, $passed_ref, $skip_method ) = @_;
    ###InternalExtracteDPrinT	warn "reached _after_hash_printing with:" . Dumper( $passed_ref );
	if( $passed_ref->{skip} eq 'YES' ){
		$self->_add_to_pending_string( $passed_ref->{primary_ref} . ',' );
	}else{
		$self->_add_to_pending_string( '},' );
	}
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	return 1;
}

sub _after_object_printing{
    my ( $self, $passed_ref, $skip_method ) = @_;
    ###InternalExtracteDPrinT	warn "reached _after_object_printing with:" . Dumper( $passed_ref );
	if( $passed_ref->{skip} eq 'YES' ){
		$self->_add_to_pending_string( $passed_ref->{primary_ref} . ',' );
	}else{
		$self->_add_to_pending_string( '},' );
	}
	###InternalExtracteDPrinT	warn "current pending string:" . $self->_get_pending_string;
	return 1;
}

sub _add_tabs{
    my ( $self, $current_level ) = @_;
    ###InternalExtracteDPrinT	warn "reached _add_tabs with current level: $current_level";
    return ("\t" x $current_level);
}

#########1 Phinish Strong     3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 Main POD starts    3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Data::Walk::Print - A data printing function

=head1 SYNOPSIS

	#!perl
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use YAML::Any;
	use Data::Walk::Extracted;
	use Data::Walk::Print;

	#Use YAML to compress writing the data ref
	my  $firstref = Load(
		'---
		Someotherkey:
			value
		Parsing:
			HashRef:
				LOGGER:
					run: INFO
		Helping:
			- Somelevel
			- MyKey:
				MiddleKey:
					LowerKey1: lvalue1
					LowerKey2:
						BottomKey1: 12345
						BottomKey2:
						- bavalue1
						- bavalue2
						- bavalue3'
	);
	my  $secondref = Load(
		'---
		Someotherkey:
			value
		Helping:
			- Somelevel
			- MyKey:
				MiddleKey:
					LowerKey1: lvalue1
					LowerKey2:
						BottomKey2:
						- bavalue1
						- bavalue3
						BottomKey1: 12354'
	);
	my $AT_ST = build_instance( 
			package => 'Gutenberg',
			superclasses =>['Data::Walk::Extracted'],
			roles =>[qw( Data::Walk::Print )],
			match_highlighting => 1,#This is the default
		);
	$AT_ST->print_data(
		print_ref	=>  $firstref,
		match_ref	=>  $secondref,
		sorted_nodes =>{
			HASH => 1, #To force order for demo purposes
		}
	);

	#################################################################################
	#     Output of SYNOPSIS
	# 01:{#<--- Ref Type Match
	# 02:	Helping => [#<--- Secondary Key Match - Ref Type Match
	# 03:		'Somelevel',#<--- Secondary Position Exists - Secondary Value Matches
	# 04:		{#<--- Secondary Position Exists - Ref Type Match
	# 05:			MyKey => {#<--- Secondary Key Match - Ref Type Match
	# 06:				MiddleKey => {#<--- Secondary Key Match - Ref Type Match
	# 07:					LowerKey1 => 'lvalue1',#<--- Secondary Key Match - Secondary Value Matches
	# 08:					LowerKey2 => {#<--- Secondary Key Match - Ref Type Match
	# 09:						BottomKey1 => '12345',#<--- Secondary Key Match - Secondary Value Does NOT Match
	# 10:						BottomKey2 => [#<--- Secondary Key Match - Ref Type Match
	# 11:							'bavalue1',#<--- Secondary Position Exists - Secondary Value Matches
	# 12:							'bavalue2',#<--- Secondary Position Exists - Secondary Value Does NOT Match
	# 13:							'bavalue3',#<--- Secondary Position Does NOT Exist - Secondary Value Does NOT Match
	# 14:						],
	# 15:					},
	# 16:				},
	# 17:			},
	# 18:		},
	# 19:	],
	# 20:	Parsing => {#<--- Secondary Key Mismatch - Ref Type Mismatch
	# 21:		HashRef => {#<--- Secondary Key Mismatch - Ref Type Mismatch
	# 22:			LOGGER => {#<--- Secondary Key Mismatch - Ref Type Mismatch
	# 23:				run => 'INFO',#<--- Secondary Key Mismatch - Secondary Value Does NOT Match
	# 24:			},
	# 25:		},
	# 26:	},
	# 27:	Someotherkey => 'value',#<--- Secondary Key Match - Secondary Value Matches
	# 28:},
	#################################################################################


=head1 DESCRIPTION

This L<Moose::Role|https://metacpan.org/module/Moose::Manual::Roles> is mostly written
as a demonstration module for L<Data::Walk::Extracted>. 
Both L<Data::Dumper|Data::Dumper/Functions> - Dumper and L<YAML|YAML/SUBROUTINES> 
- Dump functions are more mature than the printing function included here.

=head2 USE

This is a L<Moose::Role> specifically
designed to be used with L<Data::Walk::Extracted
|Data::Walk::Extracted/Extending Data::Walk::Extracted> It can be combined traditionaly 
to the ~::Extracted class using L<Moose::Roles> or for information on how to join
this role to Data::Walk::Extracted at run time see L<Moose::Util> or 
L<MooseX::ShortCut::BuildInstance> for more information.

=head1 Attributes

Data passed to -E<gt>new when creating an instance.  For modification of these attributes
see L<Methods|/Methods>.  The -E<gt>new function will either accept fat comma lists or a
complete hash ref that has the possible attributes as the top keys.  Additionally
some attributes that have all the following methods; get_$attribute, set_$attribute,
has_$attribute, and clear_$attribute, can be passed to L<print_data
|/print_data( $arg_ref|%args|$data_ref )> and will be adjusted for just the run of that
method call.  These are called 'one shot' attributes.  The class and each role (where
applicable) in this package have a list of L<supported one shot attributes
|/Supported one shot attributes>.

=head2 match_highlighting

=over

B<Definition:> this determines if a comments string is added after each printed
row that indicates how the 'print_ref' matches the 'match_ref'.

B<Default> True (1)

B<Range> This is a Boolean data type and generally accepts 1 or 0

=back

=head2 to_string

=over

B<Definition:> this determines whether the output is sent to STDOUT or coallated
into a final string and sent as a result of L<print_data
|/print_data( $arg_ref|%args|$data_ref )>.

B<Default> True (1)

B<Range> This is a Boolean data type and generally accepts 1 or 0

=back

=head2 (see also)

L<Data::Walk::Extracted|https://metacpan.org/module/Data::Walk::Extracted#Attributes>
- Attributes

=head1 Methods

=head2 print_data( $arg_ref|%args|$data_ref )

=over

B<Definition:> this is the method used to print a data reference

B<Accepts:> either a single data reference or named arguments
in a fat comma list or hashref

=over

B<named variable option> - if data comes in a fat comma list or as a hash ref
and the keys include a 'print_ref' key then the list is processed as follows.

=over

B<print_ref> - this is the data reference that should be printed in a perlish way
- Required

B<match_ref> - this is a reference used to compare against the 'print_ref'
- Optional

B<[attribute name]> - attribute names are accepted with temporary attribute settings.
These settings are temporarily set for a single "print_data" call and then the original
attribute values are restored.  For this to work the the attribute must meet the
L<necessary criteria|/Attributes>.  These attributes can include all attributes active
for the constructed class not just this role.

=back

B<single variable option> - if only one data_ref is sent and it fails the test
for "exists $data_ref->{print_ref}" then the program will attempt to name it as
print_ref => $data_ref and then process the data as a fat comma list.

=back

B<Returns:> 1 (And prints out the data ref) or a string - see L<to_string|/to_string>

=back

=head2 set_match_highlighting( $bool )

=over

B<Definition:> this is a way to change the L<match_highlighting|/match_highlighting>
attribute

B<Accepts:> a Boolean value

B<Returns:> ''

=back

=head2 get_match_highlighting

=over

B<Definition:> this is a way to view the state of the L<match_highlighting|/match_highlighting>
attribute

B<Accepts:> nothing

B<Returns:> The current 'match_highlighting' state

=back

=head2 has_match_highlighting

=over

B<Definition:> this is a way to know if the L<match_highlighting|/match_highlighting>
attribute is active

B<Accepts:> nothing

B<Returns:> 1 if the attribute is active (not just if it == 1)

=back

=head2 clear_match_highlighting

=over

B<Definition:> this clears the L<match_highlighting|/match_highlighting> attribute

B<Accepts:> nothing

B<Returns:> '' (always successful)

=back

=head2 set_to_string( $bool )

=over

B<Definition:> this is a way to change the L<to_string|/to_string>
attribute

B<Accepts:> a Boolean value

B<Returns:> ''

=back

=head2 get_to_string

=over

B<Definition:> this is a way to view the state of the L<to_string|/to_string>
attribute

B<Accepts:> nothing

B<Returns:> The current 'to_string' state

=back

=head2 has_to_string

=over

B<Definition:> this is a way to know if the L<to_string|/to_string>
attribute is active

B<Accepts:> nothing

B<Returns:> 1 if the attribute is active (not just if it == 1)

=back

=head2 clear_to_string

=over

B<Definition:> this clears the L<to_string|/to_string> attribute

B<Accepts:> nothing

B<Returns:> '' (always successful)

=back

=head1 Caveat utilitor

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

=item match_highlighting

=item to_string

=back

=head2 Printing for skipped nodes

L<Data::Walk::Extracted|https://metacpan.org/module/Data::Walk::Extracted> allows for some
nodes to be skipped.  When a node is skipped the L<print_data
|/print_data( $arg_ref|%args|$data_ref )> function prints the scalar (perl pointer description)
of that node.

=head1 SUPPORT

=over

L<github Data-Walk-Extracted/issues|https://github.com/jandrew/Data-Walk-Extracted/issues>

=back

=head1 TODO

=over

B<1.> Support printing Objects / Instances

B<2.> Support printing CodeRefs

B<3.> Support REF types

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

L<version>

L<utf8>

L<Moose::Role>

=over

B<requires>

=over

=item _process_the_data

=item _get_had_secondary

=item _dispatch_method

=back

=back

L<MooseX::Types::Moose>

L<Data::Walk::Extracted>


=head1 SEE ALSO

=over

L<Log::Shiras::Unhide> - Can use to unhide '###InternalExtracteDGrafT' tags

L<Log::Shiras::TapWarn> - to manage the output of exposed '###InternalExtracteDGrafT' lines

L<Data::Dumper> - used in the '###InternalExtracteDGrafT' lines

L<Data::Walk>

L<Data::Walker>

L<Data::Dumper> - Dumper

L<YAML> - Dump

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9
