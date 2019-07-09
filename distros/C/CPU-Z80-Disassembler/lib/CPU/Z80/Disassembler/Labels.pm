package CPU::Z80::Disassembler::Labels;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Disassembler::Labels - All labels used in the disassembled program

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use Bit::Vector;

use CPU::Z80::Disassembler::Label;
use CPU::Z80::Disassembler::Format;

our $VERSION = '0.07';

#------------------------------------------------------------------------------

=head1 SYNOPSYS

  $labels = CPU::Z80::Disassembler::Labels->new();
  $labels->add($addr, $name, $from_addr);
  $found = $labels->search_addr($addr);
  $found = $labels->search_name($name);
  @labels = $labels->search_all;
  print $labels->max_length;
  $label = $labels->next_label($addr);

=head1 DESCRIPTION

Contains an indexed list of all L<CPU::Z80::Diassembler::Label> labels
in the disassembled program. 

Each label is created by the add()
method, that simultaneously prepares the indexes for a fast search. There are also
methods to search for labels at a given address of with a given name.

This module assumes that the address of a label does not change after being defined,
i.e. there is never the need to reindex all labels.

=head1 FUNCTIONS

=head2 new

Creates a new empty object.

=cut

#------------------------------------------------------------------------------
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(
		'_by_addr',			# array of labels by address
		'_by_name',			# hash of labels by name
		'max_length',		# max length of all defined labels
		'_has_label',		# Bit::Vector, one bit per address, 1 if label
							# exists at that address
);

sub new {
	my($class) = @_;
	my $has_label = Bit::Vector->new(0x10000);
	return bless {	_by_addr 	=> [], 
					_by_name 	=> {}, 
					max_length 	=> 0,
					_has_label	=> $has_label,
				}, $class;
}
#------------------------------------------------------------------------------

=head2 add

Creates and adds a new label to the indexes. If the same name and address as an
existing label is given then the $from_addr is updated.

If the name is not given, creates a temporary label of the form L_HHHH.

It is an error to add a label already added with a different address.

=head2 max_length

Length of the longest label name of all defined labels. This is updated when
a label is added to the index, and can be used for formating label lists in columns.

=cut

#------------------------------------------------------------------------------
sub add {
	my($self, $addr, $name, $from_addr) = @_;

	my $temp_name = sprintf("L_%04X", $addr);

	# check for dupplicate names
	my $label;
	if ( defined($name) && 
		 defined($label = $self->_by_name->{$name}) && 
		 $label->addr != $addr
	   ) {
		croak("Label '$name' with addresses ".format_hex4($label->addr).
			  " and ".format_hex4($addr));
	}
	
	# check for dupplicate address
	if (! defined($label = $self->_by_addr->[$addr])) {
	
		$label = CPU::Z80::Disassembler::Label
				->new($addr, $name || $temp_name);
				
		# create index
		$self->_by_addr->[$addr] = 
			$self->_by_name->{$label->name} = 
				$label;
		$self->_has_label->Bit_On($addr);
	}
	else {
		# label at that address exists
		if ( defined($name) && 
			 $label->name eq $temp_name) {	
			
			# temp label was given a name
			$label->name($name);
			
			delete $self->_by_name->{$temp_name};
			$self->_by_name->{$name} = $label;
		}
		elsif ( defined($name) && 
				$label->name ne $name) {
			
			# label renamed
			croak("Labels '".$label->name."' and '$name' at the same address ".
				  format_hex4($addr));
		}
		else {
			# OK, same address and name
		}
	}
	
	# define max length
	my $length = length($label->name);
	$self->max_length($length) if $length > $self->max_length;

	# add references
	$label->add_refer($from_addr) if defined $from_addr;
	
	return $label;
}
#------------------------------------------------------------------------------

=head2 search_addr

Return the label object defined at the given address, undef if none.

=cut

#------------------------------------------------------------------------------
sub search_addr {
	my($self, $addr) = @_;
	
	return $self->_by_addr->[$addr];
}
#------------------------------------------------------------------------------

=head2 search_name

Return the label object with the given name, undef if none.

=cut

#------------------------------------------------------------------------------
sub search_name {
	my($self, $name) = @_;
	
	return $self->_by_name->{$name};
}
#------------------------------------------------------------------------------

=head2 search_all

Return all the defined label objects.

=cut

#------------------------------------------------------------------------------
sub search_all {
	my($self) = @_;
	
	return sort {$a->name cmp $b->name} values %{$self->_by_name};
}
#------------------------------------------------------------------------------

=head2 next_label

Return the first label defined on the given address or after. If no address
is given, returns the first defined label.
Returns undef if there is no label on the address or after.

This can be used to find the next label after the current instruction.

=cut

#------------------------------------------------------------------------------
sub next_label {
	my($self, $addr) = @_;
	$addr ||= 0;
	
	if (my($min,$max) = $self->_has_label->Interval_Scan_inc($addr)) {
		return $self->search_addr($min);
	}
	else {
		return undef;
	}
}
#------------------------------------------------------------------------------

=head1 BUGS, FEEDBACK, AUTHORS, COPYRIGHT and LICENCE

See L<CPU::Z80::Disassembler|CPU::Z80::Disassembler>.

=cut

1;
