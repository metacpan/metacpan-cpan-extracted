package Bio::Epithelium::CellSystem; 

sub new {
	my ($class, @cells) = @_;

	my $self = { cells => @cells, };

	$class = ref($class) || $class;

	bless $self, $class;
}


1;
