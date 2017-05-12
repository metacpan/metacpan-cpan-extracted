package AppWithParams;

use base 'CGI::Application';

sub setup {
	my $self = shift;
	$self->start_mode('mode1');
	$self->mode_param('rm');
	$self->run_modes(
	        'mode1' => 'a_run_mode',
	);
}	

sub a_run_mode {
    my ($self) = @_;
    
	return '<HTML><TITLE>' 
	    . $self->param('message')
	    . '</TITLE><BODY><H1>'
	    . $self->param('message')
	    . "</H1><HR></BODY></HTML>";		
}

1;
