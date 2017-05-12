package Crypt::Chimera::Event;

use strict;
use vars qw(@ISA $SEQ);
use Crypt::Chimera::Object;

@ISA = qw(Crypt::Chimera::Object);
$SEQ = 0;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{Seq} = $SEQ++;
	return $self;
}

1;
