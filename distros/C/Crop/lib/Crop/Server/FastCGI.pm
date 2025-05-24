package Crop::Server::FastCGI;
use base qw/ Crop::Server /;

=begin nd
Class: Crop::Server::FastCGI
	Server uses FastCGI protocol.
=cut

use v5.14;
use warnings;

use CGI::Fast;

use Crop::Debug;
use Crop::HTTP::Request::FastCGI;

=begin nd
Variable: our %Attributes
	Class attributes:

	cgi - object of Common Gateway Interface
=cut
our %Attributes = (
	cgi => {mode => 'read'},
);

=begin nd
Method: _flush ( )
	Send the result back to a client.
=cut
sub _flush {
	my $self = shift;
	
	$self->{redirect} // print $self->{cgi}->header(@{$self->{headers}}), $self->{content};
}

=begin
Method: _init_httprequest ( )
	Create Request object.
	
	Set start time to Request.
=cut
sub _init_httprequest {
	my $self = shift;
	
	$self->{request} = Crop::HTTP::Request::FastCGI->new(tik => $self->{tik}->timestamp);
}

=begin nd
Method: listen ( )
	Main loop is specific for Gateway Interface.

Returns:
	Nerver returns.
=cut
sub listen {
	my $self = shift;
	
	while ($self->{cgi} = CGI::Fast->new) {
		$self->_work;
	}
}

=begin nd
Method: _redirect ( )
	Send redirect to a client.
=cut
sub _redirect {
	my $self = shift;

	print $self->{cgi}->redirect(
		-uri    => $self->{redirect},
		-status => 303,
	);
}

=begin nd
Method: _sendfile ( )
	Send X-Accel-Redirect to Nginx.
	
	This method fetches file data from an structure of <Crop::File::Send> type stored in the 'Server.sendfile' attribute.
=cut
sub _sendfile {
	my $self = shift;
	my $sendfile = $self->sendfile;
	
	print $self->{cgi}->redirect(
		"-X-Accel-Redirect"   => $sendfile->url,
		"Content-Disposition" => $sendfile->disposition . '; filename=' . $sendfile->name,
	);
}

=begin nd
Method: upload_size ($field)
	Get upload from multipart-form.
	
Parameters:
	$field - name of field in multipart-form
	
Returns:
	Size in bytes.
=cut
sub upload_size {
	my ($self, $field) = @_;
	
	-s $self->cgi->upload($field);
}

1;
