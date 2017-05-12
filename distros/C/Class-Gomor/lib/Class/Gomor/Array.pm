#
# $Id: Array.pm 2000 2015-01-13 18:24:09Z gomor $
#
package Class::Gomor::Array;
use strict; use warnings;

our $VERSION = '1.03';

use Class::Gomor;
use base qw(Class::Gomor);

use Data::Dumper;

no strict 'refs';

sub new {
   my $self = shift;
   my $class = ref($self) || $self;
   my %h = @_;
   $class->cgCheckParams(\%h, $class->cgGetAttributes)
      unless $Class::Gomor::NoCheck;
   my @obj;
   my $base = $class.'::__';
   $obj[${$base.$_}] = $h{$_} for keys %h;
   bless(\@obj, $class);
}

sub cgGetIndice {
   my $self = shift;
   ${(ref($self) || $self).'::__'.shift()};
}

sub cgBuildIndices {
   my $self = shift;
   my $i = 0;
   ${(ref($self) || $self).'::__'.$_} = $i++ for @{$self->cgGetAttributes};
}

sub cgFullClone {
   my $self = shift;
   my ($n) = @_;
   return $self->SUPER::cgFullClone($n) if $n;
   my $class = ref($self) || $self;
   my @new;
   for (@$self) {
      (ref($_) && UNIVERSAL::isa($_, 'Class::Gomor'))
         ? push @new, $_->cgFullClone
         : push @new, $_;
   }
   bless(\@new, $class);
}

sub cgDumper {
   my $self = shift;
   my $class = ref($self) || $self;
   my %h = map { $_ => $self->[$self->cgGetIndice($_)] }
      @{$class->cgGetAttributes};
   Dumper(\%h);
}

sub _cgAccessorScalar {
   my $self = shift;
   my $a = shift;
   @_ ? $self->[${ref($self).'::__'.$a}] = shift
      : $self->[${ref($self).'::__'.$a}];
}

sub _cgAccessorArray {
   my $self = shift;
   my $a = shift;
   @_ ? $self->[${ref($self).'::__'.$a}] = shift
      : @{$self->[${ref($self).'::__'.$a}]};
}

1;

=head1 NAME

Class::Gomor::Array - class and object builder, array version

=head1 SYNPOSIS

   # Create a base class in BaseClass.pm
   package My::BaseClass;

   require Class::Gomor::Array;
   our @ISA = qw(Class::Gomor::Array);

   our @AS = qw(attribute1 attribute2);
   our @AA = qw(attribute3 attribute4);
   our @AO = qw(other);

   # You should initialize yourself array attributes
   sub new { shift->SUPER::new(attribute3 => [], attribute4 => [], @_) }

   # Create indices and accessors
   My::BaseClass->cgBuildIndices;
   My::BaseClass->cgBuildAccessorsScalar(\@AS);
   My::BaseClass->cgBuildAccessorsArray(\@AA);

   sub other {
      my $self = shift;
      @_ ? $self->[$self->cgGetIndice('other')] = [ split(/\n/, shift) ]
         : @{$self->[$self->cgGetIndice('other')]};
   }

   1;

   # Create a subclass in SubClass.pm
   package My::SubClass;

   require My::BaseClass;
   our @ISA = qw(My::BaseClass);

   our @AS = qw(subclassAttribute);

   My::SubClass->cgBuildIndices;
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

This class is a subclass from B<Class::Gomor>. It implements objects as array references, and inherits methods from B<Class::Gomor>.

=head1 GLOBAL VARIABLES

See B<Class::Gomor>.

=head1 METHODS

=over 4

=item B<new> (hash)

Object constructor. This is where user passed attributes (hash argument) are checked against valid attributes (gathered by B<cgGetAttributes> method). Valid attributes are those that exists (doh!), and have not an undef value. The default is to check this, you can avoid it by setting B<$NoCheck> global variable (see perldoc B<Class::Gomor>).

=item B<cgBuildIndices>

You MUST call this method one time at the beginning of your classes, and all subclasses (even if you do not add new attributes). It will build the matching between object attributes and their indices inside the array object. Global variables will be created in your class, with the following format: B<$__attributeName>.

=item B<cgBuildAccessorsScalar> (array ref)

=item B<cgBuildAccessorsArray> (array ref)

See B<Class::Gomor>.

=item B<cgGetIndice> (scalar)

Returns the array indice of specified attribute passed as a parameter. You can use it in your programs to avoid calling directly the global variable giving indice information concerning requesting object, thus avoiding using `no strict 'vars';'. This method is usually used when you build your own accessors (those using attributes defined in B<@AO>).

=item B<cgClone> [ (scalar) ]

You can clone one of your objects by calling this method. An optional parameter may be used to create multiple clones. Cloning will occure only on the first level attributes, that is, if you have attributes containing other objects, they will not be cloned.

=item B<cgFullClone> [ (scalar) ]

This method is the same as B<cgClone>, but will clone all attributes recursively, but only if they are subclassed from B<Class::Gomor>. So, objects created with other modules than B<Class::Gomor::Array> or B<Class::Gomor::Hash> will not be cloned.

Another thing to note, there is no catch for cycling references (when you link two objects with each others). You have been warned.

=item B<cgDumper>

Will return a string as with B<Data::Dumper> Dumper method. This is useful for debugging purposes, because an arrayref object does not include attributes names.

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
