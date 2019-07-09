package CPU::Z80::Disassembler::Label;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Disassembler::Label - Label used in the disassembled program

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

use CPU::Z80::Disassembler::Format;

our $VERSION = '0.07';

#------------------------------------------------------------------------------

=head1 SYNOPSYS

  $label = CPU::Z80::Disassembler::Label->new($addr, $name, @from_addr);
  $label->add_refer(@from_addr);
  my @refer = $label->refer_from;
  print $label->label_string;
  print $label->equ_string;

=head1 DESCRIPTION

Represents one label in the disassembled program. The label contains a name, an
address and a list of addresses of opcodes that refer to it.

=head1 FUNCTIONS

=head2 new

Creates a new object.

=head2 name

Gets/sets the label name.

=head2 comment

Gets/sets the comment to add to the definition of the label.

=head2 addr

Gets the label address. The address cannot be modified.

=cut

#------------------------------------------------------------------------------
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(
		'name',			# name
		'comment',		# comment to add to label when defining
		'addr',			# address
		'_refer',		# hash of reference address
);

sub new {
	my($class, $addr, $name, @from_addr) = @_;
	croak("invalid name".(defined($name) ? " '$name'" : "")) 
		unless defined($name) && $name =~ /^[a-z_]\w*$/i;
	croak("invalid address".(defined($addr) ? " '$addr'" : ""))
		unless defined($addr) && $addr =~ /^\d+$/;
		
	my $self = bless {	name => $name, addr => $addr, 
						_refer => {},
					}, $class;
	$self->add_refer(@from_addr) if @from_addr;
	return $self;
}
#------------------------------------------------------------------------------

=head2 add_refer

Add the given addresses as references to this label, i.e. places from where 
this label is used.

=cut

#------------------------------------------------------------------------------
sub add_refer {
	my($self, @from_addr) = @_;
	$self->_refer->{$_}++ for (@from_addr);
}

#------------------------------------------------------------------------------

=head2 refer_from

Return the list of all addresses from which this label is used.

=cut

#------------------------------------------------------------------------------
sub refer_from {
	my($self) = @_;
	return sort {$a <=> $b} keys %{$self->_refer};
}

#------------------------------------------------------------------------------

=head2 label_string

Returns the string to be used in an assembly file to define this label
at the current location counter:

  LABEL:            ; COMMENT

=cut

#------------------------------------------------------------------------------
sub label_string {
	my($self) = @_;
	my $opcode = $self->name.":";
	return $self->_format_comment($opcode)."\n";
}
#------------------------------------------------------------------------------

=head2 equ_string

Returns the string to be used in an assembly file to define this label
as a constant:

  LABEL equ ADDR    ; COMMENT

=cut

#------------------------------------------------------------------------------
sub equ_string {
	my($self, $field_width) = @_;
	$field_width ||= 12;
	my $opcode = sprintf("%-*s equ %s", $field_width-1, $self->name, 
						 format_hex4($self->addr));
	return $self->_format_comment($opcode)."\n";
}

sub _format_comment {
	my($self, $opcode) = @_;
	
	my $comment = $self->comment;
	if (defined $comment) {
		$comment =~ s/\n/ "\n" . " " x 32 . "; " /ge;	# multi-line comment
	}
	
	return !defined($comment) ? 
				$opcode :
				length($opcode) >= 32 ?
					$opcode . "\n" . " " x 32 . "; " . $comment :
					sprintf("%-32s; %s", $opcode, $comment);
}

#------------------------------------------------------------------------------

=head1 BUGS, FEEDBACK, AUTHORS, COPYRIGHT and LICENCE

See L<CPU::Z80::Disassembler|CPU::Z80::Disassembler>.

=cut

1;
