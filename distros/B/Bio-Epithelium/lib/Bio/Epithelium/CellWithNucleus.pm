package Bio::Epithelium::CellWithNucleus; 

use parent 'Bio::Epithelium::Cell';

sub new {
	my ($class, $n) = @_; ### $n is a Nucleus instance
        my $self = $class->SUPER::new;

	$self->{nucleus} = $n;
}

sub has_nucleus {
	my ($self) = @_;

	return 1;
}


1;
