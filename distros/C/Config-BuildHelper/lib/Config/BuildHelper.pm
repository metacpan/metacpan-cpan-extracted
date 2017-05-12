package Config::BuildHelper;

our $VERSION = '0.02';

use base qw(Data::Classifier);

use strict;
use warnings;

use Data::Dumper;

sub return_result {
	my ($self, $ret) = @_;

	return Config::BuildHelper::Result->new($ret);
}

package Config::BuildHelper::Result;

use strict;
use warnings;

use base qw(Data::Classifier::Result);

use Data::Dumper;

sub config_list {
	my ($self) = @_;	

	if (defined($self->{QUERY_HASH})) {
		return(keys(%{$self->{QUERY_HASH}}));
	} 

	$self->{QUERY_HASH} = {};

	foreach my $one ($self->attributes('data')) {
		my $node_query = $one->{config};

		if (ref($node_query) eq 'ARRAY') {
			foreach my $one_query (@$node_query) {
				#copy this to a local variable so when
				#we shift off of it, it does not effect
				#everyone else
				my @query_list = @$one_query;
				my $op = shift(@query_list);

				if ($op eq 'ADD') {
					$self->config_add(@query_list);
				} elsif ($op eq 'REMOVE') {
					$self->config_remove(@query_list);
				} elsif ($op eq 'SET') {
					$self->config_set(@query_list);
				} else {
					die "unknown OP: $op";
				}
			}
		}
	}

	return keys(%{$self->{QUERY_HASH}});
}

sub config_add {
	my $self = shift(@_);
	my $query_hash = $self->{QUERY_HASH};
	my @queries = @_;

	foreach my $one (@queries) {
		$query_hash->{$one} = 1;
	}

	return 1;
}

sub config_remove {
	my $self = shift(@_);
	my $query_hash = $self->{QUERY_HASH};
	my @queries = @_;

	foreach my $one (@queries) {
		delete($query_hash->{$one});
	}
	
	return 1;
}

sub config_set {
	my $self = shift;
	my $query_hash = $self->{QUERY_HASH} = {};

	return $self->config_add(@_);
}

1;

__END__

=head1 NAME

Config::BuildHelper - A tool to help build config files

=head1 SYNOPSIS

  use strict;
  use warnings;
  
  use Config::BuildHelper;
  
  my $yaml = <<EOY;
  ---
  name: Root
  data:
        config: [[SET, CHECK_BRAKES, CHECK_SPARK_PLUGS]]
  children:
      - name: Car
        match: 
              model: "^(\\d{3}[a-z]?|[A-Z]\\d)\$"
        data:
              config: [[ADD, ROTATE_TIRES]]
        children:
            - name: Diesel
              match:
                    model: "d\$"
              data: 
                    config: [[REMOVE, CHECK_SPARK_PLUGS], [ADD, CHECK_GLOW_PLUGS]]
      - name: Motorcycle
        match:
              model: "^[A-Z]\\d{3,4}[^\\d]"
        data: 
              config: [[ADD, CHECK_REAR_TIRE_ALIGNMENT]]
  EOY
  
  my @customer_vehicles = (
  	{ customer_id => 1, model => '325i' },
  	{ customer_id => 2, model => '535d' },
  	{ customer_id => 3, model => 'M3' },
  	{ customer_id => 4, model => 'R1200RT' },
  );
  
  my $helper = Config::BuildHelper->new(yaml => $yaml);
  
  for (@customer_vehicles) {
  	my $result = $helper->process($_);
  
  	print "$_->{customer_id}: ";
  	
  	if (! defined($result->class)) {
  		print "could not classify data\n";
  		next;
  	}
  
  	print "$_->{model} ", join(' ', $result->config_list), "\n";
  }

__END__

Which will output:

1: 325i CHECK_SPARK_PLUGS ROTATE_TIRES CHECK_BRAKES

2: 535d ROTATE_TIRES CHECK_BRAKES CHECK_GLOW_PLUGS

3: M3 CHECK_SPARK_PLUGS ROTATE_TIRES CHECK_BRAKES

4: R1200RT CHECK_SPARK_PLUGS CHECK_BRAKES CHECK_REAR_TIRE_ALIGNMENT


=head1 OVERVIEW

B<NOTE>: This module is a very thin layer on top of Data::Classifier. While 
this documentation will cover the basics of what can be done using this 
module, more advanced operations can be performed using the functionality
included with Data::Classifier.

This is a module that helps you automatically generate configuration files
for large numbers of hosts where each host can be classified according to a
set of rules. With a good set of rules and class hierarchy you can even handle
the edge cases in your configurations with ease.

The example above could be used by a BMW dealer to automatically generate a
report of what maintnance should be performed on customer cars using only the
car model number. In this hypothetical situation, everything the dealer 
services has approximately the same requirements, except a few special cases.

Once this has been defined in the class hierarchy, the module will give back
a list of operations that should be performed for what ever host you specified
during the request. This is nothing more than a list of strings; figuring out
exactly the steps to implement a configuration item for one of the returned 
values is left as an exercise for the user of this module. 

=head1 USAGE

Using this module involves creating an instance of it and then passing in
bits of information to classify as hashes. During creation of an instance,
you must pass in a class specification some how, either as a yaml file, a
yaml string, or a prebuilt data structure. 

=head2 METHODS

=over 4

=item $helper = Config::BuildHelper->new(%options)

Create a new instance of Config::BuildHelper. This is passed right on through
to Data::Classifier so see the documentation for that method for all the ways
to specify a class hierarchy and available runtime options.

=item $result = $helper->process($data)

Requests a result object for a given piece of data (as a hash reference). The 
result object contains the list of config items for the data you specified
to process.

=back

=head2 Result Classes

The result class contains all the information about the data passed in to the
process method. This includes the list of strings generated and other 
information about the class and hierarchy (from Data::Classifier::Result). 

=head3 Methods

=over 4

=item $result->config_list

Returns a list of strings representing the config operations to perform.

=back

=head1 AUTHORS

This module was created and documented by Tyler Riddle E<lt>triddle@gmail.comE<gt>.

=head1 BUGS

There are no known bugs at this time.

Please report any bugs or feature requests to
C<bug-config-buildhelper@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config::BuildHelper>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

