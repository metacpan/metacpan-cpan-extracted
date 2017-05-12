package Context::Set;

our $VERSION = '0.02';

use Moose;


has 'name' => ( is => 'ro', isa => 'Str', default => 'UNIVERSE' );
has 'properties' => ( is => 'rw' , isa => 'HashRef' , required => 1 , default => sub{ {}; } );


sub fullname{
  my ($self) = @_;
  return $self->name();
}

sub is_inside{
  my ($self , $name) = @_;
  return $self->name() eq $name;
}

sub restrict{
  my ($self, $restriction_name) = @_;
  unless( $restriction_name ){
    confess("Missing restriction_name");
  }
  ## Avoid circular dependencies.
  require Context::Set::Restriction;
  return Context::Set::Restriction->new({ name => $restriction_name,
                                     restricted => $self });
}


sub unite{
  my ($self, $other) = @_;
  unless( $other && $other->isa('Context::Set') ){
    confess("Missing other Context in unite");
  }
  require Context::Set::Union;
  return Context::Set::Union->new({ contexts => [ $self, $other ] });
}


sub set_property{
  my ($self, $prop_name, $value) = @_;
  unless( defined $prop_name ){
    confess("prop_name has to be a defined value");
  }
  $self->properties()->{$prop_name} = $value;
}


sub get_property{
  my ($self, $prop_name) = @_;
  unless( $self->has_property($prop_name) ){
    confess("No property named $prop_name in ".$self->name());
  }
  return $self->properties()->{$prop_name};
}


sub has_property{
  my ($self, $prop_name) = @_;
  return exists $self->properties()->{$prop_name};
}

sub delete_property{
  my ($self, $prop_name) = @_;
  unless( $self->has_property($prop_name) ){
    confess("No property named $prop_name in ".$self->name()." cannot delete it");
  }
  return delete $self->properties()->{$prop_name};
}

sub lookup{
  my ($self, $prop_name) = @_;
  unless( $prop_name ){ confess("Missing prop_name"); }
  return $self if $self->properties()->{$prop_name};
  return $self->_lookup_parents($prop_name);
}

sub _lookup_parents{
  my ($self, $pname) = @_;
  return undef;
}

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 NAME

Context::Set - A Contextual preference/configuration holder.

=head1 VERSION

Version 0.01

=head1 INTRODUCTION

Context is a preference manager that aims at solving the problem of storing configuration properties accross
an ever growing collection of contexts that often characterises enterprise systems.

For instance, you might want to have a 'page colour' setting that is global to your system,
but allow users to choose their own if they want.

Additionally, you might want to allow your users to specifically define a page color when
they view a specific 'list of stuff' in your system. Or allow the system to specify a page color
for all lists, or a specific one to certain lists, but still allowing users to override that.

Multiplication of preferences and management of their priorities can cause a lot of confusion
and headaches. This module is an attempt to help you to keep those things tidy and in control.

=head1 SYNOPSIS

To use Context, the best way is probably to use a Context::Set::Manager that will
keep your contexts tidy for you.

  my $cm = Context::Set::Manager->new();
  $cm->universe()->set_property('page.colour' , 'blue');

  my $users = $cm->restrict('users');
  $users->set_property('page.colour', 'green');

  my $user1 = $cm->restrict('users' , 1);
  $user1->set_property('page.colour' , 'red');


  $user1->get_property('page.colour'); # red

  my $user2 = $cm->restrict('users' , 2);
  $user2->get_property('page.colour') ; # green

  my $lists = $cm->restrict('lists');
  my $list1 = $cm->restrict->($lists, 1);

  my $u1l1 = $cm->unite($user1, list1);
  $u1l1->set_property('page.colour', 'purple');

  $u1l1->get_property('page.colour'); # purple

  my $u1l2 = $cm->unite($user1 , $cm->restrict('lists' , 2));
  $u1l2->get_property('page.colour') ; # red

=head1 PERSISTENCE

To make context properties persistent accross instances of your application,
see L<Context::Set::Manager>


=head1 METHODS


=head2 fullname

Returns the fully qualified name of this context. The fullname of a context identifies the context
in the UNIVERSE in a unique manner.

=head2 name

Returns the local name of this context. fullname is more useful.

=head2 is_inside

Returns true if this storage is inside a context matching the given name.

Note that this excludes this Context::Set

Usage:

 if( $this->is_inside('users') ){ ... }

=head2 has_property

Returns true if there is a property of this name in this context.

Usage:

 if( $this->has_property('pi') ){
    ...
 }

=head2 get_property

Gets the property that goes by the given name. Dies if no property with the given name can be found.

my $pi = $this->get_property('pi');

=head2 set_property

Sets the given property to the given value. Never dies.

Usage:

  $this->set_property('pi' , 3.14159 );
  $this->set_property('fibo', [ 1, 2, 3, 5, 8, 12, 20 ]);

=head2 delete_property

Deletes the given property from this context. Dies if no property with this name exists.

Returns the current value of this property (so you have a chance to look at it a last time
before it goes away).

Usage:

  my $deleted_value = $this->delete_property('pi');


=head2 lookup

Returns the context holding the given property or undef if none is found.

Usage:

  if( my $holder_context = $context->lookup('pi') ){
     ## $holder_context is the first context holding this property.
  }

=head2 unite

Returns the Context::Set::Union of this and the other context.

usage:

  my $u = $this->unite($other_context);

=head2 restrict

Produces a new Context::Set::Restriction of this one.

Usage:

  ## Restrict to all users.
  my $context = $this->restrict('users');

  ## Further restriction to user 1
  $context = $context->restrict('1');

=head1 AUTHOR

Jerome Eteve, C<< <jerome.eteve at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-context at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Context::Set>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Context::Set


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Context::Set>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Context::Set>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Context::Set>

=item * Search CPAN

L<http://search.cpan.org/dist/Context/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerome Eteve.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

