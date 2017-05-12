package Dancer::Plugin::WindowSession;

use strict;
use warnings;
use Clone;
use Carp;

our $VERSION = '0.02';

use Dancer ':syntax';
use Dancer::Plugin;

sub _get_window_session_object
{
	my $win_sess_id ; ## The window session ID, from the HTTP request.
	my $win_sess_obj ; ## The Dancer::Session::Abstract object

	## Is there a cached version of the window-session object ?
	if (defined(var 'window_session_object')) {
		$win_sess_obj = var 'window_session_object';
		$win_sess_id = $win_sess_obj->id;
		return $win_sess_obj;
	}


	# This is the first time 'window_session' is request during this request handling,
	# check if we have one in the HTTP Request
	$win_sess_id = param 'winsid';

	my $session_engine = engine 'session'
		or die "Can't find session engine";

	# If we have a Window-session-Id, try to retrieve the corresponding hash.
	if ($win_sess_id) {
		$win_sess_obj = $session_engine->retrieve($win_sess_id);

		## If we failed to retrieve existing window-session, force a new one
		$win_sess_id = undef unless $win_sess_obj;
	}

	# If anything failed along the way, just create a new window session
	if (!$win_sess_id) {
		$win_sess_obj = $session_engine->create();
		$win_sess_id = $win_sess_obj->id;

	}
	## Cache the new window-session object,
	## for other route handlers downstream in the current request handling.
	var 'window_session_object' => $win_sess_obj;

	return $win_sess_obj;
}

hook before => sub {
	my $window_session = _get_window_session_object;
	my $window_session_id = $window_session->id;
};

hook before_template_render => sub {
	my $tokens = shift ;

	my $window_session = _get_window_session_object;

	$tokens->{winsid} = $window_session->id;
	$tokens->{window_session} = Clone::clone($window_session);
};

hook after => sub {
	my $window_session = _get_window_session_object;
	my $window_session_id = $window_session->id;
	$window_session->flush();
};

register window_session_id => sub {
	my $window_session = _get_window_session_object;
	return $window_session->id;
};


register window_session => sub {
	my $window_session = _get_window_session_object;
	my $window_session_id = $window_session->id;

	my ($key,$value) = @_;
	$key eq 'id' and croak 'Can\'t store to window_session key with name "id"';

	$window_session->{$key} = $value if (@_==2);
	return $window_session->{$key};
};

register_plugin;

# ABSTRACT: A Dancer plugin for managing Browser Window Sessions

1;
__END__
=pod

=head1 NAME

Dancer::Plugin::WindowSession - Manage Per-Browser-Window sessions.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

	use Dancer;
	use Dancer::Plugin::WindowSession;

	get '/' => sub {
		## Read Session-wide variable
		## (applies to all open browser windows)
		my $username = session 'username';

		## Read Window-Session variable
		## (will be different for every open browser window)
		my $color = window_session 'color';

		## [ return something to the user ]
	};


	## Assume the user submitted a POST <form>
	## with new data, save some variables to the standard session,
	## and others to the per-window session.
	post 'change_settings' => sub {
		my $username = param 'username';
		my $color = param 'color';

		session 'username' => $username ;
		window_session 'color' => $color ;

		## [ return something to the user ]
	};

	dance;

	######################
	### VERY IMPORTANT ###
	######################
	In all the template files, you must pass-on the 'winsid' CGI variable,
	either as part of a URL or as part of a POST <form> varaible.

	Using Template::Toolkit templtates:

	<a href="some_other_page?winsid=[% winsid | uri %]">Go to some other page</a>

	OR

	<form method="post">
		<input type="hidden" name="winsid" value="[% winsid|uri %]">
	</form>

=head1 FUNCTIONS

C<window_session> - Read/Write access to the per-window-session variables. Behaves exactly like L<Dancer>'s C<session> keyword.

C<window_session_id> - Returns the per-window-session ID number (if you need to embed it in a URL string).

=head1 DESCRIPTION

This module makes it easy to manage per-window session variables (as opposed to browser-wide session variables).

The common use case is when you expect users of your website to have multiple web-browser windows open with your web-site, and for each open window you want to maintain independant set of variables.


=head1 IMPLEMENTATION

To use this plugin effectively, be sure to include the C<winsid> value in B<all> URLs and POST forms you have in your templates.

This plugin uses the same session engine configured for your Dancer application (see L<Dancer::Session>).

=head1 CONFIGURATION

No configuration options are available, at the moment.

Future version might allow changing the name of the CGI varaible (C<winsid>) to something else.

=head1 AUTHOR

Assaf Gordon, C<< <gordon at cshl.edu> >>

=head1 BUGS

Possibly many.

B<NOTE>: If a user copies a URL (containing the C<winsid> value) and pastes it in a new browser window (or sends it to another user) - then both windows will share the same sessions. This can be viewed as a bug (The per-window mechanism does not really guarentee to be a single-window session) or a feature (users can easily share their session state with other users).

Please report any bugs or feature requests to
L<https://github.com/agordon/Dancer-Plugin-WindowSession/issues>

=head1 SEE ALSO

L<Dancer>, L<Dancer::Plugin>

=head1 Example

See working example at: L<http://winsid.cancan.cshl.edu> .

See the C<eg/> directory for a complete source of the example. Run: C<perl -I./lib/ eg/example/bin/app.pl> then visit L<http://localhost:3000> .

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::WindowSession

=head1 ACKNOWLEDGEMENTS

The implementation was influenced by the UCSC Genome Browser website, which uses the C<hgsid> CGI variable in the same manner.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Assaf Gordon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
