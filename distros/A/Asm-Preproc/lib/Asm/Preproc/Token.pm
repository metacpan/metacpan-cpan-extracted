# $Id: Token.pm,v 1.6 2013/07/26 01:57:26 Paulo Exp $

package Asm::Preproc::Token;

#------------------------------------------------------------------------------

=head1 NAME

Asm::Preproc::Token - One token retrieved from the input

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

our $VERSION = '1.02';

use Data::Dump 'dump';
use Asm::Preproc::Line;

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use Asm::Preproc::Token;
  my $token = Asm::Preproc::Token->new($type, $value, $line);
  $token->type; $token->value; 
  $token->line; # isa Asm::Preproc::Line
  my $token2 = $token->clone;
  $token->error($message);
  $token->warning($message);
  Asm::Preproc::Token->error_at($token, $message);
  Asm::Preproc::Token->warning_at($token, $message);

=head1 DESCRIPTION

This module defines the object to represent one token of input text as retrieved 
from the preprocessed input text.
It contains the token type (a string), the token value (a string) and a 
L<Asm::Preproc::Line|Asm::Preproc::Line> object with the line where the token
was found.

There are also utility methods for error messages.

=head1 METHODS

=head2 new

Creates a new object with the given type, value and line.

=head2 type

Get/set type.

=head2 value

Get/set file value.

=head2 line

Get/set line.

=head2 clone

Creates an identical copy as a new object.

=cut

#------------------------------------------------------------------------------
use Class::XSAccessor::Array {
	accessors => {
		type		=> 0,
		value		=> 1,
		_line		=> 2,		
	},
	predicates => {
		_has_line	=> 2,
	},
};

# create line on demand
sub line {
	my $self = shift;
	$self->_has_line or $self->_line( Asm::Preproc::Line->new );
	$self->_line(@_);
}

sub new { 
	#my($class, $type, $value, $line) = @_;
	my $class = shift;
	bless [@_], $class;
}

sub clone {
	my $self = shift;
	bless [$self->type, $self->value, $self->line->clone], ref($self);
}

#------------------------------------------------------------------------------

=head2 error

Dies with the given error message, indicating the place in the input source file
where the error occured as:

  FILE(LINE) : error ... at TOKEN

=cut

#------------------------------------------------------------------------------
sub error { 
	my($self, $message) = @_;
	$self->line->error($self->_format_error_msg($message));
}
#------------------------------------------------------------------------------

=head2 error_at

Same as error(), but is a class method and can receive an undef $token.

=cut

#------------------------------------------------------------------------------
sub error_at { 
	my($class, $token, $message) = @_;
	$token ||= $class->new();
	$token->line->error($token->_format_error_msg($message));
}
#------------------------------------------------------------------------------

=head2 warning

Warns with the given error message, indicating the place in the input source file
where the error occured as:

  FILE(LINE) : warning ... at TOKEN

=cut

#------------------------------------------------------------------------------
sub warning { 
	my($self, $message) = @_;
	$self->line->warning($self->_format_error_msg($message));
}
#------------------------------------------------------------------------------

=head2 warning_at

Same as warning(), but is a class method and can receive an undef $token.

=cut

#------------------------------------------------------------------------------
sub warning_at { 
	my($class, $token, $message) = @_;
	$token ||= $class->new();
	$token->line->warning($token->_format_error_msg($message));
}
#------------------------------------------------------------------------------
# error message for error() and warning()
sub _format_error_msg {
	my($self, $message) = @_;
	my $type = $self->type;
	
	defined($message) or $message = ""; 
	$message =~ s/\s+$//;
	$message .= " " if $message ne "";
	$message .= "at ".
					(! defined($type) ?
						"EOF" :
						$type =~ /\W/ ?
							dump($type) :
							$type
					);
	return $message;
}
#------------------------------------------------------------------------------

=head1 AUTHOR, BUGS, SUPPORT, LICENSE, COPYRIGHT

See L<Asm::Preproc|Asm::Preproc>.

=cut

#------------------------------------------------------------------------------

1;
