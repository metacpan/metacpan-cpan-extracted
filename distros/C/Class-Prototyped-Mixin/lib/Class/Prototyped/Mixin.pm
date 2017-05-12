package Class::Prototyped::Mixin;
use strict;
use warnings;

use Carp qw(cluck);
use Class::Prototyped;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = 3.00_00 ;
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw(mixin);
    %EXPORT_TAGS = ();
}

=head1 NAME

Class::Prototyped::Mixin - Mixin Support for Class::Prototyped

=head1 SYNOPSIS

=head2 Usage one: whip up a class and toss it in a scalar

 package HelloWorld;

 sub hello { 
  my ($self, $age) = @_;
  return "Hello World! I am $age years old" 
 }


 package HelloWorld::Uppercase;
 use base qw(Class::Prototyped);

 __PACKAGE__->reflect->addSlot(
  [qw(hello superable)] => sub {
    my $self = shift;
    my $ret = $self->reflect->super('hello', @_);
    uc $ret
  }
 );


 package HelloWorld::Bold;
 use base qw(Class::Prototyped);

 __PACKAGE__->reflect->addSlot(
  [qw(hello superable)] => sub {
    my $self = shift;
    my $ret = $self->reflect->super('hello', @_);
    "<b>$ret</b>";
  }
 );

  
 package HelloWorld::Italic;
 use base qw(Class::Prototyped);

 __PACKAGE__->reflect->addSlot(
  [qw(hello superable)] => sub {
    my $self = shift;
    my $ret = $self->reflect->super('hello', @_);
    "<i>$ret</i>";
  }
 );

 # script.pl - now the whipping begins
 use Class::Prototyped::Mixin qw(mixin);
 my $runtime = mixin(
     'HelloWorld' => 'HelloWorld::Uppercase', 'HelloWorld::Italic'
 );

 print $runtime->hello(74);
 <i>HELLO WORLD! I AM 74 YEARS OLD</i>

=head2 Usage two: create hierarchy and install in a Class::Prototyped package

 package CompileTime;
 use Class::Prototyped::Mixin qw(mixin);

 my $uclass = mixin(
  'HelloWorld' => 'HelloWorld::Uppercase', 'HelloWorld::Bold'
 );

 __PACKAGE__->reflect->addSlot(
  '*' => $uclass
 );


 # script.pl
 use CompileTime;

 print CompileTime->hello(88);
 <b>HELLO WORLD! I AM 88 YEARS OLD</b>

=head1 DESCRIPTION

This module aids prototyped-based object programming in Perl by
making it easy to layer functionality on base functionality
via a collection of mixin classes. The SYNOPSIS is admittedly easier done
via a C<fold> or some other pure functional approach. However, the case for 
intelligent, "performant" mixins is argued strongly here:
L<http://www.mail-archive.com/sw-design@metaperl.com/msg00060.html>

To date, the Mixin contributions to CPAN use class-based OOP,  
with L<Class::MixinFactory> being perhaps the
most complete and best documented.
This module is one of a series
designed to show the flexibility, simplicity 
and power of prototyped-based object programming. 

The reason I wish to address object-oriented design concerns in 
prototype-based object-oriented programming is that it is simple, flexible
and seems to involve less confusion than I see evolving with Perl
class-based oop. For awhile there was interest in roles. Now there is
interest in traits. And there has always been a long-standing interest
in mixins, decoration, and delegation.

I cringe at the thought of trying to get all of these technologies to
meld in a large project. I cringe equally at those who talk and do not
do: The last thing that is necessary is for me to SAY that
prototyped-based oop can address real-world concerns yet not
DEMONSTRATE.


=head1 AUTHOR

	Terrence Brannon
	CPAN ID: TBONE
	metaperl.com
	metaperl@gmail.com
	http://www.metaperl.com

=head1 SOURCES

Distributed on CPAN.

CVS access is via:

  cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/sw-design login

  cvs -z3 -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/sw-design co -P cpmixin




=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

=over 4

=item * L<Class::MixinFactory>

=back

=head1 METHODS

=head2 mixin

 Usage     : Class::Prototyped::Mixin::mixin($base, $derived, $derived_two, ..)
 Purpose   : Dynamically build an object with the specified inheritance
 Returns   : a Class::Prototyped object
 Argument  : a list of classes, starting from the root class and moving
             down the hierarchy
 Throws    : Returns undef if at least 2 classes are not passed in for mixing
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

=cut

#################### subroutine header end ####################


sub mixin {
  unless (@_ >= 2) {
    cluck 'at least 2 classes required for mixing';
    return;
  }
	
  my $base = shift;
  my @derived;
  {
    push @derived , (shift)->clone;
    $derived[$#derived]->reflect->addSlot('*' => $base);

    if (@_) {
      $base = $derived[$#derived];
      redo;
    }

  }

  $derived[$#derived];

}






1;


