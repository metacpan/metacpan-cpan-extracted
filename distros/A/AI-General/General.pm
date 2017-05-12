package AI::General;

use 5.008;
use strict;
use warnings;


our $VERSION = '0.01';


sub new {
	my ( $class ) = @_;
	my $self = bless [], $class;
	$self->dwim( "Implement self" );
	return $self;
}


sub dwim {
	my ( $self, $args ) = @_;

	#... TO DO
}
	

1;


__END__

=head1 NAME

AI::General - A general-purpose artificial intelligence

=head1 SYNOPSIS

  use AI::General;
  
  AI::General->dwim( "Prove NP != P" ) or
  	die $AI::General::excuse;
  	
  
  
=head1 DESCRIPTION

This module is a general purpose artificial intelligence.  It consists
of one method, dwim ('Do what I mean'), which can take any number of 
arguments.  

=head1 TO DO

Implement dwim()

=head1 CREDITS

Cheers to Santiago Dala for suggesting the constructor implementation

=head1 AUTHOR

Maciej Ceglowski, E<lt>maciej@ceglowski.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
