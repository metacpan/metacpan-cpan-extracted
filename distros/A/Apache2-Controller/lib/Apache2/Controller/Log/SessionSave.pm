package Apache2::Controller::Log::SessionSave;

=head1 NAME

Apache2::Controller::Log::SessionSave - Log phase handler to save
session data from L<Apache2::Controller::Session> hook.

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

Don't do anything with this handler.  It's set by
L<Apache2::Controller::Session> to save your session.

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller::NonResponseBase 
    Apache2::Controller::Methods 
);

use YAML::Syck;
use Log::Log4perl qw(:easy);

use Apache2::Const -compile => qw( OK HTTP_MULTIPLE_CHOICES );
use Apache2::RequestUtil ();
use Apache2::Controller::X;
use Apache2::Controller::Const qw( $DEFAULT_SESSION_SECRET );

=head2 process

If aborted connection, don't save, and return. 

If status >- 300 and not set C<< $r->pnotes->{a2c}{session_force_save} >>,
don't save, and return.

If session object is not tied, throw an error.  This may not do
anything noticible to the user since the request response is
finished, but you'll see it in the log.

Update the top-level timestamp in the session if the directive
C<A2C_Session_Always_Save> is set.

Untie the session so Apache::Session saves it or not.

=cut

sub process {
    my ($self) = @_;
    my $r = $self->{r};

    DEBUG "A2C session cleanup: start handler sub";

    my $pnotes_a2c = $r->pnotes->{a2c};

    # just return if connection was detected as aborted in Log phase
    # while the connection was still open
    if ($pnotes_a2c->{connection_aborted}) {
        DEBUG "Connection aborted.  NOT saving session.";
        return Apache2::Const::OK;
    }

    # don't save if the status code >= 300 and they have not
    # set the special force-save flag.
    my $http_status = $r->status;
    if ($http_status >= Apache2::Const::HTTP_MULTIPLE_CHOICES) {
        if ($pnotes_a2c->{session_force_save}) {
            DEBUG "status $http_status, but pnotes->{a2c}{session_force_save} is set."
        }
        else {
            DEBUG "status $http_status, not saving session.";
            return Apache2::Const::OK;
        }
    }

    DEBUG "connection not aborted, saving session...";

    # connection finished successfully thru whole cycle, so save session
    my $tied_session = $pnotes_a2c->{_tied_session};
    a2cx 'no tied session in pnotes when saving' if !defined $tied_session;
    a2cx 'pnotes->{a2c}{_tied_session} is not actually tied when saving'
        if !tied %{$tied_session};
    DEBUG "ref of pnotes tied_session is '$tied_session'.";

    my $session_copy = $pnotes_a2c->{session};
    a2cx 'no pnotes->{a2c}{session}' if !defined $session_copy;

    # set the top-level timestamp to force Apache::Session to save
    # if our flag is set in directives.
    $session_copy->{a2c_timestamp} = time
        if $self->get_directive('A2C_Session_Always_Save');

    DEBUG sub{
        "putting copy data back into tied session:\n".Dump($session_copy)
    };
    %{$tied_session} = %{$session_copy}; 

    DEBUG sub {
        my %debug_sess = %{$tied_session};
        "real session is now:\n".Dump(\%debug_sess);
    };

    DEBUG "untying session to save it";
    untie %{$tied_session};
    undef $tied_session;

    DEBUG "Done saving session in PerlLogHandler";
    return Apache2::Const::OK;
};

=head1 SEE ALSO

L<Apache2::Controller::Session>

L<Apache2::Controller>

L<Apache::Session>

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


1;
