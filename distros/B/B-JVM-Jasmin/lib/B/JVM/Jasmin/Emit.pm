# Emit.pm                                                          -*- Perl -*-
#
#   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License, as specified in the LICENSE file that was shipped
# with this distribution.

# "Last night, I had a dream.  I found myself in a desert called `Cyberland'.
#  It was hot; my canteen had sprung a leak and I was thirsty."
#                                          -- Maureen, "Over the Moon", _RENT_


# FIXME:  the error messags from this package need to be standarized
 
package B::JVM::Jasmin::Emit;

use 5.000562;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

use B::JVM::Emit;

=head1 NAME

B::JVM::Jasmin::Emit -  Package used by B::JVM::Jasmin to emit Jasmin syntaxed
                        file

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

This class is used emit JVM assembler code in Jasmin syntax.  Each method
one can use is either an opcode or a directive supported by Jasmin syntax.

=head1 AUTHOR

Bradley M. Kuhn, bkuhn@ebb.org, http://www.ebb.org/bkuhn

=head1 COPYRIGHT

Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.

=head1 LICENSE

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the LICENSE file that was shipped
with this distribution.

=head1 SEE ALSO

perl(1), B::JVM::Jasmin(3), B::JVM::Emit(3).

=head1 DETAILED DOCUMENTATION

=head2 B::JVM::Jasmin::Emit Package Variables

=over

=over

=item $VERSION

Version number of B::JVM::Jasmin::Emit.  For now, it should always match the
version of B::JVM::Jasmin

=item @EXPORT_OK

All the methods that one can grab from B::JVM::Jasmin::Emit

=item @EXPORT

We don't export anything by default.

=back

=cut

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(B::JVM::Emit Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = "0.02";

###############################################################################

=head2 Modules used by B::JVM::Jasmin::Emit

=over

=item Carp

Used for error reporting

=item B::JVM::Utils

Used to get needed utility functions, such as ExtractMethodData and
IsValidMethodString

=back

=cut

use Carp;

use B::JVM::Utils
               qw(ExtractMethodData IsValidMethodString IsValidTypeIdentifier);

###############################################################################

=head2 Methods in B::JVM::Jasmin::Emit

=over

=cut

#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::Emit::new

usage: B::JVM::Emit::new(FILEHANDLE, [SOURCE_FILE_NAME])

Creates a new object of the class.  It assumes that FILEHANDLE is a
lexically scoped file handle open for writing, and that SOURCE_FILE_NAME
that should be used for a source directive.  SOURCE_FILE_NAME is optional, but
may annoys someone firing up your code in the Java debugger.

=cut

sub new {
  my $proto          = shift;
  my $class          = ref($proto) || $proto;
  my $fh             = shift;
  my $sourceFileName = shift;

  my $self = $class->SUPER::new($fh);

  bless $self, $class;

  $self->source($sourceFileName) unless defined $sourceFileName;

  return $self;
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::_clearMethodData()

usage: $jasminEmitter->_clearMethodData()

Clear out the method data elements of the Jasmin emitter

=cut

sub _clearMethodData {
  my($self, $methodName) = @_;

  $self->{methodData}{$methodName}{header}         = [];
  $self->{methodData}{$methodName}{declarations}   = [];
  $self->{methodData}{$methodName}{body}           = [];
  $self->{methodData}{$methodName}{footer}         = [];
  $self->{methodData}{$methodName}{locals}{count}  = 0;
  $self->{methodData}{$methodName}{locals}{table}  = {};

  $self->{methodData}{$methodName}{labels}{count}  = 0;
  $self->{methodData}{$methodName}{labels}{table}  = {};
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::source

usage: B::JVM::Emit::Jasmin::source(SOURCE_FILE_NAME)

Emits the source file name directive.

=cut

sub source {
  my($self, $sourceFileName) = @_;

  croak "usage: B::JVM::Jasmin::Emit->source(SOURCE_FILE_NAME)"
    unless defined $sourceFileName;

  print {$self->{fileHandle}} ".source $sourceFileName\n";
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::comment

usage: C<B::JVM::Emit::Jasmin::comment($methodName, $commentString)>

Puts C<$commentString> in a comment in the file, in the code for method
C<$metohdName>.

=cut

sub comment {
  my($self, $methodName, $commentString) = @_;

  croak 'usage: B::JVM::Jasmin::Emit->comment($methodName, $commentString)'
    unless (defined $commentString && defined $methodName);

  croak "B::JVM::Jasmin::Emit->comment(): unknown method name, $methodName"
    unless (defined $self->{methodData}{$methodName});

  foreach my $line (split(/\n/, $commentString)) {
    push(@{$self->{methodData}{$methodName}{body}}, "; " . $line);
  }
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::super

usage: B::JVM::Emit::Jasmin::super(CLASS_NAME)

sends class directive, using  CLASS_NAME, to the output file

=cut

sub super {
  my($self, $className) = @_;

  croak "usage: B::JVM::Jasmin::Emit->super(CLASS_NAME)"
    unless defined $className;

  print {$self->{fileHandle}} ".super $className\n";
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::class

usage: B::JVM::Emit::Jasmin::class(ACCESS_SPEC, CLASS_NAME)

sends class directive, using CLASS_NAME to the ACCESS_SPEC, to the output
file

=cut

sub class {
  my($self, $accessSpec, $className) = @_;

  croak "usage: B::JVM::Jasmin::Emit->class(ACCESS_SPEC, CLASS_NAME)"
    unless (defined $accessSpec and defined $className);

  $self->_setClassName($className);

  print {$self->{fileHandle}} ".class $accessSpec $className\n";
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::interface

usage: B::JVM::Emit::Jasmin::interface(ACCESS_SPEC, INTERFACE_NAME)

sends interface directive, using INTERFACE_NAME to the ACCESS_SPEC, to the
output file

=cut

sub interface {
  my($self, $accessSpec, $interfaceName) = @_;

  croak "usage: B::JVM::Jasmin::Emit->interface(ACCESS_SPEC, INTERFACE_NAME)"
    unless (defined $accessSpec and defined $interfaceName);

  print {$self->{fileHandle}} ".interface $accessSpec $interfaceName\n";
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::implements

usage: B::JVM::Emit::Jasmin::implements(CLASS_NAME)

sends implements directive, using CLASS_NAME to the output file

=cut

sub implements {
  my($self, $className) = @_;

  croak "usage: B::JVM::Jasmin::Emit->implements(CLASS_NAME)"
    unless (defined $className);

  print {$self->{fileHandle}} ".implements $className\n";
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::labelCreate

usage: C<$emitter->labelCreate($methodName, $labelNameRequested)>

In method, $methodName, creates a new label, whose name will "resemble"
$labelNameRequested.  This label is not actually sent to the output, that
must be done later with C<$emitter->labelSend($methodName, $value)>.

Note that the value returned from this method is the actual label name
assigned and will only "resemble" (i.e., not match exactly) the
C<$labelNameRequested>.

=cut

sub labelCreate {
  my($self, $method, $labelRequested) = @_;

  croak('usage: B::JVM::Jasmin::Emit->labelCreate' .
        '($methodName, $labelNameRequested)')
    unless (defined $labelRequested and defined $method);

  croak "B::JVM::Jasmin::Emit->labelCreate(): unknown method, $method"
    unless (defined $method and defined $self->{methodData}{$method});

  my $labelValue = $labelRequested . "_" .
                   $self->{methodData}{$method}{labels}{count};

  $self->{methodData}{$method}{labels}{count}++;

  $self->{methodData}{$method}{labels}{table}{$labelValue} = 1;

  return $labelValue;
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::labelSend

usage: C<$emitter->labelSend($methodName, $labelName)>

Send a label, C<$labelName>, to the output of method, C<$methodName>.

This label must be valid label previously returned from
C<$emitter->labelCreate($methodName, $someValue)>.

=cut

sub labelSend {
  my($self, $method, $labelName) = @_;

  croak "B::JVM::Jasmin::Emit->labelSend(): unknown method name, $method"
    unless (defined $method and defined $self->{methodData}{$method});

  croak "B::JVM::Jasmin::Emit->labelSend(): unknown label name, $labelName"
    unless (defined $labelName and
            defined $self->{methodData}{$method}{labels}{table}{$labelName});

  push(@{$self->{methodData}{$method}{body}}, "${labelName}:");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::field

usage: B::JVM::Emit::Jasmin::field(ACCESS_SPEC, FIELD_NAME, TYPE, [VALUE])

sends field directive, using the arguments given, to the output file

=cut

sub field {
  my($self, $accessSpec, $fieldName, $type, $value) = @_;

  croak "usage: B::JVM::Jasmin::Emit->field(CLASS_NAME)"
    unless (defined $accessSpec and defined $fieldName and defined $type);

  my $fieldString = ".field $accessSpec $fieldName $type";

  if (defined $value) {
    $fieldString .= " = $value";
  }

  print {$self->{fileHandle}} "$fieldString\n";
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::methodStart

usage: $emitter->methodStart(METHOD_NAME, ACCESS_SPEC, [STACK_SIZE])

sends method directive and other directives needed to start up a new method.
Also sets the current method for the emitter.  STACK_SIZE is optional.
However, a stack size is always set to a default value (currently 256),
because if it is not set, a number of problems occur with the stack.

=cut

sub methodStart {
  my($self,  $methodName, $accessSpec, $stackSize) = @_;

  croak("usage: B::JVM::Jasmin::Emit->methodStart(METHOD_NAME, ACCESS_SPEC,"
        . " [STACK_SIZE])")
    unless (defined $accessSpec and defined $methodName and
            IsValidMethodString($methodName) and
            ( (! defined $stackSize) || $stackSize =~ /\d+/ ));

  $self->_clearMethodData($methodName);

  push(@{$self->{methodData}{$methodName}{header}},
       ".method $accessSpec $methodName");

  $stackSize = 256 unless (defined $stackSize);

  push(@{$self->{methodData}{$methodName}{header}},
       "\t.limit stack $stackSize");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::methodCreateLocal

usage: $emitter->methodCreateLocal(METHOD_NAME, VARIABLE_NAME_REQUEST,
                                   VARIABLE_TYPE, [LABEL1], [LABEL2])

Creates a local of type VARIABLE_TYPE, with a given name in method,
METHOD_NAME.  If LABEL1 is given, LABEL2 must be given, and vice versa.

If the labels are given, then the variable is only valid between those two
labels in the resulting assembler source.  

methodCreateLocal attempts to give a variable name that "resembles"
VARIABLE_NAME_REQUEST.  If the labels are given, it is guaranteed that the
variable name will "resemble" the VARIABLE_NAME_REQUEST.

If the labels are not given, it is very likely that an old local variable of
the same type will be returned.

The actual variable name given will be returned.  It is imperative that the
user of methodCreateLocal use this variable name, and not
VARIABLE_NAME_REQUEST, for obvious reasons.


=cut

sub methodCreateLocal {
  my($self, $methodName, $variableRequest, $type, $labelStart, $labelEnd) = @_;

  croak("usage: B::JVM::Jasmin::Emit->methodCreateLocal("
        . "METHOD_NAME, VARIABLE_NAME, VARIABLE_TYPE, [LABEL1], [LABEL2])")
    if (
       (! (defined $methodName and defined $variableRequest
           and defined $type) )
        and (defined $labelStart and (! defined $labelEnd))
        and (! IsValidTypeIdentifier($type)) );

  my $variableName;

  unless (defined $labelStart) {
    # If we don't have any labels, we can possibly use a free variable
    foreach my $local (keys
                       %{$self->{methodData}{$methodName}{locals}{table}}) {
      my $localHash = $self->{methodData}{$methodName}{locals}{table}{$local};
      if ($localHash->{free}  && $localHash->{type} eq $type) {
        # If this variable is free and the type matches the one we need, 
        # go ahead and use it and leave the loop
        $variableName = $local;
        last;
      }
    }
  }
  unless (defined $variableName) {
    # If we aren't using  a free variable, we have to create one

    $variableName = $variableRequest .
      $self->{methodData}{$methodName}{locals}{count};

    my $declaration =
      ".var $self->{methodData}{$methodName}{locals}{count} is "
        . "$variableName $type";

    if (defined $labelStart) {
      $declaration .= " from $labelStart to $labelEnd";
    }
    push(@{$self->{methodData}{$methodName}{declarations}}, $declaration);

    # Save variable information
    $self->{methodData}{$methodName}{locals}{table}{$variableName}{number} =
      $self->{methodData}{$methodName}{locals}{count};
    $self->{methodData}{$methodName}{locals}{table}{$variableName}{type} =
      $type;

    # Now, we have another local
    $self->{methodData}{$methodName}{locals}{count} ++;
  }

  # Either way, we need to mark this variable as not free now
  $self->{methodData}{$methodName}{locals}{table}{$variableName}{free} = 0;


  return $variableName;
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::methodFreeLocal

usage: $emitter->methodFreeLocal(METHOD_NAME VARIABLE_NAME)

Indicates that the local, VARIABLE_NAME, in method, METHOD_NAME, is no
longer in use.  It is not required that locals be freed in this manner,
however, many, many locals can be allocated unnecessarily if this is not done.

=cut

sub methodFreeLocal {
  my($self, $methodName, $variableName) = @_;

  croak("usage: B::JVM::Jasmin::Emit->methodFreeLocal("
        . "METHOD_NAME, VARIABLE_NAME)")
    unless (defined $methodName and defined $variableName and defined
            $self->{methodData}{$methodName}{locals}{table}{$variableName});

  $self->{methodData}{$methodName}{locals}{table}{$variableName}{free} = 1;
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::methodEnd

usage: C<$emitter->methodEnd($method, [$debug])>

Finishes up a method, C<$method>, that is currently being emitted.  If
C<$debug> is defined and is true, then ".line" directives will be put into
the output for debugging purposes.

=cut

sub methodEnd {
  my($self, $methodName, $debug) = @_;

  push(@{$self->{methodData}{$methodName}{footer}}, ".end method");

  push(@{$self->{methodData}{$methodName}{header}}, "\t.limit locals " .
                    "$self->{methodData}{$methodName}{locals}{count}");

  foreach my $line (@{$self->{methodData}{$methodName}{header}}) {
    print {$self->{fileHandle}} $line, "\n";
  }
  my $lineNumber = 1;
  foreach my $line (@{$self->{methodData}{$methodName}{declarations}},
                    @{$self->{methodData}{$methodName}{body}}) {
    print {$self->{fileHandle}} "\t.line $lineNumber\n"
      if (defined $debug and $debug);
    print {$self->{fileHandle}} "\t$line\n";
    $lineNumber++;
  }
  foreach my $line (@{$self->{methodData}{$methodName}{footer}}) {
    print {$self->{fileHandle}} $line, "\n";
  }
  undef $self->{methodData}{$methodName};
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::astore

usage: $emitter->astore([METHOD, VARIABLE])

Emits an "astore" instruction, using the VARIABLE name in METHOD given, if
one is given.  If VARIABLE is given, it is looked up in variables created
with B::JVM::Emit::Jasmin::methodCreateLocal() for the given method, METHOD.

=cut
  
sub astore {
  my($self, $method, $variable) = @_;

  croak("B::JVM::Emit::Jasmin::astore was given a variable, " .
        "$variable, unknown to method, $method")
    if ( (defined $variable or defined $method) and
         (! defined $self->{methodData}{$method}{locals}{table}{$variable}) );

  my $statement = "astore";

  if (defined $variable) {
    my $value = $self->{methodData}{$method}{locals}{table}{$variable}{number};

    $statement .=  ( ($value < 4) ? "_" : " ") . $value;
  }

  push(@{$self->{methodData}{$method}{body}}, $statement);
  
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::invokevirtual

usage: $emitter->invokevirtual(METHOD_IN, METHOD_INVOKED)

Emits an "invokevirtual" instruction to invoke METHOD_INVOKED in the code
for METHOD_IN

=cut

sub invokevirtual {
  my($self, $methodIn, $methodInvoked) = @_;

  croak "usage: B::JVM::Jasmin::Emit->invokeVirtual(METHOD_IN, METHOD_INVOKED)"
        unless (defined $self->{methodData}{$methodIn} 
                and IsValidMethodString($methodInvoked));

  push(@{$self->{methodData}{$methodIn}{body}},
       "invokevirtual $methodInvoked");
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::ifne

usage: C<$emitter->ifne($methodName, $labelName)>

Emits an "ifne" instruction with argument, C<$labelName> in the code for
method, C<$methodName>.

This label, C<$labelName> must be valid label previously returned from
C<$emitter->labelCreate($methodName, $someValue)>.

=cut

sub ifne {
  my($self, $methodIn, $labelName) = @_;

  croak "B::JVM::Jasmin::Emit->ifne(): unknown method, $methodIn"
    unless (defined $methodIn and defined $self->{methodData}{$methodIn});

  croak "B::JVM::Jasmin::Emit->ifne(): unknown label, $labelName"
    unless (defined $labelName and
            defined $self->{methodData}{$methodIn}{labels}{table}{$labelName});

  push(@{$self->{methodData}{$methodIn}{body}}, "ifne $labelName");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::ifeq

usage: C<$emitter->ifeq($methodName, $labelName)>

Emits an "ifeq" instruction with argument, C<$labelName> in the code for
method, C<$methodName>.

This label, C<$labelName> must be valid label previously returned from
C<$emitter->labelCreate($methodName, $someValue)>.

=cut

sub ifeq {
  my($self, $methodIn, $labelName) = @_;

  croak "B::JVM::Jasmin::Emit->ifeq(): unknown method, $methodIn"
    unless (defined $methodIn and defined $self->{methodData}{$methodIn});

  croak "B::JVM::Jasmin::Emit->ifeq(): unknown label, $labelName"
    unless (defined $labelName and
            defined $self->{methodData}{$methodIn}{labels}{table}{$labelName});

  push(@{$self->{methodData}{$methodIn}{body}}, "ifeq $labelName");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::aload

usage: $emitter->aload([METHOD, VARIABLE])

Emits an "aload" instruction, using the VARIABLE name in METHOD given, if
one is given.  If VARIABLE is given, it is looked up in variables created
with B::JVM::Emit::Jasmin::methodCreateLocal() for the given method, METHOD.

=cut
  
sub aload {
  my($self, $method, $variable) = @_;

  croak("B::JVM::Emit::Jasmin::aload was given a variable, " .
        "$variable, unknown to method, $method")
    if ( (defined $variable or defined $method) and
         (! defined $self->{methodData}{$method}{locals}{table}{$variable}) );

  my $statement = "aload";

  if (defined $variable) {
    my $value = $self->{methodData}{$method}{locals}{table}{$variable}{number};

    $statement .=  ( ($value < 4) ? "_" : " ") . $value;
  }

  push(@{$self->{methodData}{$method}{body}}, $statement);
  
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::invokestatic

usage: $emitter->invokevirtual(METHOD_IN, METHOD_INVOKED)

Emits an "invokestatic" instruction to invoke METHOD_INVOKED in the code
for METHOD_IN

=cut

sub invokestatic {
  my($self, $methodIn, $methodInvoked) = @_;

  croak "usage: B::JVM::Jasmin::Emit->invokestatic(METHOD_IN, METHOD_INVOKED)"
        unless (defined $self->{methodData}{$methodIn} and
                IsValidMethodString($methodInvoked));

  push(@{$self->{methodData}{$methodIn}{body}},
       "invokestatic $methodInvoked");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::iconst

usage: $emitter->iconst(METHOD, VALUE)

Emits an "iconst" instruction, using the value of VALUE for the constant, in
the method named METHOD.  

=cut
  
sub iconst {
  my($self, $method, $value) = @_;

  croak("usage: B::JVM::Emit::Jasmin::iconst(METHOD, VALUE)")
    unless (defined $method and defined $value and 
            defined $self->{methodData}{$method});

  push(@{$self->{methodData}{$method}{body}}, "iconst_$value");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::istore

usage: $emitter->istore([METHOD, VARIABLE])

Emits an "istore" instruction, using the VARIABLE name in METHOD given, if
one is given.  If VARIABLE is given, it is looked up in variables created
with B::JVM::Emit::Jasmin::methodCreateLocal() for the given method, METHOD.

=cut
  
sub istore {
  my($self, $method, $variable) = @_;

  croak("B::JVM::Emit::Jasmin::istore was given a variable, " .
        "$variable, unknown to method, $method")
    if ( (defined $variable or defined $method) and
         (! defined $self->{methodData}{$method}{locals}{table}{$variable}) );

  my $statement = "istore";

  if (defined $variable) {
    my $value = $self->{methodData}{$method}{locals}{table}{$variable}{number};

    $statement .=  ( ($value < 4) ? "_" : " ") . $value;
  }

  push(@{$self->{methodData}{$method}{body}}, $statement);
  
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::iload

usage: $emitter->iload([METHOD, VARIABLE])

Emits an "iload" instruction, using the VARIABLE name in METHOD given, if
one is given.  If VARIABLE is given, it is looked up in variables created
with B::JVM::Emit::Jasmin::methodCreateLocal() for the given method, METHOD.

=cut
  
sub iload {
  my($self, $method, $variable) = @_;

  croak("B::JVM::Emit::Jasmin::iload was given a variable, " .
        "$variable, unknown to method, $method")
    if ( (defined $variable or defined $method) and
         (! defined $self->{methodData}{$method}{locals}{table}{$variable}) );

  my $statement = "iload";

  if (defined $variable) {
    my $value = $self->{methodData}{$method}{locals}{table}{$variable}{number};

    $statement .=  ( ($value < 4) ? "_" : " ") . $value;
  }

  push(@{$self->{methodData}{$method}{body}}, $statement);
  
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::iand

usage: $emitter->iand([METHOD])

Emits an "iand" instruction, in METHOD given, if one is given. 

=cut
  
sub iand {
  my($self, $method) = @_;

  my $statement = "iand";

  push(@{$self->{methodData}{$method}{body}}, $statement);
  
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::pop

usage: $emitter->pop([METHOD])

Emits an "pop" instruction, in METHOD given, if one is given. 

=cut
  
sub pop {
  my($self, $method) = @_;

  my $statement = "pop";

  push(@{$self->{methodData}{$method}{body}}, $statement);
  
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::getstatic

usage: $emitter->getstatic(METHOD_IN, FIELD, TYPE)

Emits an "getstatic" instruction for the field, FIELD, of type,
TYPE in the code for METHOD_IN

=cut

sub getstatic {
  my($self, $methodIn, $field, $type) = @_;

  croak "usage: B::JVM::Jasmin::Emit->getstatic(METHOD_IN, FIELD, TYPE)"
        unless (defined $self->{methodData}{$methodIn} and
                IsValidTypeIdentifier($type) and defined $field);

  push(@{$self->{methodData}{$methodIn}{body}},
       "getstatic $field $type");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::ldc

usage: $emitter->ldc(METHOD_IN, VALUE)

Emits an "ldc" instruction with the value of VALUE, in the method METHOD_IN.

=cut

sub ldc {
  my($self, $methodIn, $value) = @_;

  croak "usage: B::JVM::Jasmin::Emit->ldc(VALUE)"
    unless (defined $value and defined $self->{methodData}{$methodIn});

  push(@{$self->{methodData}{$methodIn}{body}}, "ldc $value");
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::newObject

usage: $emitter->newObject(METHOD_IN, CLASS)

Emits an "new" instruction for the class, CLASS in the body for the method,
METHOD_IN.  CLASS must be a valid class name.

=cut

sub newObject {
  my($self, $methodIn, $classValue) = @_;

  croak "usage: B::JVM::Jasmin::Emit->newObject(CLASS)"
    unless (defined $classValue and defined $self->{methodData}{$methodIn});

  push(@{$self->{methodData}{$methodIn}{body}}, "new $classValue");
}

#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::invokespecial

usage: $emitter->invokespecial(METHOD_IN, METHOD_INVOKED)

Emits an "invokespecial" instruction to invoke METHOD_INVOKED in the code
for METHOD_IN

=cut

sub invokespecial {
  my($self, $methodIn, $methodInvoked) = @_;

  croak "usage: B::JVM::Jasmin::Emit->invokespecial(METHOD_IN, METHOD_INVOKED)"
        unless (defined $self->{methodData}{$methodIn} and
                IsValidMethodString($methodInvoked));

  push(@{$self->{methodData}{$methodIn}{body}},
       "invokespecial $methodInvoked");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::dup

usage: C<$emitter->dup($method)>

Emits an "dup" instruction in the code for the method, C<$method>

=cut

sub dup {
  my($self, $methodIn) = @_;

  croak "B::JVM::Jasmin::Emit->dup(METHOD): unknown method given, $methodIn"
    unless (defined $self->{methodData}{$methodIn});

  push(@{$self->{methodData}{$methodIn}{body}}, "dup");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::swap

usage: C<$emitter->swap($method)>

Emits an "swap" instruction in the code for the method, C<$method>

=cut

sub swap {
  my($self, $methodIn) = @_;

  croak "B::JVM::Jasmin::Emit->swap(METHOD): unknown method given, $methodIn"
    unless (defined $self->{methodData}{$methodIn});

  push(@{$self->{methodData}{$methodIn}{body}}, "swap");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::gotoLabel

usage: C<$emitter->gotoLabel($methodName, $labelName)>

Emits an "goto" instruction with argument, C<$labelName> in the code for
method, C<$methodName>.

This label, C<$labelName> must be valid label previously returned from
C<$emitter->labelCreate($methodName, $someValue)>.

=cut

sub gotoLabel {
  my($self, $methodIn, $labelName) = @_;

  croak "B::JVM::Jasmin::Emit->gotoLabel(): unknown method, $methodIn"
    unless (defined $methodIn and defined $self->{methodData}{$methodIn});

  croak "B::JVM::Jasmin::Emit->gotoLabel(): unknown label, $labelName"
    unless (defined $labelName and
            defined $self->{methodData}{$methodIn}{labels}{table}{$labelName});

  push(@{$self->{methodData}{$methodIn}{body}}, "goto $labelName");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::returnVoid

usage: $emitter->returnVoid(METHOD_IN)

Emits an "return" instruction in the code for method, METHOD_IN.

=cut

sub returnVoid {
  my($self, $methodIn) = @_;

  croak "usage: B::JVM::Jasmin::Emit->returnVoid(METHOD_IN)"
        unless (defined $self->{methodData}{$methodIn});

  push(@{$self->{methodData}{$methodIn}{body}}, "return");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::iinc

usage: C<$emitter->iinc($method, $variable, $amount)>

Emits an "iinc" instruction, using the C<$variable> name in the method,
C<$method>.  The variable, C<$variable> must have one previously returned
from C<methodCreateLocal($method, ...)> that has not been freed with
C<methodFreeLocal($method, ...)> yet.

C<$amount> is the integer amount to increment C<$variable> by.

=cut
  
sub iinc {
  my($self, $method, $variable, $amount) = @_;

  croak("B::JVM::Emit::Jasmin::iinc was given a variable, " .
        "$variable, unknown to method, $method")
    if ( (defined $variable or defined $method) and
         (! defined $self->{methodData}{$method}{locals}{table}{$variable}) );

  croak("B::JVM::Emit::Jasmin::iinc was not given an amount") 
    unless (defined $amount);

  my $statement;

  if ($amount == 0) {
    $statement = "nop";
  } else {
    $statement = "iinc " .
               $self->{methodData}{$method}{locals}{table}{$variable}{number} .
               " $amount";
  }

  push(@{$self->{methodData}{$method}{body}}, $statement);
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::bipush

usage: C<$emitter->bipush($method, $value)>

Emits an "bipush" instruction, into the method, C<$method> using the value
of C<$value>.  Note that an "iconst" or an "iconst_m1" instruction is
emitted if the C<$value> is the range where "iconst" will work.

=cut
  
sub bipush {
  my($self, $method, $value) = @_;

  croak("B::JVM::Emit::Jasmin::bipush was an unknown to method, $method")
    if ( (! defined $method) and (! defined $self->{methodData}{$method}) );

  my $statement;

  if ($value >= 0 and $value <= 5) {
    $statement = "iconst_$value";
  } elsif ($value == -1) {
    $statement = "iconst_m1";
  } else {
    $statement = "bipush $value";
  }

  push(@{$self->{methodData}{$method}{body}}, $statement);
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::aastore

usage: C<$emitter->aastore($method)>

Emits an "aastore" instruction, into the method, C<$method>.

=cut
  
sub aastore {
  my($self, $method) = @_;

  croak("B::JVM::Emit::Jasmin::aastore was an unknown to method, $method")
    if ( (! defined $method) and (! defined $self->{methodData}{$method}) );

  push(@{$self->{methodData}{$method}{body}}, "aastore");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::isub

usage: C<$emitter->isub($method)>

Emits an "isub" instruction, into the method, C<$method>.

=cut
  
sub isub {
  my($self, $method) = @_;

  croak("B::JVM::Emit::Jasmin::isub was an unknown to method, $method")
    if ( (! defined $method) and (! defined $self->{methodData}{$method}) );

  push(@{$self->{methodData}{$method}{body}}, "isub");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::nop

usage: C<$emitter->nop($method)>

Emits a "nop" instruction, into the method, C<$method>.

=cut
  
sub nop {
  my($self, $method) = @_;

  croak("B::JVM::Emit::Jasmin::nop: was an unknown to method, $method")
    if ( (! defined $method) and (! defined $self->{methodData}{$method}) );

  push(@{$self->{methodData}{$method}{body}}, "nop");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::aaload

usage: C<$emitter->aaload($method)>

Emits an "aaload" instruction, into the method, C<$method>.

=cut
  
sub aaload {
  my($self, $method) = @_;

  croak("B::JVM::Emit::Jasmin::aaload was an unknown to method, $method")
    if ( (! defined $method) and (! defined $self->{methodData}{$method}) );

  push(@{$self->{methodData}{$method}{body}}, "aaload");
}
#-----------------------------------------------------------------------------

=item B::JVM::Emit::Jasmin::anewarray

usage: C<$emitter->anewarray($method, $type)>

Emits an "anewarray" instruction, into the method, C<$method>.  The new array
will be of type C<$type>.  The method will fail if C<$type> is not a valid
JVM type identifier.


=cut
  
sub anewarray {
  my($self, $method, $type) = @_;

  croak("B::JVM::Emit::Jasmin::anewarray was an unknown to method, $method")
    if ( (! defined $method) and (! defined $self->{methodData}{$method}) );

  croak("B::JVM::Emit::Jasmin::anewarray was given an unknown type, $type")
    unless (defined $type and IsValidTypeIdentifier($type));

  push(@{$self->{methodData}{$method}{body}}, "anewarray $type");
}
###############################################################################

=back

=cut

1;
__END__

# "I gotta get out here!  It's like I'm being tied to the hood of a yellow
#  rental truck, being packed in with fertilzer and fuel oil, pushed over a
#  cliff by a suicidal Mickey Mouse."       -- Maureen, "Over the Moon", _RENT_
