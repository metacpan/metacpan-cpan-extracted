package CGI::Lazy::Session::Data;

use strict;

use CGI::Lazy::Globals;

#----------------------------------------------------------------------------------------------	
sub AUTOLOAD {
	my $self = shift;

	my $name = our $AUTOLOAD;
	return if $name =~ /::DESTROY$/;
	my @list = split "::", $name;
	my $value = pop @list;
	if (@_) {
		$self->{_data}->{$value} = shift; #this will work equally well for scalars and array refs.  Do we need it to fly for lists?
		$self->session->save unless ($self->q->plugin->session->{autowrite} && ($self->q->plugin->session->{autowrite} == 0));
	} else {
		if (ref $self->{_data}->{$value} eq 'HASH') {
		       	return wantarray ? %{$self->{_data}->{$value}} : $self->{_data}->{$value};
		} elsif (ref $self->{_data}->{$value} eq 'ARRAY') {
		       	return wantarray ? @{$self->{_data}->{$value}} : $self->{_data}->{$value};
		} else {
			return $self->{_data}->{$value};
		}
	}
}

#--------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->session->q;
}

#--------------------------------------------------------------------------------------
sub session { 
	my $self = shift;

	return $self->{_session};
}

#--------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $session = shift;

	my $self = {_session => $session, _data => $session->getData}; 

	return bless $self, $class;


}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Session::Data

=head1 SYNOPSIS

	use CGI::Lazy;

	our $q = CGI::Lazy->new({

					tmplDir 	=> "/templates",

					jsDir		=>  "/js",

					plugins 	=> {

						mod_perl => {

							PerlHandler 	=> "ModPerl::Registry",

							saveOnCleanup	=> 1,

						},

						ajax	=>  1,

						dbh 	=> {

							dbDatasource 	=> "dbi:mysql:somedatabase:localhost",

							dbUser 		=> "dbuser",

							dbPasswd 	=> "letmein",

							dbArgs 		=> {"RaiseError" => 1},

						},

						session	=> {

							sessionTable	=> 'SessionData',

							sessionCookie	=> 'frobnostication',

							saveOnDestroy	=> 1,

							expires		=> '+15m',

						},

					},

				});

	$q->session->data->name($q->session->sessionID);

	$q->session->data->banner($message);

	print $q->header,

	      $q->session->data->name;

=head1 DESCRIPTION

CGI::Lazy::Session::Data is simply a data container for CGI::Lazy::Session.  Its a separate object just so we can cleanly use an autoloader without running into namespace problems with the Session object.  This way, you have the widest possible range of names to use for session data.

=cut

