# $Id: Line.pm,v 1.10 2013/07/26 01:57:26 Paulo Exp $

package Asm::Preproc::Line;

#------------------------------------------------------------------------------

=head1 NAME

Asm::Preproc::Line - One line of text retrieved from the input

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

our $VERSION = '1.03';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use Asm::Preproc::Line;
  my $line = Asm::Preproc::Line->new($text, $file, $line_nr);
  $line->text; $line->rtext; $line->file; $line->line_nr;
  my $line2 = $line->clone;
  if ($line == $line2) {...}
  if ($line != $line2) {...}
  $line->error($message);
  $line->warning($message);

=head1 DESCRIPTION

This module defines the object to represent one line of input text
to preprocess. It contains the actual text from the line, and the file name 
and line number where the text was retrieved. It contains also utility methods
for error messages.

=head1 METHODS

=head2 new

Creates a new object with the given text, file name and line number.

=head2 text

Get/set line text.

=head2 rtext

Return reference to the text value.

=head2 file

Get/set file name.

=head2 line_nr

Get/set line number.

=head2 clone

Creates an identical copy as a new object.

=cut

#------------------------------------------------------------------------------
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(
		'text',
		'file',
		'line_nr',
	);

sub new { 
	my($class, $text, $file, $line_nr) = @_;
	bless {text => $text, file => $file, line_nr => $line_nr}, $class;
}

sub clone {
	my $self = shift;
	bless {%$self}, ref($self);
}

#------------------------------------------------------------------------------

=head2 is_equal

  if ($self == $other) { ... }

Compares two line objects. Overloads the '==' operator.

=cut

#------------------------------------------------------------------------------
sub is_equal { my($self, $other) = @_;
	no warnings 'uninitialized';
	return $self->text    eq $other->text    &&
		   $self->line_nr == $other->line_nr &&
		   $self->file    eq $other->file;
}

use overload '==' => \&is_equal, fallback => 1;
#------------------------------------------------------------------------------

=head2 is_different

  if ($self != $other) { ... }

Compares two line objects. Overloads the '!=' operator.

=cut

#------------------------------------------------------------------------------
sub is_different { my($self, $other) = @_;
	return ! $self->is_equal($other);
}

use overload '!=' => \&is_different, fallback => 1;
#------------------------------------------------------------------------------

=head2 error

Dies with the given error message, indicating the place in the input source file
where the error occured as:

  FILE(LINE) : error: MESSAGE

=cut

#------------------------------------------------------------------------------
sub error { 
	my($self, $message) = @_;
	die $self->_error_msg("error", $message);
}
#------------------------------------------------------------------------------

=head2 warning

Warns with the given error message, indicating the place in the input source file
where the error occured as:

  FILE(LINE) : warning: MESSAGE

=cut

#------------------------------------------------------------------------------
sub warning { my($self, $message) = @_;
	warn $self->_error_msg("warning", $message);
}
#------------------------------------------------------------------------------
# error message for error() and warning()
sub _error_msg { 
	my($self, $type, $message) = @_;
	
	no warnings 'uninitialized';
	
	my $file = $self->file;
	my $line_nr = $self->line_nr ? '('.$self->line_nr.')' : '';
	my $pos = "$file$line_nr"; $pos .= " : " if $pos;
	
	$message =~ s/\s+$//;		# in case message comes from die, has a "\n"
	
	return "$pos$type: $message\n";
}
#------------------------------------------------------------------------------

=head1 AUTHOR, BUGS, SUPPORT, LICENSE, COPYRIGHT

See L<Asm::Preproc|Asm::Preproc>.

=cut

#------------------------------------------------------------------------------

1;
