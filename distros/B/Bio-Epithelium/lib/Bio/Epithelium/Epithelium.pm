package Bio::Epithelium::Epithelium;

use parent 'Bio::Epithelium::CellSystem';

### specialize into different epithelium classes

sub new {
	my ($class, @cells) = @_;
        my $self = $class->SUPER::new(@cells);

}

1;
