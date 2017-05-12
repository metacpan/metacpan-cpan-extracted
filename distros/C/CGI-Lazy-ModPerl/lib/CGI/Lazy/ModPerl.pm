package CGI::Lazy::ModPerl;

use strict;
use warnings;

use CGI::Lazy::Globals;
use Apache2::Const;
use Apache2::RequestUtil;

no warnings qw(uninitialized redefine);

our $VERSION = '0.04';

#------------------------------------------------------------------------------
sub _sessionCleanup {
	my $r = shift;
	my $q = shift;

	if ($q->plugin->session) {
		unless ($q->plugin->session->{saveOnDestroy} == 0) {
			$q->session->save if $q->session;
		}
	}

	return Apache2::Const::OK;

}

#------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my $vars = $q->plugin->mod_perl;

	if ($q->plugin->session) {
		#register cleanup handler, so we make damn sure that the session variable is saved
		my $handler = $q->plugin->mod_perl->{PerlHandler};
		my $r = Apache2::RequestUtil->request();
		$r->push_handlers(PerlCleanupHandler	=> \&_sessionCleanup($r, $q));
	}

	return bless {_q => $q, _vars => $vars}, $class;
}

#------------------------------------------------------------------------------
sub vars {
	my $self = shift;

	return $self->{_vars};
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

CGI::Lazy::ModPerl

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

=head1 DESCRIPTION

Module for handling the wierdness that entails when you move from normal cgi scripting into the wonderful world of mod_perl.

The mod_perl object needs to know which response handler is being used.  This is a manditory argument.

Sessions are saved in a cleanup handler by default, as well as when the Lazy object is destroyed.  (call me paranoid)  If you wish to disable the mod_perl handler save, set saveOnCleanup => 0.  If it's not set, it's the same as if it was set to 1.

=head1 METHODS

=head2 _sessionCleanup

Mod_perl cleanup handler for saving session data.  Called automatically if using both mod_perl and session plugins.

=head2 new ( q )

Constructor.

=head3 q

CGI::Lazy object

=head2 vars ()

Returns mod_perl object settings from config.

=cut

