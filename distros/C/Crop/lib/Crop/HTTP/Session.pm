package Crop::HTTP::Session;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::HTTP::Session
	HTTP Session.
	
	A Session remembers a pair of cookies. If last request fails, previous cookie
	is used to look up the session.
=cut

use v5.14;
use warnings;

use Digest::MD5 qw/ md5_hex /;

use Crop::DateTime;
use Crop::HTTP::Session::Thru;

use Crop::Error;
use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:

	cookie   - last cookie
	cookie2  - pre last cookie in case of setting new cookie failure
	ctime    - creation time
	id_client - Client ID; always exists
	mtime    - modified
	notes    - 'fake', supposed users
	referer  - URL to redirect;
	error    - error to client
=cut
our %Attributes = (
	cookie    => {mode => 'read'},
	cookie2   => undef,
	ctime     => undef,
	id_client => {mode => 'read/write'},
	mtime     => {mode => 'write'},
	notes     => undef,
# 	referer   => undef,
	error     => undef,
);

=begin nd
Method: generate_cookie ( )
	Set cookie string to the 'cookie' attribute.
	
	All requests set fresh cookie to a client.
	
	Copies existing cookie to cookie2.
	
	This method can be called with server stopped.
	
Returns:
	$self
=cut
sub generate_cookie {
	my $self = shift;
	
	if ($self->{cookie}) {
		$self->{cookie2} = $self->{cookie} if $self->{cookie} eq $self->S->request->cookie_in;
	} elsif ($self->{cookie2}) {
		undef $self->{cookie2};
	}

	my $tik = $self->S->can('tik') ? $self->S->tik : Crop::DateTime->new;  #  if the Server is not running
	
	$self->{cookie} = sprintf "%s-%s%06s",
		md5_hex(rand),
		$tik->sec,
		$tik->usec;
	
	$self->Modified;
}

=begin nd
Method: pass_thru ( )
	Save input for next request.

	Form handler pass thru the current request input to the next request for use original user's data by the same form
	highlighting errors and filling form fields.

	To restore early saved input and errors, use <restore_param ( )>
=cut
sub pass_thru {
	my $self = shift;

	my $thru = Crop::Object::Collection->new('Crop::HTTP::Session::Thru');

# 	my $rp = $self->S->I;
	my $param = $self->S->request->param;
# 	debug 'CROPHTTPSESSION_PASSTHRU_REQUEST=', $param;
	while (my ($p, $v) = each %$param) {
		$thru->Push({
			id_session => $self->{id},
			param      => $p,
			value      => $v,
		});

	}


# 	debug 'CROPHTTPSESSION_PASSTHRU_ATWORK';
	my $error;
	Crop::Error::bind $error;
# 	debug 'CROPHTTPSESSION_PASSTHRU_ERR=', $error;

# 	my $thru = Crop::Object::Collection->new('Crop::HTTP::Session::Thru');
	while (my ($err, $val) = each %$error) {
		$thru->Push({
			id_session => $self->{id},
			param      => "ERROR.$err",
			value      => $val,
		});
	}

# 	debug 'CROPHTTPSESSION_PASSTHRU_THRU=', $thru;
}

=begin nd
	Method: restore_thru ( )

	Restore previously saved parameters to use in form where a handler has failed.
=cut
sub restore_thru {
	my $self = shift;

	my $thru = Crop::HTTP::Session::Thru->All(id_session => $self->{id});
	for ($thru->List) {
# 		debug 'CROPHTTPSESSION_RESTORETHRU_PARAM=', $_;
		my @param = split '\.', $_->param;
# 		debug 'CROPHTTPSESSION_RESTORETHRU_PARAMS=', \@param;
		my $last_name = pop @param;

		my $cur_node = $self->S->O;
		while (my $next = shift @param) {
# 			debug 'CROPHTTPSESSION_RESTORETHRU_NEXT=', $next;
			$cur_node->{$next} = {} unless exists $cur_node->{$next};
			$cur_node = $cur_node->{$next};
		}
		$cur_node->{$last_name} = $_->value;

		$_->Remove;
	}

	$self->S->request->param;

# 	debug 'CROPHTTPSESSION_RESTORETHRU_O=', $self->S->O;

# 	for
# 	if (not $param->Is_empty) {
# 		;  # delete $param's
# 	}
}

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'session' string
=cut
sub Table { 'session' }

1;
