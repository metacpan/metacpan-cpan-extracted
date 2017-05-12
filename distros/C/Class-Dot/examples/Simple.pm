# $Id: Simple.pm 37 2007-11-03 20:08:48Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/examples/Simple.pm $
# $Revision: 37 $
# $Date: 2007-11-03 21:08:48 +0100 (Sat, 03 Nov 2007) $
package Class::Dot::Example::Simple;

use Class::Dot 2.0 qw(-new :std);

use XML::Simple;


property name => isa_String;

property email => isa_String;
property age   => isa_Int;

sub BUILD {
   my ($self, $options_ref) = @_;

   # name is required.
   croak 'Name is required' if not $self->name;

   return;
}

# Use XML::Simple to serialize this object instance as XML.
sub as_XML {
   my ($self) = @_;

   return XMLout({
      name  => $self->name,
      email => $self->email,
      age   => $self->age,
   });
}


1;


