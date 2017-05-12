package Bio::BioVeL::AsynchronousService::Mock;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService;
use base 'Bio::BioVeL::AsynchronousService';

=head1 NAME

Bio::BioVeL::AsynchronousService::Mock - example asynchronous service

=head1 DESCRIPTION

This dummy service runs the 'sleep' shell command for the provided number
of seconds, then returns with a simple text message.

=head1 METHODS

=over

=item new

The constructor defines a single object property: the number of seconds
the service should sleep for.

=cut

sub new {
	shift->SUPER::new( 'parameters' => [ 'seconds' ], @_ );
}

=item launch

Runs the shell's C<sleep> command to demonstrate asynchronous operation.
Updates the status as needed to indicate success or failure.

=cut

sub launch {
	my $self = shift;
	if ( system("sleep", ( $self->seconds || 2 ) ) ) {
		$self->status( Bio::BioVeL::AsynchronousService::ERROR );
		$self->lasterr( $? );
	}
	else {
		$self->status( Bio::BioVeL::AsynchronousService::DONE );
	}
}

=item response_body

Returns a simple text string that specifies how long the process has slept for.

=cut

sub response_body { "I slept for ".shift->seconds." seconds" }

=back

=cut

1;