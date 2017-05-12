package App::GitHubWebhooks2Ikachan;
use 5.008005;
use strict;
use warnings;
use Encode qw/encode_utf8/;
use Getopt::Long;
use JSON;
use Log::Minimal;
use LWP::UserAgent;
use Plack::Builder;
use Plack::Runner;
use Plack::Request;
use Pod::Usage;
use App::GitHubWebhooks2Ikachan::Events;
use Class::Accessor::Lite(
    new => '0',
    rw  => [qw/ua ikachan_url/],
);

our $VERSION = "0.10";

sub new {
    my ($class, $args) = @_;

    my $ua = LWP::UserAgent->new(
        agent => "App::GitHubWebhooks2Ikachan (Perl)",
    );

    bless {
        ua          => $ua,
        ikachan_url => $args->{ikachan_url},
        debug       => $args->{debug},
    }, $class;
}

sub to_app {
    my ($self) = @_;

    if ($self->{debug}) {
        infof("*** RUNNING IN DEBUG MODE ***");
    }

    infof("App::GitHubWebhooks2Ikachan Version: %.2f", $VERSION);
    infof("ikachan url: %s", $self->ikachan_url);

    builder {
        enable 'AccessLog';

        sub {
            my $env = shift;
            my $req = Plack::Request->new($env);

            return $self->respond_to_ikachan($req);
        };
    };
}

sub respond_to_ikachan {
    my ($self, $req) = @_;

    (my $channel = $req->path_info) =~ s!\A/+!!;
    if (!$channel) {
        return [400, ['Content-Type' => 'text/plain', 'Content-Length' => 20], ['Missing channel name']];
    }

    my $payload = $req->param('payload');
    unless ($payload) {
        return [400, ['Content-Type' => 'text/plain', 'Content-Length' => 18], ['Payload is nothing']];
    }
    my $dat = decode_json($payload);

    if ($self->{debug}) {
        infof("Payload: %s", $payload);
    }

    my $event_name = $req->header('X-GitHub-Event');

    my $event_dispatcher = App::GitHubWebhooks2Ikachan::Events->new(
        dat => $dat,
        req => $req,
    );

    my $send_texts = $event_dispatcher->dispatch($event_name);
    if ($send_texts) {
        if (ref $send_texts ne 'ARRAY') {
            $send_texts = [$send_texts];
        }
        for my $send_text (@$send_texts) {
            $self->send_to_ikachan($channel, $send_text);
        }
    }

    return [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['OK']];
}

sub send_to_ikachan {
    my ($self, $channel, $text) = @_;

    my $res = $self->ua->post($self->ikachan_url, [
        message => $text,
        channel => $channel,
    ]);

    $text = encode_utf8($text);

    $channel =~ s/\A\%23/#/;
    infof("POST %s, %s", $channel, $text);
}

sub parse_options {
    my ($class, @argv) = @_;

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help pass_through)],
    );

    $p->getoptionsfromarray(\@argv, \my %opt, qw/
        ikachan_url=s
        debug
    /) or pod2usage();
    $opt{ikachan_url} || pod2usage();

    return (\%opt, \@argv);
}

sub run {
    my ($self, @argv) = @_;

    my $runner = Plack::Runner->new;
    $runner->parse_options('--port=5555', @argv);
    $runner->run($self->to_app);
}

1;
__END__

=encoding utf-8

=for stopwords webhooks

=head1 NAME

App::GitHubWebhooks2Ikachan - Web server to notify GitHub Webhooks to L<App::Ikachan>

=head1 SYNOPSIS

    $ githubwebhooks2ikachan --ikachan_url=http://your-ikachan-server.com/notice --port=12345

=head1 DESCRIPTION

App::GitHubWebhooks2Ikachan is the server to notify GitHub Webhooks to L<App::Ikachan>.

Now, this application supports C<issues>, C<pull_request>, C<issue_comment>, C<commit_comment>, C<pull_request_review_comment> and C<push> webhooks of GitHub.

=head1 PARAMETERS

Please refer to the L<githubwebhooks2ikachan>.

=head1 USAGE

Please set up webhooks at GitHub (if you want to know details, please refer L<http://developer.github.com/v3/activity/events/types/>).

Payload URL will be like so;

    http://your-githubwebhooks2ikachan-server.com/${path}?subscribe=issues,pull_request&issues=opened,closed&pull_request=opened

This section describes the details.

=over 4

=item PATH INFO

=over 8

=item ${path}

Destination of IRC channel or user to send message. This is essential.
If you want to send C<#foobar> channel, please fill here C<%23foobar>.

=back

=item QUERY PARAMETERS

=over 8

=item subscribe

Event names to subscribe. Specify by comma separated value.
Now, this application supports C<issues>, C<pull_request>, C<issue_comment>, and C<push>.

If you omit this parameter, it will subscribe the all of supported events.

=item issues

Action names to subscribe for C<issues> event. Specify by comma separated value.
Now this application supports C<opened>, C<closed>, and C<reopend>.

If you omit this parameter, it will subscribe the all of supported actions of C<issues>.

=item pull_request

Action names to subscribe for C<pull_request> event. Specify by comma separated value.
Now this application supports C<opened>, C<closed>, C<reopend>, and C<synchronize>.

If you omit this parameter, it will subscribe the all of supported actions of C<pull_request>.

=back

=back

=head1 SEE ALSO

L<githubwebhooks2ikachan>

L<http://developer.github.com/v3/activity/events/types/>.

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

