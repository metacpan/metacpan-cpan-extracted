package App::TimeTracker::Command::TellSlack;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker plugin for posting to slack.com

our $VERSION = '1.001';

use Moose::Role;
use LWP::UserAgent;
use Digest::SHA qw(sha1_hex);
use URI::Escape;
use App::TimeTracker::Utils qw(error_message);
use Encode;
use JSON::XS qw(encode_json);

has 'tell_slack' => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 1,
    documentation => 'Post to slack',
    traits        => ['Getopt'],
);

after [ 'cmd_start', 'cmd_continue' ] => sub {
    my $self = shift;
    return unless $self->tell_slack;
    my $task = $self->_current_task;
    $self->_post_to_slack( start => $task );
};

after 'cmd_stop' => sub {
    my ($self, $dont_exit) = @_;
    return unless $self->tell_slack;
    return unless $self->_current_command eq 'cmd_stop';
    my $cfg = $self->config->{tell_slack} || {};
    return if $dont_exit && $cfg->{ignore_stop_when_starting};

    my $task = App::TimeTracker::Data::Task->previous( $self->home );
    $self->_post_to_slack( stop => $task );
};

sub _post_to_slack {
    my ( $self, $status, $task ) = @_;
    my $cfg = $self->config->{tell_slack};
    return unless $cfg;

    unless ($cfg->{url}) {
        error_message( 'tell_slack.url not defined in config, cannot post to slack' );
        return;
    }

    my $ua = LWP::UserAgent->new( timeout => 3 );
    my $message
        = $task->user
        . ( $status eq 'start' ? ' is now' : ' stopped' )
        . ' working on '
        . $task->say_project_tags;
    my $request = HTTP::Request->new(POST=>$cfg->{url});

    my $payload = {
        text=>$message
    };
    $payload->{username} = $cfg->{username} if $cfg->{username};

    $request->content(decode_utf8(encode_json($payload)));
    my $res = $ua->request($request);
    unless ( $res->is_success ) {
        error_message( 'Could not post to slack: %s',
            $res->status_line );
    }
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::TellSlack - App::TimeTracker plugin for posting to slack.com

=head1 VERSION

version 1.001

=head1 DESCRIPTION

Tell your team members what you're doing via a slack.com channel.

=head1 CONFIGURATION

=head2 plugins

add C<TellSlack> to your list of plugins

=head2 tell_slack

add a hash named C<tell_slack>, containing the following keys:

=head3 url

Required.

The C<Webhook URL> for your L<Incoming WebHook|https://api.slack.com/incoming-webhooks>.

=head3 username

Optional.

The username that should be used when posting the message.

=head3 ignore_stop_when_starting

Optional.

If set to a true value, do not post the previous task (which has just
been stopped) when starting a new task.

=head1 NEW COMMANDS

none

=head1 CHANGES TO OTHER COMMANDS

=head2 start, stop, continue

After running the respective commands, a message is sent to slack

=head3 New Options

=head4 --tell_slack

Defaults to true, but you can disable it like this:

    ~/perl/Secret-Project$ tracker start --notell_slack --tag watching_cat_videos

to not post this action to slack.

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
