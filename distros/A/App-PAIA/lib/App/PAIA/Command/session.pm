package App::PAIA::Command::session;
use strict;
use v5.10;
use parent 'App::PAIA::Command';

our $VERSION = '0.30';

use App::PAIA::JSON;

sub _execute {
    my ($self, $opt, $args) = @_;

    if (defined $self->session->file ) {
        my $data = $self->session->load;
        say encode_json($data) if $self->app->global_options->verbose;
        my $msg = $self->not_authentificated;
        die "$msg.\n" if $msg;
        say "session looks fine.";
    } else {
        die "no session file found.\n";
    }

    if (!$self->auth) {
        die "PAIA auth server URL not found\n";
    } else {
        $self->logger->('auth URL: '.$self->auth);
    }

    if (!$self->core) {
        die "PAIA core server URL not found\n";
    } else {
        $self->logger->('core URL: '.$self->core);
    }

    return;
}

1;
__END__

=head1 NAME

App::PAIA::Command::session - show current session status

=head1 DESCRIPTION

This command shows the current PAIA auth session.  The exit code indicates
whether a session file was found with not-expired access token and PAIA server
URLs. Option --verbose|-v enables details.

=cut
