package Bio::Epithelium::Cell; 

sub new {
	my ($class) = @_;

	my $self = {};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub has_nucleus {
	my ($self) = @_;

	return 0;
}

1;
