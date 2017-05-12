package MyCGIApp;

use base 'CGI::Application';

use CGI::Application::Plugin::Redirect;

sub setup {
	my $self = shift;
	$self->start_mode('mode1');
	$self->mode_param('rm');
	$self->run_modes(
	        'mode1' => 'hello_world',
	        'mode2' => 'goodbye_world',
	        'mode3' => 'redirected',
	        'mode4' => 'redirect_end',
	);
}	

sub hello_world {
	return "<HTML><TITLE>Hello</TITLE><BODY><H1>Hello World!</H1><HR>" . 
		   "<A HREF='index.cgi?rm=mode2'>Goodbye</A>" . 
		   "<A HREF='index.cgi?rm=mode3'>Redirected</A>" . 
		   "</BODY></HTML>";
}

sub goodbye_world {
	return "<HTML><TITLE>Goodbye</TITLE><BODY><H1>Goodbye World!</H1><HR>" . 
	       "<A HREF='index.cgi?rm=mode1'>Hello</A>" . 
	   	   "</BODY></HTML>";		
}

sub redirected {
    my $self = shift;
    return $self->redirect( "/index.cgi?rm=mode4" );
}

sub redirect_end {
	return "<HTML><TITLE>Redirect End</TITLE><BODY><H1>Redirected!</H1><HR>" . 
	       "<A HREF='index.cgi?rm=mode1'>Back to Hello</A>" . 
	   	   "</BODY></HTML>";		
}

1;
