package App::TimeTracker::Command::TellRemote;
use strict;
use warnings;
use 5.010;

our $VERSION = "3.000";
# ABSTRACT: App::TimeTracker plugin for telling generic remotes

use Moose::Role;
use LWP::UserAgent;
use Digest::SHA qw(sha1_hex);
use URI::Escape;
use App::TimeTracker::Utils qw(error_message);
use Encode;

has 'tell_remote' => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 1,
    documentation => 'TellRemote: tell generic remote',
    traits        => ['Getopt'],
);

after [ 'cmd_start', 'cmd_continue' ] => sub {
    my $self = shift;
    return if $self->irc_quiet;
    my $task = $self->_current_task;
    $self->_tell_remote( start => $task );
};

after 'cmd_stop' => sub {
    my $self = shift;
    return if $self->irc_quiet;
    return unless $self->_current_command eq 'cmd_stop';
    my $task = App::TimeTracker::Data::Task->previous( $self->home );
    $self->_tell_remote( stop => $task );
};

sub _tell_remote {
    my ( $self, $status, $task ) = @_;
    my $cfg = $self->config->{tell_remote};
    return unless $cfg;

    my $ua = LWP::UserAgent->new( timeout => 3 );
    my $message
        = $task->user
        . ( $status eq 'start' ? ' is now' : ' stopped' )
        . ' working on '
        . $task->say_project_tags;
    # Use bytes for creating the digest, otherwise we'll get into trouble
    # https://rt.cpan.org/Public/Bug/Display.html?id=93139
    my $token = sha1_hex( encode_utf8($message), $cfg->{secret} );

    my $url
        = $cfg->{host}
        . '?message='
        . uri_escape_utf8($message)
        . '&token='
        . $token;
    my $res = $ua->get($url);
    unless ( $res->is_success ) {
        error_message( 'Could not post to remote status via %s: %s',
            $url, $res->status_line );
    }
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::TellRemote - App::TimeTracker plugin for telling generic remotes

=head1 VERSION

version 3.000

=head1 DESCRIPTION

We use an internal IRC channel for internal communication. And we all want (need) to know what other team members are currently doing. This plugin helps us making sharing this information easy.

After running some commands, this plugin prepares a short message and
sends it (together with an authentification token) to a small
webserver-cum-irc-bot (C<Bot::FromHTTP>, not yet on CPAN, but basically
just a slightly customized/enhanced pastebin).

The messages is transfered as a GET-Request like this:

  http://yourserver/?message=some message&token=a58875d576e8c09a...

=head1 CONFIGURATION

=head2 plugins

add C<TellRemote> to your list of plugins

=head2 tell_remote

add a hash named C<tell_remote>, containing the following keys:

=head3 host

The hostname of the server C<Bot::FromHTTP> is running on. Might also contain a special port number (C<http://ircbox.vpn.yourcompany.com:9090>)

=head3 secret

A shared secret used to calculate the authentification token. The token is calculated like this:

  my $token = Digest::SHA::sha1_hex($message, $secret);

=head1 NEW COMMANDS

none

=head1 CHANGES TO OTHER COMMANDS

=head2 start, stop, continue

After running the respective command, a message is sent to the
remote that could for example post the message to IRC.

=head3 New Options

=head4 --tell_remote

Defaults to true, but you can use:

    ~/perl/Your-Secret-Project$ tracker start --no_tell_remote

to B<not> send a message

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2019 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
