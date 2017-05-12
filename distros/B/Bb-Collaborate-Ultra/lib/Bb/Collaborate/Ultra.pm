package Bb::Collaborate::Ultra;

=head1 NAME

Bb::Collaborate::Ultra - Perl bindings for Blackboard Ultra virtual classrooms

=head1 VERSION

Version 0.01.02

=cut

use strict;
our $VERSION = '0.01.02';

use 5.008003;

=head1 SYNOPSIS

    use Bb::Collaborate::Ultra::Connection;
    use Bb::Collaborate::Ultra::Session;
    use Bb::Collaborate::Ultra::User;
    use Bb::Collaborate::Ultra::LaunchContext;

	my %credentials = (
	  issuer => 'OUUK-REST-API12340ABCD',
	  secret => 'ABCDEF0123456789AA',
	  host => 'https://xx-csa.bbcollab.com',
	);

	# connect to server
	my $connection = Bb::Collaborate::Ultra::Connection->new(\%credentials);
	$connection->connect;

	# create a virtual classroom, starts now runs, for 15 minutes
	my $start = time() + 60;
	my $end = $start + 900;
	my $session = Bb::Collaborate::Ultra::Session->post($connection, {
		name => 'Test Session',
		startTime => $start,
		endTime   => $end,
		},
	    );

	# define a session user
	my $user = Bb::Collaborate::Ultra::User->new({
	    extId => 'dwarring',
	    displayName => 'David Warring',
	    email => 'david.warring@gmail.com',
	    firstName => 'David',
	    lastName => 'Warring',
	});

	# register the user. obtain a join URL
	my $launch_context =  Bb::Collaborate::Ultra::LaunchContext->new({
	      launchingRole => 'moderator',
	      editingPermission => 'writer',
	      user => $user,
	     });
	 my $url = $launch_context->join_session($session);

=head1 BACKGROUND

Blackboard Collaborate Ultra is software for virtual web classrooms. It is
suitable for meetings, demonstrations web conferences, seminars, general
training and support.

Bb-Ultra is a set of Perl bindings and entity definitions for the
Collaborate REST services. These can be used to administer classrooms,
including sessions, users and recordings.

=head1 DESCRIPTION

This Perl 5 module provides bindings to the the Collaborate (*) Services RESTful API. These support the CRUD and processing operations for the scheduling and access to HTML sessions.

These services are described in L<https://xx-csa.bbcollab.com/documentation>.

=head2 Resource Classes


Each resource class is represented by a Perl 5 class:

=over 4

=item Context - L<Bb::Collaborate::Ultra::Context> (see L<Context Documentation|https://xx-csa.bbcollab.com/documentation#Context>)

=item Session - L<Bb::Collaborate::Ultra::Session> (see L<Session Documentation|https://xx-csa.bbcollab.com/documentation#Session>)

=item Recording - L<Bb::Collaborate::Ultra::Recording> (see L<Recording Documentation|https://xx-csa.bbcollab.com/documentation#Recording>)

=item Session Logs - L<Bb::Collaborate::Ultra::Session::Log> (see L<Session Documentation|https://xx-csa.bbcollab.com/documentation#Attendee-collection>)

=back

=head2 RESTful Services

The above classes are based on Bb::Collaborate::Ultra::DAO, which  provides low level `post`, `get`, `patch` and `delete` methods. Where:

=over 4

=item `post` creates new entities on the server

=item `get` is used to fetched entities, by `id` or various other criteria

=item `patch` is used to update entities

=item `delete` is used to delete items

=back

=head2 Data Mapping

Some conversion is needed between JSON and Perl:

=over 4

=item - Boolean `true` and `false` are converted to 0 and 1

=item - JSON date strings are converted to Unix numeric timestamps, rounded to the nearest second. For example, `2016-12-15T22:26:17.000Z` is converted to 1481840777.

=back

These conversions are applied on data being sent or received from the Collaborate Ultra server.

=head2 Authentication

Authentication is via the OAuth 2.0 protocol, using the JWT Token Flow, as described in the L<documentation|https://xx-csa.bbcollab.com/documentation>.

See L<Bb::Collaborate::Ultra::Connection> for details.

=head1 SCRIPTS

=head2 bb-collab-session-log

Tjhis is a sample script to dump basic session logging for a
completed session.

=head1 BUGS AND LIMITATIONS

=over 4

=item - This module does not yet fully implement resource types: Users, Enrollments or Courses

=item - JWT Username-Password authentication is not yet supported.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2017 David Warring, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Bb::Collaborate::Ultra
