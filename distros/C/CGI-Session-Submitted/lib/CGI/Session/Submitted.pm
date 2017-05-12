package CGI::Session::Submitted;
use strict;
use Carp;
use base qw(CGI::Session);
use CGI;
#use Smart::Comments '###'; # we'll use this for debug
use warnings;
#this is to get version num according to cvs
our $VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)/g;

sub run {
	my $self = shift;
	$self->{preset} = shift; 
	$self->{args} = shift;	
	
	(ref $self->{preset}) eq 'HASH' or croak('arg must be hash ref');
	my $preset = $self->{preset};
		
	### param_presets from Submitted.pm	
	if ($self->is_new){ 
		### is new , setting defaults
		$self->param( $preset );
		### ok, assuring cookie
		$self->_assure_cookie unless $self->{args}->{nocookie}; # will redirect and exit.
		 # just to make a point
	}

	# make sure all of the params we want *are* there

	for ( keys %{$preset} ){
		unless ( $self->param($_) ){
			$self->param($_ => $preset->{$_});		
		}
	}

	### saving params from cgi
	
	$self->save_param($self->query, [keys %{$preset}] ); # save these params if they any of them came in

	### loading params from session in to cgi

	$self->load_param($self->query, [keys %{$preset}] ); # load all these query params from session storage  to cgi object

	return $self->query;
}

sub session_to_tmpl {
	my $self= shift;
	my $tmpl = shift; $tmpl or croak('is this an HTML::Template object?');

	for ($self->get_presets){
		my $key = $_;
		my $val = $self->param($key);
		$val ||=0;
		$tmpl->param($key => $val);	
	}	
	return $tmpl;
}

sub query_to_tmpl {
	my $self = shift;
	my $tmpl = shift; $tmpl or croak('is this an HTML::Template object?');

	for ($self->query->param){
		my $key = $_;
		my $val = $self->query->param($key);
		$val ||=0;
		$tmpl->param($key => $val);	
	}
	
	return $tmpl;
}

sub get_presets {
	my $self = shift;
	(ref $self->{preset}) eq 'HASH' or croak('arg must be hash ref');
	my @p = sort keys %{$self->{preset}};	
	return \@p;
}

sub _assure_cookie {
	my $self = shift;
	$self->is_new or return 1;
	
	my $redirect = shift;
	$redirect ||= $ENV{SCRIPT_NAME}; $redirect or croak('CGI::Session::Submitted::_assure_coooie() error: missing $ENV{SCRIPT_NAME} - where to redirect to?');	
	
	print $self->query->redirect(
					-uri			=> $redirect, 
					-cookie		=> 
						$self->query->cookie(
							-name		=> $self->name, 
							-value	=> $self->id,
					)
	);				
	exit(0);
}


1;
__END__

=pod

=head1 NAME

CGI::Session::Submitted - Automatic session and persistence of query data.

=head1 SYNOPSIS

	use CGI::Session::Submitted;	
	
	my $s = new CGI::Session::Submitted;
	$s->run( { theme=> 'light', help_on=> 1 } ); 
	
=head1 DESCRIPTION

This module is a wrap around CGI::Session. It offers a standard way in which you 
may want to use a session object in regards to incoming query data.

This is how one may normally use a session object:

=over 4

=item * 

First, you would want to create a new session if one is not loaded.

=item *

Then you want to make sure that the client can keep track of the session.

=item *

Thirdly you may have certain query data that the user client may submit that you 
want them to be able to change at any time.

=item *

Last, you want those specific parameters you specified to be readily available to
your code via a cgi object.

=back

This module keeps track of all those things for you.

	my $s = new CGI::Session::Submitted;

	my $cgi = $s->run({ theme=> 'light', help_on => 1 }); 

	$cgi->param('theme'); 	# returns 'light'
	$s->param('theme');		# also returns 'light'
	
In this example, param 'theme' will return light always - unless the user has at any point submitted a different 
value for it via GET or POST.


Any data you want the client to be able to change at any moment, you should place as an argument to
run(), with default values.
Imagine you are taking address information, you may want to do this:

	my $s = new CGI::Session::Submitted;

	my $cgi = $s->run({ 
		address_name => undef,
		address_line_1 => undef,
		address_line_2 => undef,
		address_city => undef,
		address_state => undef,
		address_zip => undef,
		address_country => US,
	}); 

If at any moment POST or GET contain these params (form fields), then they are automatically saved 
to the session object. Your presets will not override a user submission.
Also, these objects are readily available parms in the $cgi object returned.
You do not *have* to use the cgi query object returned via the session object. You may choose to 
simply query the session object for this.

This module inherits CGI::Session and all its methods.

=head1 PUBLIC METHODS

Don't forget this module inherits CGI::Session and all its wonderful and useful methods. 

=head2 run()

Argument is a hash ref. Each key is a param name you want to keep track of. The values are the defaults to set.
Returns cgi object with params loaded into it.

If session is new: sets presets, makes cookie, redirects and exits
This is so you do not have to track the session id. 

All params in the query object (cgi) that match the arguments, are automatically saved to the session.

All the params we declared will be automatically loaded into the query object (cgi object, if you will).

Returns cgi query object with params from session loaded into itself.

=head2 session_to_tmpl()

If you have an existing HTML::Template object and you want to load it with all the params in session object.
	
	$s->session_to_tmpl($tmpl);

If the value is undef, sets to 0.

Returns HTML::Template object you provided as argument.

=head2 query_to_tmpl()

If you have an existing HTML::Template object and you want to load it with all the params in the cgi query object.
If value is undef, sets to 0.

	$s->query_to_tmpl($tmpl)

Returns HTML::Template object you provided as argument.

=head2 get_presets()

Returns array ref of presets you defined via run().
This is just a list with the names of the params you predefined via run().

=head1 INTERNAL METHODS

=head2 _assure_cookie()

If the session is new (the client did not already have one) then this prints a header with
a cookie and redirects to itself ( environment variable SCRIPT_NAME ).

=head1 BUGS

Please inform developer of any bugs or issues concerning this module. If there's a feature
you would like to see added, please suggest. I will go the distance.

=head1 TODO

Should allow specifying a different cookie, a timeout for it, etc.
Present cookie does not have an expiry specified. The idea is if these are user options, then 
Why do you want to get rid of them? I can see a lot of reasons why. But for now this should do.

=head1 COPYRIGHT

Copyright (C) Leo Charre E<lt>leo@leocharre.comE<gt>. All rights reserved.
This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=head1 AUTHOR

Leo Charre E<lt>leo@leocharre.comE<gt>, http://leocharre.com

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session|CGI::Session> - What this module inherits

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - Tutorial on how to use sessions, very helpful

=item * 

L<CGI|CGI> - the CGI library

=back

=cut
