package Data::Classifier::Result;

our $VERSION = '0.01';

use strict;
use warnings;

#private interface
sub new {
	my ($class, $stack) = @_;
	my $self = {};

	bless($self, $class);

	$self->{STACK} = $stack;

	$self->init;

	return $self;
}

#this method is intended to be overloaded by subclasses to further customize
#the behavior of the classification, such as insctructions to execute at class
#boundries 
sub init {
	return;
}

#public interface

#returns the most specific class node that matched or undef if no
#classification was possible
sub class {
	my ($self) = @_;
	my @stack = $self->stack;
	my $last = $#stack;

	return $stack[$last];
}

sub stack {
	my ($self) = @_;

	return @{$self->{STACK}};
}

sub fqn {
	my ($self) = @_;
	my $classes = $self->{STACK};
	my @tmp;

	foreach my $class (@$classes) {
		push(@tmp, $class->{name});
	}

	return join('::', @tmp);
}

#returns the most specific class name
sub name {
	my ($self) = @_;
	my $class = $self->class;

	return $class->{name};
}

#return a list of data attributes
sub attributes {
	my ($self, $attribute) = @_;
	my @ret;

	foreach ($self->stack) {
		push(@ret, $_->{$attribute});
	}

	return @ret;
}

1;

__END__

=head1 NAME

Data::Classifier::Result

=head1 OVERVIEW

B<NOTE>: You should have already read the documentation for Data::Classifier
which has an example on how to produce Data::Classifier::Result instances.

This class represents results from classification requests sent to a
Data::Classifier instance.

=head1 METHODS

=over 4

=item $class = $result->class

Returns the most specific class that matched as a hash; this includes all of 
the attributes stored in a node. If no classification could be done, this 
returns undef.

=item @classes = $result->stack

Returns a list of the entire class hierarchy for the result. The root node is
at 0 and the most specific node is at the end.

=item $name = $result->name

Returns a string that is the name of the most specific class that matched.

=item $fqn = $result->fqn

Returns a string of the entire class path name for the match, seperated by
double colons. For instance: Root::BMW::Sports

=item @attributes = $result->attributes

Returns a list of the specified attributes for all the nodes in the matching 
class hierarchy. The root node is at 0 and the most specific node is at the 
end. If a node has no attribute by this name, undef will be stored in the list
at its corresponding position.

=back

=head1 SUBCLASSING

This class is designed to be subclassed and be used in conjuction with other 
classes that extended the functionality of Data::Classifier. 

The following methods are designed to be overloaded to change behavior:

=over 4

=item $result->init

This method will be called as the last step in the constructor, prior to 
actually returning the new instance. If you need to do any kind of 
initialization in your subclass, this would be the place to do it.

=back

=head1 IMPROVEMENTS

This class could probably use a method that searches through the tree, like 
the look_down method on HTML::Element

=head1 MORE INFORMATION

This is a class used by Data::Classifier - see the documentation for that
class for information on authors and bugs and for more documentation.
