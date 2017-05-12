package Class::Classless::C3;
use 5.006;
use strict;
use warnings;
our $VERSION = '1.00';

use Algorithm::C3;

# set this to a scalar ref for tracing
our $trace;

# the root object
our $ROOT;

# for caching results from Algorithm::C3::merge
our %c3cache;

# Class::Classless::C3->new( ['name', method=>sub, ... ] )
# $classless->new( [ 'name', method => sub, ... ] )
# name recommended
sub new
{
	my $parent = shift;
	my $class = ref $parent || $parent;
	my $self = bless {}, $class;
	# Meta class is not subclassable this way....
	$self->{_meta} = Class::Classless::C3::Meta->new();
	$self->meta->parent(ref $parent ? $parent : $ROOT);
	my $name = shift;
	$self->meta->name($name);
	$self->meta->addmethod( splice(@_,0,2) ) while @_;
	$self->init($name,@_);
	return $self;
}

$ROOT = bless {}, 'Class::Classless::C3';
$ROOT->{_meta} = Class::Classless::C3::Meta->new();
$ROOT->meta->name('ROOT');
$ROOT->meta->addmethod( init => sub {} );


sub meta
{
	return $_[0]->{_meta};
}

our $AUTOLOAD;
# top level call
sub AUTOLOAD
{
	my $self = $_[0];
	my $sub = $self->can($AUTOLOAD) or
		die("cannot call method ".($AUTOLOAD =~ m/([^:]*)$/g)[0]." on ".(ref($self)?$self->{_meta}->{name}:"'$self'"));
	$$trace .= "called ".$self->{_meta}->name."->".($AUTOLOAD =~ m/([^:]*)$/g)[0]." (@_[1..$#_])\n" if ref $trace eq 'SCALAR';
	goto $sub;
}

# inherited call
sub NEXT
{
	my $self = $_[0];
	my $class;
	my $method;
	my $level = 1;
	my $caller;
	# caller is subname-ed to instance-name::method-name
	while ($caller = (caller($level++))[3]) {
		($class,$method) = ($caller =~ m/^(.*)::([^:]+)$/s);
		last unless $method =~ m/^(\(eval\)|__ANON__|DB::.*)$/;
	}
	# need to start from parent of owner of current method
	my $sub = $self->can($method,from=>$class);
	return unless $sub;	# do not die on NEXT
	$$trace .= "NEXT $method from $class\n" if ref $trace eq 'SCALAR';
	goto $sub;
}

sub VERSION
{
	# stub
}

sub isa
{
	my $self = shift;
	my $what = shift;

	my $c3 = $c3cache{$self->{_meta}->{name}} ||= [
		Algorithm::C3::merge( $self,
			sub { @{ $_[0]->{_meta}->{parents} } },
		)];
	if (ref $what) {
		return grep($_ eq $what, @$c3) ? 1 : 0;
	} else {
		return grep($_->{_meta}->{name} eq $what, @$c3) ? 1 : 0;
	}
}

# this is here to avoid calling can('DESTROY') after meta is gone
sub DESTROY
{
}

sub can
{
	my $self = shift;
	my $method = shift;
	$method =~ s/^.*:://;
	my $from = $_[0] && $_[0] eq 'from' ? $_[1] : undef;

	if (!$self->{_meta}) { warn("cannot can '$method' without meta"); }
	my $c3 = $c3cache{$self->{_meta}->{name}} ||= [
		Algorithm::C3::merge( $self,
			sub { @{ $_[0]->{_meta}->{parents} } },
		)];
	my $sub;
	for my $o ( @$c3 ) {
		if ($from) {
			next if $o->{_meta}->{name} ne $from;
			undef $from;
			next;
		}
		if (ref $o && $o->{_meta}) {
			$sub = $o->{_meta}->{methods}->{$method};
			return $sub if $sub;
			# for optional autoload-like behavior
			if (ref $Class::Classless::C3::autoload eq 'CODE') {
				$sub = $Class::Classless::C3::autoload->($o,$method);
				return $sub if $sub;
			}
		} else {
			$sub = UNIVERSAL::can($o,$method);
			return $sub if $sub;
		}
	}
	# catch methods defined in Class::Classless::C3
	$sub = UNIVERSAL::can($self,$method);
	return $sub if $sub;

	return undef;
}

$Class::Classless::C3::autoload ||= '';


package # hide from pause
	Class::Classless::C3::Meta;
use Sub::Name;

$Class::Classless::C3::Meta::uid = 0;

sub new
{
	my $object = shift;
	my $class = ref $object || $object;
	my $self = bless {}, $class;
	$self->init(@_);
	return $self;
}

sub init
{
	my $self = shift;
	$self->{parents} = [];
}

sub name
{
	my $self = shift;
	if (@_) {
		$self->purge_c3cache if $self->{name};
		my $name = shift;
		$self->{name} = $name;
		unless ($self->{name}) {
			$self->{name} = 'x_'.++$Class::Classless::C3::Meta::uid;
		}
		subname $name.'::'.$_ => $self->{methods}->{$_} for keys %{$self->{methods}};
		$self->purge_c3cache;
	}
	return $self->{name};
}

sub parent
{
	my $self = shift;
	if (@_) {
		# clear any isa caching 
		$self->purge_c3cache if @{$self->{parents}};
		my $par = shift;
		die("called parent with nonref '$par'") unless ref $par;
		$self->{parents} = [$par];
	}
	return $self->{parents}->[0];
}

sub parents
{
	my $self = shift;
	if (@_) {
		$self->purge_c3cache if $self->{parents};
		if (ref $_[0] eq 'ARRAY') {
			$self->{parents} = [@{$_[0]}];
		} else {
			$self->{parents} = [@_];
		}
	}
	# return a copy of the array, so they cannot change our copy
	# we need to clear the c3cache if our copy changes
	return @{$self->{parents}};
}

sub addparent
{
	my $self = shift;
	my $newp = shift;
	return unless $newp;
	$self->purge_c3cache;
	# maybe this should unshift???
	push @{ $self->{parents} }, $newp;
}

sub addmethod
{
	my $self = shift;
	my($name,$sub) = @_;
	my $fullname = $self->{name}.'::'.$name;
	$self->{methods}->{$name} = subname $fullname => $sub;
}

sub delmethod
{
	my $self = shift;
	my($name) = @_;
	delete $self->{methods}->{$name};
}

sub clone
{
}

# creates a Classless object from an existing package
sub declassify
{
	my $class = shift;
	my $self = Class::Classless::C3->new($class);

	no strict 'refs';
	my $symtable = \%{$class.'::'};
	for my $sym ( keys %$symtable ) {
		next if $sym =~ m/^(AUTOLOAD|NEXT|can|isa|VERSION|meta|new)$/;
		my $sub = *{$symtable->{$sym}}{CODE};
		if (defined $sub) {
			$self->meta->addmethod($sym => $sub);
			delete ${$class.'::'}{$sym};  #deletes all glob-parts
		}
	}
	return $self;
}

# clear any c3cache entries which contain this object
# (called when an object's parents change or object's name changes)
sub purge_c3cache
{
	my $self = shift;
	my $who = shift || $self->{name};
	for my $k (keys %Class::Classless::C3::c3cache) {
		if (grep $who eq $_->{_meta}->{name}, @{ $Class::Classless::C3::c3cache{$k} }) {
			delete $Class::Classless::C3::c3cache{$k};
		}
	}
}

sub show_c3cache  # for debugging
{
	my $self = shift;
	return join ',',
		map { $_->meta->name }
		@{ $Class::Classless::C3::c3cache{$self->{name}} };
}


1;
__END__

=head1 NAME

Class::Classless::C3 - Classless object system framework

=head1 SYNOPSIS

  use Class::Classless::C3;

  # create a new object
  my $a = Class::Classless::C3::ROOT->new('a');
  my $b = Class::Classless::C3->new('b');   # ROOT is default parent

  # create derived object
  my $c = $b->new('c');

  # attributes (not inherited) and methods (inherited)
  $b->{'attribute'} = 'exists';
  $b->meta->addmethod('method' => sub { "exists" });

  print $c->{'attribute'};  # ''
  print $c->method;         # 'exists'
  
=head1 DESCRIPTION

This implements a classless object system, very similar to L<Class::Classless>.

There are two major differences.  One is that Class::Classless::C3 relies 
on L<Algorithm::C3> to determine the inheritance tree, which outsources the
most complicated part of the code.  

The more important difference is that there is no C<$callstate> object passed
around in Class::Classless::C3.  This means methods can be written in 
exactly the same way methods are written in other perl objects.
The job formerly done by $callstate is now accomplished using L<Sub::Name>.

=head1 Classless Objects

As with Class::Classless, all objects are created by inheriting from a $ROOT
object.  Objects can have attributes (data members) which are not inherited,
and can have methods added to them, which will be inherited by sub-objects.

A Class::Classless::C3 object is a blessed hash reference, so attributes are
merely hash entries.

The only "special" hash key is called C<_meta>, 
but you should use the C<meta> accessor method. 
It contains a classless meta
object which contains all the meta information for the class, including its
name, parent(s), and methods.  It is also used when altering the class meta
information.  

=head1 OBJECT METHODS

=head2 $obj2 = $obj->new( ['name'] )

Creates a new $obj2, with the given name, with $obj as the parent.
This is like the 'clone' method from Class::Classless.  
If no name is given, and unique name will be autogenerated.
It calls an 'init' method, which you can override for object initialization.

=head2 $self->NEXT(@_);

This is how to call the same method in the superclass.  It will dispatch
in C3 method resolution order.
 
It is similar to the use of C<SUPER::> in normal perl objects, and equivalent
to C<next::method> from L<Class::C3>.

It is a no-op if the method does not exist in any superclass. 

=head2 $obj->can( 'methodname' )

Checks whether an object (or its parents) can execute the given method,
and returns a code reference for the method.

=head2 $obj->isa( $objn )

Returns true if $obj is a descendant of the argument, which can be
an object or an object name.  The 'can' method is more useful.

=head2 $obj->VERSION

Should return a version number, if your object has one.

=head2 $obj->meta

Returns the meta-object, used for altering the object meta-information,
such as the object name, parent object(s), and adding methods.


=head1 OBJECT META METHODS

=head2 $obj->meta->name( ['name'] )

Gets or sets the object's name.

=head2 $obj->meta->parent( [$obj2] )

Gets or sets the object's parent.  This method only supports single inheritance.

=head2 $obj->meta->parents( [$obj3, $obj4, ...] )

Gets or sets multiple parents for an objects, in order to support
multiple inheritance.

=head2 $obj->meta->addparent( $obj5 )

Adds another parent to the object.  This is the most common method
of setting up multiple inheritance.

=head2 $obj->meta->addmethod( 'mymethod' => sub { 'this is what i do' } )

Adds a new method to an object.  Requires a method name and a code ref.

=head2 $obj->meta->delmethod( 'mymethod' )

Deletes a method from an object.

=head1 Miscellany

These are some extra features provided by Class::Classless::C3.
I'm not sure why B<you> would use them, but I found a use for them.

=head2 Class::Classless::C3::Meta::declassify

This is a convenience method to create a classless object from an existing
perl package. The statement

  $parent = Package->Class::Classless::C3:Meta::declassify();

will create a classless object with all the methods defined in 'Package',
which you could use as a parent for a lot of other generated classless
objects.  Mainly, it makes writing the code for the parent object
more straight-forward and perlish.

=head2 $Class::Classless::C3::autoload

If you assign a coderef to this variable, it will activate an autoload-like
feature.

If $obj->method is called, and method does not exist, this autoload sub
is called (with the object and methodname as arguments) it give it a
chance to create the method.  It should return a coderef on success, 
which will be called.  It can also do $obj->meta->addmethod to avoid
this overhead in the future.

=head2 $Class::Classless::C3::trace

If this is assigned to a scalar ref (not a scalar), every time a classless
method or NEXT is called, debug information will be appended to the string.

=head1 NOTES

All classless objects are blessed in to the Class::Classless:C3 namespace,
so to determine if an object is classless, just ask whether 
C<ref($obj) eq 'Class::Classless::C3'>

Algorithm::C3 will die on invalid inheritance trees.  The algorithm used
in Class::Classless would try anyway, not necessarily with sane results.

=head1 SEE ALSO

The original L<Class::Classless>

=head1 AUTHOR

John Williams, smailliw@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by John Williams. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
