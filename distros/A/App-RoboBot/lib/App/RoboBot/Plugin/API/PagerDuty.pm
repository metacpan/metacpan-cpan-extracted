package App::RoboBot::Plugin::API::PagerDuty;
$App::RoboBot::Plugin::API::PagerDuty::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use AnyEvent;
use Data::Dumper;
use DateTime;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use LWP::Protocol::https;
use URI;

use App::RoboBot::Channel;
use App::RoboBot::Response;

extends 'App::RoboBot::Plugin';

=head1 api.pagerduty

Exports functions for interacting with PagerDuty API, and subscribing to alarm
notices.

API Keys for Pagerduty are currently part of the on-disk configuration file for
the bot, and as such there are no functions for adding/removing/changing oncall
groups or adding new Pagerduty accounts without restarting the bot. This will
likely change in a future release to make things easier for users to manage.

=cut

has '+name' => (
    default => 'API::PagerDuty',
);

has '+description' => (
    default => 'Exports functions for interacting with PagerDuty API, and subscribing to alarm notices.',
);

=head2 pagerduty-groups

=head3 Description

Displays the list of PagerDuty contact groups which currently have API keys
configured.

=head2 pagerduty-oncall

=head3 Description

Displays on-call information for the named group, based on the current schedule
in PagerDuty. All remaining arguments after the group name, if provided, will
be echoed back.

Calls to the on-call scheduling API at Pagerduty are cached briefly (for a few
minutes per oncall group) to prevent flooding their servers should anyone in
the channel call this function repeatedly.

=head3 Usage

<group> [<message>]

=head3 Examples

    :emphasize-lines: 2-5

    (pagerduty-oncall netops "I can't get a route from bastion to staging, help!")
    PagerDuty On-Call for Network Operations:
    Primary: Bobby Jo <bobby@nowhere.tld>
    Secondary: Janey Sue <janey@nowhere.tld>
    <Beauford> I can't get a route from bastion to staging, help!

=cut

has '+commands' => (
    default => sub {{
        'pagerduty-groups' => { method      => 'list_groups',
                                description => 'Displays the list of PagerDuty contact groups which currently have API keys configured.' },

        'pagerduty-oncall' => { method      => 'oncall',
                                description => 'Displays on-call information for the named group, based on the current schedule in PagerDuty. All remaining arguments after the group name, if provided, will be echoed back.',
                                usage       => '<group name> [<message>]', },
    }},
);

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new() },
);

has 'cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { oncall => {} } },
);

sub init {
    my ($self, $bot) = @_;
}

sub list_groups {
    my ($self, $message, $command, $rpl) = @_;

    return unless $self->_validate_config($message);

    $message->response->push('The following PagerDuty groups are currently present in the configuration:');

    $message->response->push(
        sprintf('*%s*: %s',
            $_,
            ($self->bot->config->plugins->{'pagerduty'}{'group'}{$_}{'desc'} // 'no description'),
        ))
        for sort { lc($a) cmp lc($b) } keys %{$self->bot->config->plugins->{'pagerduty'}{'group'}};

    return;
}

sub oncall {
    my ($self, $message, $command, $rpl, $group, @extras) = @_;

    return unless $self->_validate_group_config($message, $group);

    my $now = $self->now;

    $group = $self->bot->config->plugins->{'pagerduty'}{'group'}{lc($group)};

    $message->response->push(sprintf('PagerDuty On-Call for _%s_:', $group->{'desc'}));

    foreach my $schedule (sort { $a->{'order'} <=> $b->{'order'} } @{$self->coerce_schedules($group->{'schedule'})}) {
        my $data;

        if (exists $self->cache->{'oncall'}{$group->{'name'}}{$schedule->{'id'}}
            && $self->cache->{'oncall'}{$group->{'name'}}{$schedule->{'id'}}{'expires'} > time())
        {
            $data = $self->cache->{'oncall'}{$group->{'name'}}{$schedule->{'id'}}{'data'};
        } else {
            $data = $self->make_pd_api_call($group, [qw( api v1 schedules ), $schedule->{'id'}, qw( entries )], { since => $now, until => $now });

            unless (defined $data) {
                $message->response->raise('An error was encountered contacting the PagerDuty API. Please try again.');
                return;
            }

            $self->cache->{'oncall'}{$group->{'name'}}{$schedule->{'id'}} = {
                data    => $data,
                expires => time() + 60,
            };
        }

        next unless exists $data->{'entries'} && ref($data->{'entries'}) eq 'ARRAY' && scalar(@{$data->{'entries'}}) > 0;
        my $entry = $data->{'entries'}[0];

        $message->response->push(sprintf('*%s*: %s <%s>',
            $schedule->{'name'},
            ($entry->{'user'}{'name'} // '_Nobody_'),
            ($entry->{'user'}{'email'} // '...'),
        ));
    }

    # TODO: Ugly hack for now to suppress defaulted string of "message" in the
    #       various !oncall<X> macros we use in Slack. Should be fixed long-term
    #       by revamping the macro variables code.
    if (@extras && @extras > 0 && lc($extras[0]) ne 'message') {
        $message->response->push(sprintf('<%s> %s', $message->sender->name, join(' ', @extras)));
    }

    return;
}

sub make_pd_api_call {
    my ($self, $group, $path, $args) = @_;

    my $uri = URI->new;
    $uri->scheme('https');
    $uri->host($group->{'domain'} . '.pagerduty.com');

    if (ref($path) eq 'ARRAY') {
        $uri->path_segments(@{$path});
    } else {
        $uri->path($path);
    }

    if (defined $args && ref($args) eq 'HASH' && scalar(keys(%{$args})) > 0) {
        $uri->query_form($args);
    }

    my $req = HTTP::Request->new( GET => $uri->as_string );
    $req->header( 'Content-type'  => 'application/json' );
    $req->header( 'Authorization' => sprintf('Token token=%s', $group->{'api_key'}) );

    my $response = $self->ua->request($req);

    return unless $response->is_success;

    my $json;
    eval {
        $json = decode_json($response->decoded_content);
    };
    return if $@;
    return $json;
}

sub now {
    my ($self) = @_;

    return DateTime->now->iso8601 . 'Z';
}

sub _validate_config {
    my ($self, $message) = @_;

    unless (exists $self->bot->config->plugins->{'pagerduty'}
            && exists $self->bot->config->plugins->{'pagerduty'}{'group'}
            && ref($self->bot->config->plugins->{'pagerduty'}{'group'}) eq 'HASH')
    {
        $message->response->raise('PagerDuty groups not properly configured. Please contact bot administrator.');
        return 0;
    }

    return 1;
}

sub _validate_group_config {
    my ($self, $message, $group) = @_;

    return 0 unless $self->_validate_config($message);

    my $lgroup = lc($group);

    unless (exists $self->bot->config->plugins->{'pagerduty'}{'group'}{$lgroup}
            && exists $self->bot->config->plugins->{'pagerduty'}{'group'}{$lgroup}{'api_key'}
            && exists $self->bot->config->plugins->{'pagerduty'}{'group'}{$lgroup}{'domain'})
    {
        $message->response->raise('The PagerDuty group %s is not properly configured. Please contact bot administrator.', $group);
        return 0;
    }

    return 1;
}

sub coerce_schedules {
    my ($self, $schedule) = @_;

    # If a group only has a single schedule defined, the config is going to
    # return it as a simple hashref with that schedule's data, but for simplicity
    # we want all the other functions to be able to assume it will be an arrayref
    # containing 0+ schedules.
    return $schedule if ref($schedule) eq 'ARRAY';
    return [$schedule] if ref($schedule) eq 'HASH';
    return [];
}

__PACKAGE__->meta->make_immutable;

1;
