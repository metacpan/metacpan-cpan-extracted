package Bio::Epithelium::Nucleus; 

sub new {
	my ($class, @g) = @_;

	my $self = { genomes => @g, };

	$class = ref($class) || $class;

	bless $self, $class;
}


1;
