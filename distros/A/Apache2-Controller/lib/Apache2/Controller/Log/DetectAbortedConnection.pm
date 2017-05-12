package Apache2::Controller::Log::DetectAbortedConnection;

# fwhew! that was a mouthful.

=head1 NAME

Apache2::Controller::Log::DetectAbortedConnection -
helper handler for detecting cancelled connections to the client.

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 DESCRIPTION

You don't need to use this handler, probably.

This is pushed internally by L<Apache2::Controller::Session>
to detect in the PerlLogHandler phase if the connection has
been broken to the client before the server closes the connection.

So far it's only useful for the session, and because we now
use a C<PerlLogHandler> for session saving instead of the
C<PerlCleanupHandler> in prior versions.  Using a
C<PerlCleanupHandler> caused 
problems with synchronicity since the test scripts would
fire off a new request before Apache was done processing
the session saving from the prior request... I don't know
why it did this under prefork with C<Apache::Test>,
but it did.

So, I'm leaving it separate just in case it is useful for
something else in the future.

=head1 FUNCTIONS

=head2 handler

Sets C<< $r->pnotes->{a2c}{connection_aborted} >> with the
boolean results of C<< $r->connection->aborted() >> and returns.

I am not entirely sure why to cache this except that I couldn't
figure out any other way to manually override this state
even if you didn't abort the connection, if that's useful. 
I may be over-planning here.

=cut

use strict;
use warnings FATAL => 'all';

use Apache2::Connection ();
use Apache2::RequestRec ();
use Apache2::Const -compile => qw( OK );

use Log::Log4perl qw(:easy);

sub handler {
    my ($r) = @_;
    DEBUG "detecting aborted connection...";
    $r->pnotes->{a2c}{connection_aborted} ||= $r->connection->aborted();
    return Apache2::Const::OK;
}

1;

=head1 SEE ALSO

L<Apache2::Controller::Session>, 

L<Apache2::Controller>,

=head1 AUTHOR

Mark Hedges, C<< <hedges at formdata.biz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut

