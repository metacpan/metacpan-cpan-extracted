# Emit.pm                                                          -*- Perl -*-
#
#   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License, as specified in the LICENSE file that was shipped
# with this distribution.

package B::JVM::Emit;


use 5.000562;

use strict;
use warnings;

=head1 NAME

B::JVM::Emit -  Package used by B::JVM to emit Java Bytecode

=head1 SYNOPSIS

  use B::JVM::Jasmin::Emit;

  my $emitter = new B::JVM::Emit(FILEHANDLE);

  # ...
  $emitter->DIRECTIVE_NAME([@ARGS]);
  #  ...
  $emitter->OPCODE_NAME([@ARGS]);
  #  ...
  $emitter->OPCODE_NAME([@ARGS]);

=head1 DESCRIPTION

This class is used Java bytcodes on a file handle.  Until someone actually
creates a module that truely emits Java bytecodes, the interesting stuff is
all happening in the subclass, L<B::JVM::Jasmin::Emit|B::JVM::Jasmin::Emit>.
The method names used here were built up from the L<jasmin|jasmin> syntax.
There was no reason for this other than the implementor was most familar
with that manner of thinking about Java bytecode.  However, the set should
cover every opcode available.

The user of this module I<must> send opcodes in the order desired and is
responsible for emitting a sensible JVM program.  All this module provides
is a consistent way to emit JVM opcodes from Perl, since there is no
universal assembler syntax.  Someone who wants to emit opcodes need only
subclass this module and implement all the methods. 

=head1 AUTHOR

Bradley M. Kuhn, bkuhn@ebb.org, http://www.ebb.org/bkuhn

=head1 COPYRIGHT

Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.

=head1 LICENSE

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the LICENSE file that was shipped
with this distribution.

=head1 SEE ALSO

perl(1), B::JVM::Jasmin(3), B::JVM::Jasmin::Emit(3)

=head1 DETAILED DOCUMENTATION

=head2 B::JVM::Emit Package Variables

=over

=item $VERSION

Version number of B::JVM::Emit.  For now, it should always match the version
of B::JVM::Jasmin

=back

=cut

use vars qw($VERSION);

$VERSION = "0.02";

###############################################################################

=head2 Modules used by B::JVM::Emit

=over

=item Carp

Used for error reporting

=back

=cut

use Carp;

###############################################################################

=head2 Methods in B::JVM::Emit

=over

=cut

#-----------------------------------------------------------------------------

=item B::JVM::Emit::new

usage: B::JVM::Emit::new(FILEHANDLE)

Creates a new object of the class.  It assumes that FILEHANDLE is a
lexically scoped file handle open for writing.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $fh    = shift;

  croak "usage: ${class}->new(IO::File)\n"
    unless (defined $fh && ref($fh) eq "IO::File");

  my $self = { fileHandle    => $fh,
               currentMethod => undef,
               className     => undef
             };

  bless $self, $class;
  return $self;
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::_clearMethod

usage: $emitter->_clearMethod()

Clears  the current method name.

=cut

sub _clearMethod {
  my($self, $methodName) = @_;

  $self->{currentMethod} = undef;
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::_setCurrentMethod

usage: B::JVM::Emit::_setCurrentMethod(METHOD_NAME)

Sets the current name of the method being emitted.

=cut

sub _setCurrentMethod {
  my($self, $methodName) = @_;

  croak "$methodName is not a valid method name" 
    unless IsValidMethodString($methodName);

  $self->{currentMethod} = $methodName;
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::inMethod

usage: $emitter->inMethod()

Returns true (in particular, the current method name) if we are currently
in method, and returns false otherwise.

=cut

sub inMethod {
  my($self) = @_;
  if (defined $self->{currentMethod}) {
    return $self->{currentMethod};
  } else {
    return 0;
  }
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::_setClassName

usage: B::JVM::Emit::_setClassName(CLASS_NAME)

Sets the  name of the class being emitted.

=cut

sub _setClassName {
  my($self, $className) = @_;

  # FIXME: should probably check RE against class name

  $self->{className} = $className;
}
###############################################################################
1;
__END__

=back

=cut

