package Chromosome::Map::Block;

use strict;
use base qw( Chromosome::Map::Element );

our $VERSION = '0.01';

#-------------------------------------------------------------------------------
# public methods
#-------------------------------------------------------------------------------

sub new {
	# in case of using interval for gene, the name field could be undef
	my $class = shift;
	$class = ref($class) || $class;
	
	my %Options = @_;
	
	my $self = $class->SUPER::new (-name	=> $Options{-name},
								   -loc		=> $Options{-start},
								   -color	=> $Options{-color},
								   );
	$self->{_end} = $Options{-end};

	bless $self,$class;
	return $self;
}

sub get_block_end
{
	my ($self) = @_;
	return $self->{_end};
}

1;