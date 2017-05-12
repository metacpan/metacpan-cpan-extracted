package Algorithm::Genetic::Diploid::Base;
use strict;
use Algorithm::Genetic::Diploid::Logger;
use YAML::Any qw(Load Dump);

my $id = 1;
my $experiment;
my $logger = Algorithm::Genetic::Diploid::Logger->new;

=head1 NAME

Algorithm::Genetic::Diploid::Base - base class for core objects

=head1 METHODS

=over

=item new

Base constructor for everyone, takes named arguments

=cut

sub new {
	my $package = shift;
	$logger->debug("instantiating new $package object");
	my %self = @_;
	$self{'id'} = $id++;
	
	# experiment is provided as an argument
	if ( $self{'experiment'} ) {
		$experiment = $self{'experiment'};
		delete $self{'experiment'};
	}
	
	# create the object
	my $obj = \%self;
	bless $obj, $package;
	
	# maybe the object was the experiment?
	if ( $obj->isa('Algorithm::Genetic::Diploid::Experiment') ) {
		$experiment = $obj;
	}
	
	return $obj;
}

=item logger

The logger is a singleton object so there's no point in having each object carrying 
around its own object reference. Hence, we just return a static reference here to the
L<Algorithm::Genetic::Diploid::Logger> object.

=cut

sub logger { $logger }

=item experiment

We don't want there to be circular references from each object to the experiment 
and back because it will create recursive YAML serializations and interfere with 
object cloning. Hence this is a static method to access the 
L<Algorithm::Genetic::Diploid::Experiment> object.

=cut

sub experiment {
	my $self = shift;
	$experiment = shift if @_;
	return $experiment;
}

=item id

Accessor for the numerical ID, which is generated when the object is instantiated

=cut

sub id { shift->{'id'} }

=item dump

Write the object to a YAML string

=cut

sub dump {
	my $self = shift;
	my $string = Dump($self);
	return $string;
}

=item load

Read an object from a YAML string (static method)

=cut

sub load {
	my ( $package, $raw ) = @_;
	return Load($raw);
}

=item clone

Clone an object by writing, then reading

=cut

sub clone {
	return __PACKAGE__->load(shift->dump);
}

=back

=cut

1;