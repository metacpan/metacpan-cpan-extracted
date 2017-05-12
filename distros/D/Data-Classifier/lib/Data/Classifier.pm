package Data::Classifier;

our $VERSION = '0.01';

use strict;
use warnings;

use Carp qw(croak);
use YAML qw(LoadFile Load);

use Data::Classifier::Result;

#public interface
sub new {
	my ($class, %opts) = @_;
	my $self = {};

	bless($self, $class);

	if (defined($opts{file})) {
		$self->{TREE} = LoadFile($opts{file});
	} elsif (defined($opts{yaml})) {
		$self->{TREE} = Load($opts{yaml});
	} elsif (defined($opts{tree})) {
		$self->{TREE} = $opts{tree};
	} else {
		croak "You must specify one of file, yaml, or tree";
	}

	$self->{DEBUG} = $opts{debug};

	return $self;
}

sub process {
	my ($self, $attributes) = @_;
	my ($result, $result_class);

	$self->debug("starting classification");

	$self->{CLASS_STACK} = [];

	$self->recursive_search($attributes, $self->{TREE});

	$result = $self->{CLASS_STACK};

	$self->{CLASS_STACK} = undef;	

	$self->debug("classification done\n\n");

	return $self->return_result($result);
}

#this method should be overloaded by base classes to change the class
#that is returned by process
sub return_result {
	my ($self, $result) = @_;
	return Data::Classifier::Result->new($result);
}

sub dump {
	my ($self) = @_;

	return Dumper($self->{TREE});
}

#private interface
sub recursive_search {
	my ($self, $attributes, $node) = @_;
	my $name = $node->{name};
	my $matchmap = $node->{match};
	my $children = $node->{children};
	my $class_stack = $self->{CLASS_STACK};
	my $node_match = 0;
	my $recurse_match = 0;
	my $generic_match = 0;

	$self->debug("testing $name");

	push(@$class_stack, $node);
	
	if (! defined($matchmap)) {
		#no rules for this class, so we will be a member of it only if a lower
		#rule applies
		$node_match = 1;
		$generic_match = 1;
	} elsif (ref($matchmap) ne 'HASH') {
		$self->tree_error("match was not a map");
	} else {
		if ($self->check_match($matchmap, $attributes)) {
			$node_match = 1;
		}
	}

	if ($node_match) {
		#check the children for a more specific class
		$self->debug("looking at child classes");

		if (defined($children)) {
			if (ref($children) ne 'ARRAY') {
				$self->tree_error("children must be a sequence");
			}

			foreach my $child (@$children) {
				if ($self->recursive_search($attributes, $child)) {
					$recurse_match = 1;
					last;
				}
			}
		}
	}

	if ($generic_match && ! $recurse_match) {
		#didn't match a lower level class after a generic match, so this is really no match
		pop(@$class_stack);
		return 0;
	} elsif (! $node_match) {
		pop(@$class_stack);
		return 0;
	}

	return 1;
}

#only return true if everything in $matchlist matches the stuff in $attributes
sub check_match {
	my ($self, $matchlist, $attributes) = @_;
	my $match = 0;

	#no idea why this has to be here, but with out it, matches fail
	#for very odd reasons - not sure if it's my bug or a perl bug, but it's
	#very strange
	keys(%$matchlist);

	while(my ($attribute, $regex) = each(%$matchlist)) {
		my $to_test = $attributes->{$attribute};

		if (! defined($to_test)) {
			$self->debug("nothing to test");
			return 0;
		}

		if (! defined($regex)) {
			$self->debug("no regex");
			die "regex";
		}

		if ($to_test !~ m/$regex/) {
			$self->debug("match failure");
			return 0;
		}

		$self->debug("testing data $attribute $regex '$to_test'");	

		$match = 1;
	}

	if ($match) {
		$self->debug("success");

		return 1;
	}

	$self->debug("fell through with no matches");

	return 0;
}

sub tree_error {
	my ($self, $msg) = @_;
	my $class_stack = $self->{CLASS_STACK};
	my @names;

	foreach my $one (@$class_stack) {
		push(@names, $one->{name});
	}

	$self->debug("ERROR: Class tree was not consistent: $msg\n");
	$self->debug("\tClass path: ", join('::', @names), "\n");

	die "can not continue after class tree error";
}

sub debug {
	my ($self, $msg) = @_;
	print STDERR "DEBUG: $msg\n" if $self->{DEBUG};
}

1;

__END__

=head1 NAME

Data::Classifier - A tool for classifying data with regular expressions

=head1 SYNOPSIS

    use strict;
    use warnings;
    
    use Data::Classifier;
    
    my $yaml = <<EOY;
    ---
    name: Root
    children:
        - name: BMW
          children:
              - name: Diesel
                match:
                      model: "d\$"
              - name: Sports
                match:
                      model: "i\$"
                      seats: 2
              - name: Really Expensive
                match:
                      model: "^M"
    EOY
    
    my $classifier = Data::Classifier->new(yaml => $yaml);
    my $attributes1 = { model => '325i', seats => 4 };
    my $class1 = $classifier->process($attributes1);
    my $attributes2 = { model => '535d', seats => 4 };
    my $class2 = $classifier->process($attributes2);
    my $attributes3 = { model => 'M3', seats => 2 };
    my $class3 = $classifier->process($attributes3);
    print "$attributes2->{model}: ", $class2->fqn, "\n";
    print "$attributes3->{model}: ", $class3->fqn, "\n";
    #no real sports car has 4 seats
    print "$attributes1->{model}: ", $class1->fqn, "\n";

=head1 OVERVIEW

This module provides tools to classify sets of data contained in hashes
against a predefined class hierarchy. Testing against a class
is performed using regular expressions stored in the class hierarchy. It
is also possible to modify the behavior of the system by subclassing and
overloading a few methods. 

Note that this module may not be particularly usefull on its own. It is
designed to be used as a base class for implementing other systems, such 
as Config::BuildHelper.

=head1 USAGE

Using this module involves creating an instance of the classifier object, 
passing the class hierarchy in via a YAML file, a YAML string, or prebuilt
data structure, and any optional arguments: 

    $classifier = Data::Classifier->new(file => 'classes.yaml', debug => 1);
    $classifier = Data::Classifier->new(yaml => $yaml_string);
    $classifier = Data::Classifier->new(tree => $hashref);

=head2 Class Definition File

The class definition file is a very specific tree format, normally stored in 
a YAML file. Each node of the tree is a map with the same set of keys, some of which are optional:

=over 4

=item name

The textual name of the node being defined.

=item data (optional)

Extra data to be returned with classification results.

=item children (optional)

A sequence of nodes that exists under this node.

=item match (optional)

A map of keys to test against incomming data and regular expressions to apply 
to that data. For a match to be true, all items in the map must match the data.

=back

=head2 Matching Semantics

By default, this class has very specific matching semantics. For a dataset to
match a node, everything listed under the match definition must match the 
specified data. Additionally, a node which contains no match definition will
have all of it's children searched but can never be a match itself.

=head2 Methods

=over 4

=item $result = $classifier->process($attr)

Classify the data contained in the hash reference stored in $attr and return
an instance of Data::Classifier::Result. See the documentation for that class
for more information.

=item $classifier->dump

Return a textual representation of the class hierarchy stored in RAM.

=back

=head2 More Information

The rest of this module is documented in Data::Classifier::Result, which you
use to access the results of classification.

=head1 SUBCLASSING

This class can be subclassed to change its behavior. The following methods
are available for overloading:

=over 4

=item $classifier->return_result($result)

This method is invoked by $classifier->process() when it needs to return a new
instance of a result class. Simply return an instance of your class here, such 
as:

    sub return_result {
            my ($self, $result) = @_;
            return Data::Classifier::Result->new($result);
    }

=item $classifier->check_match($matchlist, $attributes)

This method is invoked by $classifier->recursive_match() at each node of the 
tree that contains a match attribute. The entire contents of the match 
attribute will be passed in as $matchlist and the hashref given to
$classifier->process() will be passed in via $attributes. Return true to 
indicate a match and false to indicate no match.

=item $classifier->recursive_search($attributes, $node)

This method is invoked by $classifier->process() to recursively search the
entire tree. If you need to change the semantics of how the classifier treats
matches against nodes with out a match attribute, you would do that here.

=back

=head1 IMPROVEMENTS

Here are a few ideas for improvements to this class:

=over 4

=item Data::Classifier::SQLTree

A class that stores it's tree in a SQL database, reconstructs it at startup,
and passes it in using the tree argument to new.

=back

=head1 AUTHORS

This module was created and documented by Tyler Riddle E<lt>triddle@gmail.comE<gt>.

=head1 BUGS

There are no known bugs at this time.

Please report any bugs or feature requests to
C<bug-data-classifier@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data::Classifier>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

