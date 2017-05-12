#
# $Id: Gomor.pm 2000 2015-01-13 18:24:09Z gomor $
#
package Class::Gomor;
use strict; use warnings;

our $VERSION = '1.03';

use Exporter;
use base qw(Exporter);

use Carp;

no strict 'refs';

our $Debug   = 0;
our $NoCheck = 0;
our @EXPORT_OK = qw($Debug $NoCheck);

sub cgCheckParams {
   my $self = shift;
   my ($userParams, $accessors) = @_;
   for my $u (keys %$userParams) {
      my $valid;
      my $defined;
      for (@$accessors) {
         ($u eq $_) ? $valid++ : next;
         defined($userParams->{$u}) && do { $defined++; last };
      }
      if (! $valid) {
         carp("$self: parameter is invalid: `$u'");
         next;
      }
      if (! $defined) {
         carp("$self: parameter is undef: `$u'");
         next;
      }
   }
}

sub cgGetIsaTree {
   my $self = shift;
   my ($classes) = @_;
   for (@{$self.'::ISA'}) {
      push @$classes, $_;
      $_->cgGetIsaTree($classes) if $_->can('cgGetIsaTree');
   }
}
   
sub cgGetAttributes {
   my $self = shift;
   my $classes = [ $self ];
   $self->cgGetIsaTree($classes);
   my @attributes = ();
   {
      # On perl 5.10.0, we have a warning message:
      # "::AS" used only once: possible typo ...
      no warnings;
      for (@$classes) {
         push @attributes, @{$_.'::AS'} if @{$_.'::AS'};
         push @attributes, @{$_.'::AA'} if @{$_.'::AA'};
         push @attributes, @{$_.'::AO'} if @{$_.'::AO'};
      }
   }
   \@attributes;
}

sub cgClone {
   my $self = shift;
   my $class = ref($self) || $self;
   return bless([ @$self ], $class)
      if UNIVERSAL::isa($self, 'Class::Gomor::Array');
   return bless({ %$self }, $class)
      if UNIVERSAL::isa($self, 'Class::Gomor::Hash');
   $self;
}

sub cgFullClone {
   my $self = shift;
   my ($n) = @_;
   return [ map { $self->cgFullClone } 1..$n ];
}

sub cgBuildAccessorsScalar {
   my $self = shift;
   my ($accessors) = @_;
   for my $a (@$accessors) {
      *{$self.'::'.$a} = sub { shift->_cgAccessorScalar($a, @_) }
   }
}

sub cgBuildAccessorsArray {
   my $self = shift;
   my ($accessors) = @_;
   for my $a (@{$accessors}) {
      *{$self.'::'.$a} = sub { shift->_cgAccessorArray($a, @_) }
   }
}

sub cgDebugPrint {
   my $self = shift;
   my ($level, $msg) = @_;
   return if $Debug < $level;
   my $class = ref($self) || $self;
   $class =~ s/^.*:://;
   $msg =~ s/^/DEBUG: $class: /gm;
   print STDERR $msg."\n";
}

1;

=head1 NAME

Class::Gomor - another class and object builder

=head1 DESCRIPTION

This module is yet another class builder. This one adds parameter checking in B<new> constructor, that is to check for attributes existence, and definedness.

In order to validate parameters, the module needs to find attributes, and that is the reason for declaring attributes in global variables named B<@AS>, B<@AA>, B<@AO>. They respectively state for Attributes Scalar, Attributes Array and Attributes Other. The last one is used to avoid autocreation of accessors, that is to let you declare your own ones.

Attribute validation is performed by looking at classes hierarchy, by following @ISA tree inheritance.

The loss in speed by validating all attributes is quite negligeable on a decent machine (Pentium IV, 2.4 GHz) with Perl 5.8.x. But if you want to avoid checking, you can do it, see below.

This class is the base class for B<Class::Gomor::Array> and B<Class::Gomor::Hash>, so they will inherite the following methods.

=head1 GLOBAL VARIABLES

=over 4

=item B<$NoCheck>

Import it in your namespace like this:

use Class::Gomor qw($NoCheck);

If you want to disable B<cgCheckParams> to improve speed once your program is frozen, you can use this variable. Set it to 1 to disable parameter checking.

=item B<$Debug>

Import it in your namespace like this:

use Class::Gomor qw($Debug);

This variable is used by the B<cgDebugPrint> method.

=back

=head1 METHODS

=over 4

=item B<cgCheckParams> (hash ref, array ref)

The attribute checking method takes two arguments, the first is user passed attributes (as a hash reference), the second is the list of valid attributes, gathered via B<cgGetAttributes> method (as an array ref). A message is displayed if passed parameters are not valid.

=item B<cgGetIsaTree> (array ref)

A recursive method. You pass a class in an array reference as an argument, and then the @ISA array is browsed, recursively. The array reference passed as an argument is increased with new classes, pushed into it. It returns nothing, result is stored in the array ref.

=item B<cgGetAttributes>

This method returns available attributes for caller's object class. It uses B<cgGetIsaTree> to search recursively in class hierarchy. It then returns an array reference with all possible attributes.

=item B<cgBuildAccessorsScalar> (array ref)

Accessor creation method. Takes an array reference containing all scalar attributes to create. Scalar accessors are stored in a global variable names B<@AS>. So you call this method at the beginning of your class like that:

__PACKAGE__->cgBuildAccessorsScalar(\@AS);

=item B<cgBuildAccessorsArray> (array ref)

Accessor creation method. Takes an array reference containing all array attributes to create. Array accessors are stored in a global variable names B<@AA>. So you call this method at the beginning of your class like that:

__PACKAGE__->cgBuildAccessorsArray(\@AA);

=item B<cgClone> [ (scalar) ]

You can clone one of your objects by calling this method. An optional parameter may be used to create multiple clones. Cloning will occure only on the first level attributes, that is, if you have attributes containing other objects, they will not be cloned.

=item B<cgFullClone> [ (scalar) ]

This method is the same as B<cgClone>, but will clone all attributes recursively, but only if they are subclassed from B<Class::Gomor>. So, objects created with other modules than B<Class::Gomor::Array> or B<Class::Gomor::Hash> will not be cloned.

Another thing to note, there is no catch for cycling references (when you link two objects with each others). You have been warned.

=item B<cgDebugPrint> (scalar, scalar)

First argument is a debug level. It is compared with global B<$Debug>, and if it is less than it, the second argument (a message string) is displayed. This method exists because I use it, maybe you will not like it.

=back

=head1 SEE ALSO

L<Class::Gomor::Array>, L<Class::Gomor::Hash>

=head1 AUTHOR
      
Patrice E<lt>GomoRE<gt> Auffret
      
=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
