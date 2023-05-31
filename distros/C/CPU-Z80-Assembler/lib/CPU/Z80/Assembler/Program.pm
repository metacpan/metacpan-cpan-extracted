# $Id$

package CPU::Z80::Assembler::Program;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Assembler::Program - Represents one assembly program

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

our $VERSION = '2.25';

use CPU::Z80::Assembler::Parser;
use CPU::Z80::Assembler::Segment;
use CPU::Z80::Assembler::Expr;
use CPU::Z80::Assembler::Opcode;
use Data::Dump 'dump';


sub new { 
	my($class, %args) = @_;
	bless [
		$args{_segment_id},				# index of the current segment
		$args{_segment_map}	|| {}, 		# map segment name => index in child
		$args{child} 		|| [], 		# list of segments
		$args{symbols}		|| {},		# map name => Node with evaluate() method
		$args{macros}		|| {},		# list of defined macros
	], $class;
}
sub _segment_id		{ defined($_[1]) ? $_[0][0] = $_[1] : $_[0][0] }
sub _segment_map	{ defined($_[1]) ? $_[0][1] = $_[1] : $_[0][1] }
sub child 			{ defined($_[1]) ? $_[0][2] = $_[1] : $_[0][2] }
sub symbols 		{ defined($_[1]) ? $_[0][3] = $_[1] : $_[0][3] }
sub macros 			{ defined($_[1]) ? $_[0][4] = $_[1] : $_[0][4] }

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Assembler::Program;
  my $program = CPU::Z80::Assembler::Program->new(
                    symbols => {},
                    macros  => {});
  $program->parse($input);
  $segment = $program->segment;
  $segment = $program->segment("CODE");
  $segment = $program->split_segment;
  $program->add_opcodes(@opcodes);
  $program->add_label($name, $line);
  $program->org($address);
  $bytes = $program->bytes;
  $list_output = CPU::Z80::Assembler::List->new(input => \@input, output => \*STDOUT);
  $bytes = $program->bytes($list_output);

=head1 DESCRIPTION

This module defines the class that represents one assembly program composed of
L<CPU::Z80::Assembler::Segment|CPU::Z80::Assembler::Segment>.

=head1 EXPORTS

Nothing.

=head1 FUNCTIONS

=head2 new

Creates a new object, see L<Class::Struct|Class::Struct>.

=head2 child

Each child is one L<CPU::Z80::Assembler::Segment|CPU::Z80::Assembler::Segment> object, in the order found in the
program.

=head2 symbols

Hash of all symbols defined in the program. The key is the symbol name, and 
the value is either a scalar for a constant, a L<CPU::Z80::Assembler::Expr|CPU::Z80::Assembler::Expr> for 
an expression, or a L<CPU::Z80::Assembler::Opcode|CPU::Z80::Assembler::Opcode> for a label.

=head2 macros

Hash of macro names to L<CPU::Z80::Assembler::Macro|CPU::Z80::Assembler::Macro> objects for all defined macros.

=cut

#------------------------------------------------------------------------------

=head2 parse

  $program->parse($input);

Parse the assembly program and collect the opcodes into the object. $input is
a stream of tokens as retrieved by L<CPU::Z80::Assembler|CPU::Z80::Assembler>
C<z80lexer>.

=cut

#------------------------------------------------------------------------------

sub parse { my($self, $input) = @_;
	z80parser($input, $self);
}

#------------------------------------------------------------------------------

=head2 segment

Get/Set the current segment. The current segment is the one where new opcodes 
are added.

When called without arguments returns a L<CPU::Z80::Assembler::Segment|CPU::Z80::Assembler::Segment> object
of the current segment.

When called with a $name, it sets the segment with the given name as current.
If no such segment exists, a new segment with that name is appended to the list
and set current.

=cut

#------------------------------------------------------------------------------

sub segment { 
	my($self, $name) = @_;
	
	if (defined($name) || @{$self->child} == 0) {
		# set or get but still no segments -> create
		$name = "_" unless defined($name);
		
		my $id = $self->_segment_map->{$name};

		if (! defined $id) {
			# new segment
			$id = @{$self->child}; 				# index of new segment
			my $segment = CPU::Z80::Assembler::Segment->new(name => $name);
			push(@{$self->child}, $segment);
			
			$self->_segment_map->{$name} = $id;
		}
		# segment exists
		$self->_segment_id( $id );
		return $self->child->[$id];
	}
	else {
		# get
		return $self->child->[ $self->_segment_id ];
	}
}


#------------------------------------------------------------------------------
# creates a new name based on the given name, with a suffix number to make it
# unique
sub _build_name {
	my($self, $name) = @_;

	while (exists $self->_segment_map->{$name}) {
		$name =~ s/(\d*)$/ ($1 || 0) + 1/e;
	}
	return $name;
}

#------------------------------------------------------------------------------

=head2 split_segment

Splits the current segment at the current position, creating a new segment, 
inserting it just after the current one and setting it as current.

Returns the new current segment.

As a special case, if the current is empty, then nothing is done.

This is used to split one segment in two after a second ORG statement.

=cut

#------------------------------------------------------------------------------

sub split_segment {
	my($self) = @_;
	
	return $self->segment
		unless @{$self->segment->child};			# if empty, already split
	
	# segment id
	my $old_id = $self->_segment_id;
	my $new_id = $old_id + 1;
	
	# build a new name
	my $old_name = $self->segment->name;
	my $new_name = $self->_build_name( $old_name );
	
	# make space in the index map for a new item
	my $segment_map = $self->_segment_map;
	for (keys %$segment_map) {
		$segment_map->{$_}++ if $segment_map->{$_} >= $new_id;
	}
	$segment_map->{$new_name} = $new_id;
	
	# create the segment and insert it in the child list
	my $new_segment = CPU::Z80::Assembler::Segment->new(name => $new_name);
	splice( @{$self->child}, $new_id, 0, $new_segment );
	
	$self->_segment_id( $new_id );
	return $self->child->[ $new_id ];
}					
	
#------------------------------------------------------------------------------

=head2 add_opcodes

Adds the opcodes to the current segment.

=cut

#------------------------------------------------------------------------------

sub add_opcodes { 
	my($self, @opcodes) = @_;

	$self->segment->add(@opcodes) if @opcodes;
}

#------------------------------------------------------------------------------

=head2 add_label

Add a new label at the current position with given name and line. The line
is used for error messages and assembly listing.

It is an error to add a label twice with the same name.

=cut

#------------------------------------------------------------------------------

sub add_label { 
	my($self, $name, $line) = @_;
	
	my $opcode = CPU::Z80::Assembler::Opcode->new(
						child 	=> [],
						line	=> $line);
	$self->add_opcodes($opcode);
	if (exists $self->symbols->{$name}) {
		$line->error("duplicate label definition");
		die "not reached";
	}
	$self->symbols->{$name} = $opcode;
}

#------------------------------------------------------------------------------

=head2 org

Splits the current segment with split_segment() and sets the start address 
of the new current segment.

=cut

#------------------------------------------------------------------------------

sub org { 
	my($self, $address) = @_;
	
	$self->split_segment->address($address);
}

#------------------------------------------------------------------------------
# Allocate addresses for all child segments, starting at 
# the first segment's C<address> (defined by a "org" instruction), or at 0.
# Returns the first free address after the end of the last segment.
sub _locate { 
	my($self) = @_;
	
	my @jump_opcodes;
	$self->_locate_opcodes(0, \@jump_opcodes);		# preliminary addresses, get list of jumps
	$self->_check_short_jumps(\@jump_opcodes);		# change short to long junps, as needed
	$self->_locate_opcodes(1);						# final addresses
}

sub _locate_opcodes {
	my($self, $final, $jump_opcodes) = @_;
	
	return unless @{$self->child};		# if empty, nothing to do
	
	# define start address; only define segment address on final pass
	my $first = $self->child->[0];
	my $address = defined($first->address) ? 
						$first->address : 
						$final ? 
							$first->address( 0 ) :
							0;
	
	for my $segment_id (0 .. $#{$self->child}) {
		my $segment = $self->child->[$segment_id];

		# define start 
		if (defined($segment->address)) {
			# check for overlapping segments
			if ($segment->address < $address) {
				$segment->line->error(sprintf("segments overlap, previous ends at ".
								"0x%04X, next starts at 0x%04X",
								$address, $segment->address));
				die; # NOT REACHED
			}
			# check for new address
			elsif ($segment->address > $address) {
				$address = $segment->address;
			}
		}
		else {
			$segment->address( $address ) if $final;
		}
		
		# locate the segment
		for my $opcode_id (0 .. $#{$segment->child}) {
			my $opcode = $segment->child->[$opcode_id];
			
			$opcode->address($address);		# define opcode address
			if ($jump_opcodes && $opcode->can('short_jump_dist')) {
				push(@$jump_opcodes, [$address, $segment_id, $opcode_id]);
			}

			$address += $opcode->size;
		}
	}
	
	return $address;
}

# Jump opcodes -> list of [opcode_address, opcode], computed on the first call to _locate()
sub _check_short_jumps {
	my($self, $jump_opcodes) = @_;

	my $jumps = $self->_compute_slack($jump_opcodes);
	$self->_change_to_long_jump($jumps);
}

# compute slack and impacted jumps for each jump
sub _compute_slack {
	my($self, $jump_opcodes) = @_;

	my $jumps = {};
	my $symbols = $self->symbols;
	
	for (my $i = 0; $i < @$jump_opcodes; $i++) {
		my($address, $segment_id, $opcode_id) = @{$jump_opcodes->[$i]};
		my $opcode = $self->child->[$segment_id]->child->[$opcode_id];
		
		my $dist = $opcode->short_jump_dist($address, $symbols);
		
		$jumps->{$address}{segment_id} = $segment_id;
		$jumps->{$address}{opcode_id}  = $opcode_id;
		$jumps->{$address}{depends} = [];		# list of address of other jumps that reduce
												# their slack if we grow
		
		my $target = $address + 2 + $dist;
		if ($dist >= 0) {
			my $min_target = $address + 2 + 127;
			$min_target = $target if $target < $min_target;
			
			$jumps->{$address}{slack} = 127 - $dist;
			for ( my $j = $i + 1; 
				  $j < @$jump_opcodes && 
				  (my $depend_address = $jump_opcodes->[$j][0]) < $min_target; 
				  $j++ ) {
				push(@{$jumps->{$depend_address}{depends}}, $address);
			}
		}
		else {
			my $max_target = $address + 2 - 128;
			$max_target = $target if $target > $max_target;
			
			$jumps->{$address}{slack} = 128 + $dist;
			for ( my $j = $i - 1; 
				  $j >= 0 &&  
				  (my $depend_address = $jump_opcodes->[$j][0]) >= $max_target; 
				  $j-- ) {
				push(@{$jumps->{$depend_address}{depends}}, $address);
			}
		}
	}
	$jumps;
}

# go through the list of jumps and change all with negative slack to long jumps
# on each change reduce the slack of the dependent jumps accordingly
sub _change_to_long_jump {
	my($self, $jumps) = @_;
	
	my $changed;
	do {
		$changed = 0;
		for my $address (keys %$jumps) {
			my $jump = $jumps->{$address};
			if ($jump->{slack} < 0) {
				# need to change this
				my $segment_id = $jump->{segment_id};
				my $opcode_id  = $jump->{opcode_id};
				
				my $opcode = $self->child->[$segment_id]->child->[$opcode_id];
				my $inc_size = $opcode->long_jump->size - $opcode->short_jump->size;
				
				# discard the short jump
				$self->child->[$segment_id]->child->[$opcode_id] = $opcode->long_jump;
				
				# impact all dependents
				for my $depend_address (@{$jump->{depends}}) {
					exists $jumps->{$depend_address}
						and $jumps->{$depend_address}{slack} -= $inc_size;
				}
				
				# delete this from the list
				delete $jumps->{$address};
				
				$changed++;
			}
		}		
	} while ($changed);
}	
		
#------------------------------------------------------------------------------

=head2 bytes

Allocate addresses for all child segments, starting at 
the first segment's C<address> (defined by a "org" instruction), or at 0.

Computes the bytes of each segment, and concatenates them together. Returns the
complete object code.

Gaps between segments are filled with $CPU::Z80::Assembler::fill_byte.

$list_output is an optional L<CPU::Z80::Assembler::List|CPU::Z80::Assembler::List> object to dump the assembly
listing to.

=cut

#------------------------------------------------------------------------------

sub bytes { 
	my($self, $list_output) = @_;

	return "" unless @{$self->child};		# if empty, nothing to do

	my $symbols = $self->symbols;
	
	# locate the code
	$self->_locate;
	
	# get start address
	my $address = $self->child->[0]->address;

	# char used to fill gaps between segments
	my $fill_byte = defined($CPU::Z80::Assembler::fill_byte) ? 
						chr($CPU::Z80::Assembler::fill_byte) :
						chr(0xFF);

	my $bytes = "";
	for my $segment (@{$self->child}) {
		
		# fill in the gap, if any
		my $segment_address = $segment->address;
		if (length($bytes) && $address != $segment_address) {
			my $fill = $segment_address - $address;
			die if $fill < 0; # ASSERT

			$bytes .= $fill_byte x $fill;
			$address = $segment_address;
		}

		# fill segment bytes
		for my $opcode (@{$segment->child}) {
			$opcode->address($address);
			my $opcode_bytes = $opcode->bytes($address, $symbols);
			$bytes .= $opcode_bytes;
			
			$list_output->add($opcode->line, $address, $opcode_bytes) if ($list_output);
			
			$address += $opcode->size;
		}
	}
	return $bytes;
}

#------------------------------------------------------------------------------

=head1 BUGS and FEEDBACK

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=head1 SEE ALSO

L<CPU::Z80::Assembler|CPU::Z80::Assembler>
L<CPU::Z80::Assembler::Segment|CPU::Z80::Assembler::Segment>
L<CPU::Z80::Assembler::Parser|CPU::Z80::Assembler::Parser>
L<Class::Struct|Class::Struct>

=head1 AUTHORS, COPYRIGHT and LICENCE

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=cut

#------------------------------------------------------------------------------

1;
