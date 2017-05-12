package App::RoboBot::Plugin::Net::URLs;
$App::RoboBot::Plugin::Net::URLs::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use HTML::TreeBuilder::LibXML;
use LWP::UserAgent;
use Text::Levenshtein qw( distance );
use URI::Find;

extends 'App::RoboBot::Plugin';

=head1 net.urls

Provides functions related to URLs.

In addition to exported functions, this module inserts a pre-hook into the
message processing pipeline which looks for any URLs in messages others have
sent. Any URLs that are detected are retrieved automatically and an attempt is
made to locate a page title. Redirects are also logged.

If either a page title or any redirects are found, they are displayed back in
the channel.

A timeout on all URL retrievals is set to prevent poorly behaving websites from
delaying subsequent message processing. If the timeout is reached, all further
URL detection and page title lookup is skipped for the current message.

=cut

has '+name' => (
    default => 'Net::URLs',
);

has '+description' => (
    default => 'Provides functions related to URLs.',
);

has '+before_hook' => (
    default => 'check_urls',
);

=head2 shorten-url

=head3 Description

Returns a short version of a URL for easier sharing.

=head3 Usage

<url>

=head3 Examples

    :emphasize-lines: 2

    (shorten-url "http://images.google.com/really-long-image-url.jpg?with=plenty&of=tracking&arguments=foo123")
    "http://tinyurl.com/foObar42"
=cut

has '+commands' => (
    default => sub {{
        'shorten-url' => { method      => 'shorten_url',
                           description => 'Returns a short version of a URL for easier sharing.',
                           usage       => '"<url>"',
                           example     => '"http://images.google.com/really-long-image-url.jpg?with=plenty&of=tracking&arguments=foo123"',
                           result      => 'http://tinyurl.com/foObar42' },
    }},
);

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub {
        LWP::UserAgent->new(
            agent        => "App::RoboBot",
            timeout      => 3,
            max_redirect => 5,
            ssl_opts => {
                verify_hostname => 0,
            },
            protocols_allowed => [qw( http https )],
        );
    },
);

sub check_urls {
    my ($self, $message) = @_;

    return if $message->has_expression;

    # TODO: Replace this with a generic disable-plugins directive at the network
    #       level when that feature is implemented. For now, just return right
    #       away if the message came in on a Slack network.
    return if $message->network->type && $message->network->type eq 'slack';

    my @urls = $self->find_urls($message);

    foreach my $url (@urls) {
        my $r = $self->ua->get($url);

        if ($r->is_success) {
            my $title = $self->get_title($r);

            if (defined $title && length($title) > 0 && $title =~ m{\w+}o) {
                $title =~ s{\s+}{ }ogs;
                $title =~ s{(^\s+|\s+$)}{}ogs;

                $message->response->push(sprintf('Title: %s', $title));
            }

            if (scalar($r->redirects) > 0) {
                my $redir = ($r->redirects)[-1];

                # Limit notification of redirects to only those which differ from the
                # original URL by a distance of greater than 10% of the length of
                # original URL. This prevents some odd issues from reporting a
                # redirect to the same URL.
                if (distance($url, $redir) >= length($url) * 0.10) {
                    $message->response->push(sprintf('Redirected to: %s', $redir->base));
                }
            }
        }

        # TODO add URL logging and the "Last Seen:" output from the old plugin version
    }
}

sub shorten_url {
    my ($self, $message, $command, $rpl, $url) = @_;

    return unless defined $url && length($url) > 0;

    # TODO actually shorten the URLs

    return $url;
}

sub find_urls {
    my ($self, $message) = @_;

    my $text = $message->raw;

    my @uris;
    my $finder = URI::Find->new(sub {
        my($uri) = shift;
        push @uris, $uri;
    });
    $finder->find(\$text);

    return @uris;
}

sub get_title {
    my ($self, $r) = @_;

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($r->decoded_content);
    $tree->eof;

    my @values = $tree->findvalue('//head/title');

    if (@values && scalar(@values) > 0) {
        return $values[0];
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
