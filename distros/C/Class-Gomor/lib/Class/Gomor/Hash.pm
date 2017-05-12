#
# $Id: Hash.pm 2000 2015-01-13 18:24:09Z gomor $
#
package Class::Gomor::Hash;
use strict; use warnings;

our $VERSION = '1.03';

use Class::Gomor;
use base qw(Class::Gomor);

use Data::Dumper;

sub new {
   my $self = shift;
   my $class = ref($self) || $self;
   my %h = @_;
   $class->cgCheckParams(\%h, $class->cgGetAttributes)
      unless $Class::Gomor::NoCheck;
   bless(\%h, $class);
}

# Just for compatibility with Class::Gomor::Array
# And in order to make it easy to switch for one to another
sub cgGetIndice { shift; shift }
sub cgBuildIndices {}

sub cgFullClone {
   my $self = shift;
   my ($n) = @_;
   return $self->SUPER::cgFullClone($n) if $n;
   my $class = ref($self) || $self;
   my %new;
   for my $k (keys %$self) {
      my $v = $self->{$k};
      (ref($v) && UNIVERSAL::isa($v, 'Class::Gomor'))
         ? $new{$k} = $v->cgFullClone
         : $new{$k} = $v;
   }
   bless(\%new, $class);
}

sub cgDumper { Dumper(shift()) }

sub _cgAccessorScalar {
   my ($self, $sca) = (shift, shift);
   @_ ? $self->{$sca} = shift
      : $self->{$sca};
}

sub _cgAccessorArray {
   my ($self, $ary) = (shift, shift);
   @_ ? $self->{$ary} = shift
      : @{$self->{$ary}};
}

1;

=head1 NAME

Class::Gomor::Hash - class and object builder, hash version

=head1 SYNPOSIS

   # Create a base class in BaseClass.pm
   package My::BaseClass;

   require Class::Gomor::Hash;
   our @ISA = qw(Class::Gomor::Hash);

   our @AS = qw(attribute1 attribute2);
   our @AA = qw(attribute3 attribute4);
   our @AO = qw(other);

   # You should initialize yourself array attributes
   sub new { shift->SUPER::new(attribute3 => [], attribute4 => [], @_) }

   # Create accessors
   My::BaseClass->cgBuildAccessorsScalar(\@AS);
   My::BaseClass->cgBuildAccessorsArray(\@AA);

   sub other {
      my $self = shift;
      @_ ? $self->{'other'} = [ split(/\n/, shift) ]
         : @{$self->{'other'}};
   }

   1;

   # Create a subclass in SubClass.pm
   package My::SubClass;

   require My::BaseClass;
   our @ISA = qw(My::BaseClass);

   our @AS = qw(subclassAttribute);

   My::SubClass->cgBuildAccessorsScalar(\@AS);

   sub new {
      shift->SUPER::new(
         attribute1 => 'val1',
         attribute2 => 'val2',
         attribute3 => [ 'val3', ],
         attribute4 => [ 'val4', ],
         other      => [ 'none', ],
         subclassAttribute => 'subVal',
      );
   }

   1;

   # A program using those classes

   my $new = My::SubClass->new;

   my $val1     = $new->attribute1;
   my @values3  = $new->attribute3;
   my @otherOld = $new->other;

   $new->other("str1\nstr2\nstr3");
   my @otherNew = $new->other;
   print "@otherNew\n";

   $new->attribute2('newValue');
   $new->attribute4([ 'newVal1', 'newVal2', ]);

=head1 DESCRIPTION

This class is a subclass from B<Class::Gomor>. It implements objects as hash references, and inherits methods from B<Class::Gomor>.

=head1 GLOBAL VARIABLE

See B<Class::Gomor>.

=head1 METHODS

=over 4

=item B<new> (hash)

Object constructor. This is where user passed attributes (hash argument) are checked against valid attributes (gathered by B<cgGetAttributes> method). Valid attributes are those that exists (doh!), and have not an undef value. The default is to check this, you can avoid it by setting B<$NoCheck> global variable (see perldoc B<Class::Gomor>).

=item B<cgBuildIndices>

This method does nothing. It only exists to make it more easy to switch between B<Class::Gomor::Array> and B<Class::Gomor::Hash>.

=item B<cgBuildAccessorsScalar> (array ref)

=item B<cgBuildAccessorsArray> (array ref)

See B<Class::Gomor>.

=item B<cgGetIndice> (scalar)

This method does nearly nothing. It only returns the passed-in scalar parameter (so the syntax is the same as in B<Class::Gomor::Array>). It only exists to make it more easy to switch between B<Class::Gomor::Array> and B<Class::Gomor::Hash>.

=item B<cgClone> [ (scalar) ]

You can clone one of your objects by calling this method. An optional parameter may be used to create multiple clones. Cloning will occure only on the first level attributes, that is, if you have attributes containing other objects, they will not be cloned.

=item B<cgFullClone> [ (scalar) ]

This method is the same as B<cgClone>, but will clone all attributes recursively, but only if they are subclassed from B<Class::Gomor>. So, objects created with other modules than B<Class::Gomor::Array> or B<Class::Gomor::Hash> will not be cloned.

Another thing to note, there is no catch for cycling references (when you link two objects with each others). You have been warned.

=item B<cgDumper>

Will return a string as with B<Data::Dumper> Dumper method. This is less useful for hashref objects, because they already include attributes names.

=back

=head1 SEE ALSO

L<Class::Gomor>

=head1 AUTHOR
      
Patrice E<lt>GomoRE<gt> Auffret
      
=head1 COPYRIGHT AND LICENSE
  
Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
