# CompileState.pm                                                  -*- Perl -*-
#
#   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License, as specified in the LICENSE file that was shipped
# with this distribution.


package B::JVM::Jasmin::CompileState;

use 5.000562;

use strict;
use warnings;

=head1 NAME

B::JVM::Jasmin::CompileState - Internal package used by B::JVM::Jasmin to keep state of compilation

=head1 SYNOPSIS

  use B::JVM::Jasmin::CompileState;

  my $state = new B::JVM::Jasmin::CompileState([HASHREF]);


=head1 DESCRIPTION

This class is used to store the internal state of the compiler as it runs.
Certain global information must be accounted for, and instead of making a
bunch of global variables, I thought it would be better to keep track of
this via a sub-package.

=head1 AUTHOR

Bradley M. Kuhn, bkuhn@ebb.org, http://www.ebb.org/bkuhn

=head1 COPYRIGHT

Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.

=head1 LICENSE

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the LICENSE file that was shipped
with this distribution.

=head1 SEE ALSO

perl(1), jasmin(1), B::JVM::Jasmin(3).

=head1 DETAILED DOCUMENTATION

=head2 B::JVM::Jasmin::CompileState Package Variables

=over

=item $VERSION

Version number of B::JVM::Jasmin::CompileState.  It should always match the
version of B::JVM::Jasmin

=item @ISA

Canonical @ISA array, derives from nothing

=back

=cut

use vars qw(@ISA $VERSION);

$VERSION = "0.02";

@ISA = qw();

###############################################################################

=head2 Modules used by B::JVM::Jasmin::CompileState

=over

=item Carp

Used for error reporting

=item File::Spec::Functions

Used to do some operations on files

=item IO::File

used for creating lexically scoped file handles

=item B::JVM::Jasmin::Emit

Needed for creating emitter objects for output

=back

=cut

use Carp;
use File::Spec::Functions;
use IO::File;
use B::JVM::Jasmin::Emit;

###############################################################################

=head2 Methods in B::JVM::Jasmin::CompileState

=over

=cut

#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::new

usage: B::JVM::Jasmin::CompileState::new(HASHREF)

Creates a new object of the class.  First, it checks for the validity of the
keys of the given initialization package (valid keys are kept in
@validUserParameters), and if everything checks out, it sets up a few defaults
if none were given and returns the blessed object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = shift;

  croak("CompileState not initialized correctly")
    unless (ref($self) eq "HASH");

=pod

Accepted User Parameters:

=over

=item mainClassName

The name to be used for the Java class that will correspond to the "main::"
package.  Defaults to "Main" if none is given.

=item currentPackage

This is the current package being compiled.  Should be updated by the user
using the setCurrentPackage method.  There is really no need to initialize
it until compilation starts.  Consequently, the value defaults to undef.

=item outputDirectory

A directory to use for creation of output files.  Defaults to the current
working directory.


=item keepIntermediateFiles

If true, intermediate files that are generated during the compilation
process are kept for user inspection.

=back

=cut

  my(@validUserParameters) = qw(mainClassName currentPackage outputDirectory
                                keepIntermediateFiles);
  my(%validUserParameters);
  @validUserParameters{@validUserParameters} = 1 .. @validUserParameters;

  # Set up defaults we require

  $self->{mainClassName} = "Main"  unless defined $self->{mainClassName};
  $self->{outputDirectory} = curdir() unless defined $self->{outputDirectory};

  $self->{outputDirectory} = canonpath($self->{outputDirectory}, 1);

  # First, check to make sure parameters given were correct

  foreach my $parameter (keys %{$self}) {
    croak("invalid parameter: $parameter")
      unless defined $validUserParameters{$parameter};
  }
  bless $self, $class;
  $self->createNewFile("main", $self->{mainClassName});

  return $self;
}

#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::createNewFile

usage: $obj->createNewFile($packageName, [$className])

Creates a new file entry in the compiler state object and opens a new file
handle for use when writing out jasmin files.  If the file has already been
created, nothing is done.  This is typically called whenever a new package
is discovered, so that a seperate class file can be generated for that
package (class) in True Java Style (TM) :)

=cut

sub createNewFile {
  my($self, $packageName, $className) = @_;

  # Make sure we haven't already set this package up
  return if defined $self->{Package}->{$packageName};

  unless (defined $className) {
    $className = $packageName;
    $className =~ s/::/_/g;
  }
  my $fileName = catfile($self->{outputDirectory}, "${className}.jasmin");

  my $fh = new IO::File;
  open($fh, ">$fileName") || croak "unable to open $fileName: $!";

  $self->{Package}->{$packageName}->{FH} = $fh;
  $self->{Package}->{$packageName}->{fileName} = $fileName;
  $self->{Package}->{$packageName}->{emitter}  =
    new B::JVM::Jasmin::Emit($fh, $fileName);

  $self->{Package}->{$packageName}->{emitter}->source("${className}.jasmin");
  $self->{Package}->{$packageName}->{emitter}->class("public", $className);
  $self->{Package}->{$packageName}->{emitter}->super("java/lang/Object");

#  This isn't right!  I think perljvm program will need to clear these out
#  push(@{$self->{CleanupFiles}}, $fileName)
#    unless $self->{keepIntermediateFiles};

  return $self;
}
#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::emit

usage: $obj->emit([PACAKGE_NAME])

returns the emitter object associated with the given package, PACAKGE_NAME.
If PACKAGE_NAME is missing, then the emitter object of the currentPackage
is returned

=cut

sub emit {
  my($self, $packageName) = @_;

  unless (defined $packageName) {
    $packageName = $self->{currentPackage};
    croak "cannot emit; there appears to be no currentPackage set"
      unless (defined $packageName);
  }
  return $self->{Package}->{$packageName}->{emitter};
}

#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::setCurrentMethod

usage: $obj->setCurrentMethod($methodName)

Set the current method to be $methodName

=cut

sub setCurrentMethod {
  my($self, $methodName) = @_;
  
  $self->{currentMethod} = $methodName;
}

#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::setCurrentPackage

usage: $obj->setCurrentPackage($packageName)

Set the current package to be $packageName

=cut

sub setCurrentPackage {
  my($self, $packageName) = @_;
  
  $self->{currentPackage} = $packageName;
}
#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::clearCurrentMethod

usage: $obj->clearCurrentMethod()

Clear the current method name stored

=cut

sub clearCurrentMethod {
  my($self) = @_;
  
  $self->{currentMethod} = undef;
}
#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::getCurrentMethod

usage: $obj->getCurrentMethod()

Return the current method

=cut

sub getCurrentMethod {
  my($self) = @_;
  
  return $self->{currentMethod};
}


#-----------------------------------------------------------------------------

=item B::JVM::Jasmin::CompileState::DESTORY

usage: $obj->DESTROY()

Default destructor for the object

=cut

sub DESTROY {
  my $self = shift;

  unlink(@{$self->{CleanupFiles}}) if (defined $self->{CleanupFiles});
}
###############################################################################
1;
__END__

=back

=cut
