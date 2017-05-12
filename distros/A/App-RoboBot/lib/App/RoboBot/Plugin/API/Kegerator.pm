package App::RoboBot::Plugin::API::Kegerator;
$App::RoboBot::Plugin::API::Kegerator::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use AnyEvent;
use Data::Dumper;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use URI;

use App::RoboBot::Channel;
use App::RoboBot::Response;

extends 'App::RoboBot::Plugin';

=head1 api.kegerator

Provides functions for monitoring and querying kegerator status. Currently only
supports OmniTI Kegerator API.

=cut

has '+name' => (
    default => 'API::Kegerator',
);

has '+description' => (
    default => 'Provides functions for monitoring and querying kegerator status. Currently only supports OmniTI Kegerator API.',
);

=head2 ontap

=head3 Description

Invoked with no arguments, displays the list of beers currently on tap. When
invoked with a tap number, displays detailed information on the beer available
on that tap.

=head3 Usage

[<tap number>]

=head3 Examples

    :emphasize-lines: 2-5,8

    (ontap)
    Tap 1: Tasmanian IPA (TIPA) (IPA - American) by Schlafly - The Saint Louis Brewery, Saint Louis, MO - 7.2% ABV, 93% remaining
    Tap 2: Resurrection (Brown Ale - Belgian) by The Brewer's Art, Baltimore, MD - 7.0% ABV, 97% remaining
    Tap 3: K-9 Cruiser Winter Ale (Winter Ale) by Flying Dog Brewery, Frederick, MD - 7.4% ABV, 84% remaining
    Tap 4: Crisp Apple (Cider) by Angry Orchard Cider Company, Cincinnati, OH - 5.0% ABV, 69% remaining

    (ontap 3)
    Tap 3: K-9 Cruiser Winter Ale (Winter Ale) by Flying Dog Brewery, Frederick, MD - 7.4% ABV, 84% remaining

=cut

has '+commands' => (
    default => sub {{
        'ontap' => { method      => 'show_ontap',
                     description => 'Displays the list of beers currently on tap.',
                     usage       => '[<tap number>]', },
    }},
);

has 'watcher' => (
    is => 'rw',
);

has 'ua' => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->agent('App::RoboBot');
        $ua->timeout(5);
        return $ua;
    },
);

has 'last_check' => (
    is      => 'rw',
    isa     => 'DateTime',
    default => sub { DateTime->now },
);

has 'beer_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'valid_config' => (
    is      => 'rw',
    isa     => 'Bool',
    traits  => [qw( SetOnce )],
);

sub init {
    my ($self, $bot) = @_;

    # Verify we have all the necessary config keys, so we can make a much
    # simpler ->valid_config check everywhere else.
    if (exists $self->bot->config->plugins->{'kegerator'}{'api_host'}
            && exists $self->bot->config->plugins->{'kegerator'}{'api_path_taps'}
            && exists $self->bot->config->plugins->{'kegerator'}{'api_path_beer'}) {
        $self->valid_config(1);
    } else {
        $self->valid_config(0);

        # No need to initialize anything else related to the watcher, since we
        # don't have the config keys we'll need for that.
        return;
    }

    # Coerce notification targets into an arrayref from the configuration, in
    # case only one was specified (Config::Any will have only treated it as a
    # hashref, instead of an arrayref of hashrefs. Simplifies notification
    # loop later on.
    if (exists $self->bot->config->plugins->{'kegerator'}{'notify'}) {
        $self->bot->config->plugins->{'kegerator'}{'notify'} = [
            $self->bot->config->plugins->{'kegerator'}{'notify'}
        ] if ref($self->bot->config->plugins->{'kegerator'}{'notify'}) eq 'HASH';

        # Only set the watcher if we have at least one channel to notify.
        return unless @{$self->bot->config->plugins->{'kegerator'}{'notify'}} > 0;

        $self->watcher(
            AnyEvent->timer(
                after => 30,
                cb    => sub { $self->_run_watcher($bot) },
            )
        );
    }
}

sub show_ontap {
    my ($self, $message, $command, $rpl, $tap_no) = @_;

    if (defined $tap_no && $tap_no !~ m{^\d+$}o) {
        $message->response->raise('Optional tap number must be an integer if specified.');
        return;
    }

    return unless $self->valid_config;

    my $taps = $self->make_keg_api_call($self->bot->config->plugins->{'kegerator'}{'api_path_taps'});
    return unless defined $taps;

    foreach my $tap (sort { $a->{'tap_id'} <=> $b->{'tap_id'} } @{$taps}) {
        if (defined $tap_no) {
            next unless $tap_no == $tap->{'tap_id'};
        }

        my $beer;

        if (exists $self->beer_cache->{$tap->{'beer_id'}} && $self->beer_cache->{$tap->{'beer_id'}}{'cached_at'} >= (time() - 3600 * 2)) {
            $beer = $self->beer_cache->{$tap->{'beer_id'}};
        } else {
            $beer = $self->make_keg_api_call($self->bot->config->plugins->{'kegerator'}{'api_path_beer'} . '/' . $tap->{'beer_id'});
            next unless defined $beer;

            # Trim down brewery location string for anything brewed in the US.
            $beer->{'brewery_loc'} =~ s{,\s+United\s+States.*}{}igs;

            $self->beer_cache->{$tap->{'beer_id'}} = $beer;
            $self->beer_cache->{$tap->{'beer_id'}}{'cached_at'} = time();
        }

        $message->response->push(
            sprintf('*Tap %d:* %s (%s) by %s, %s - %s ABV%s',
                $tap->{'tap_id'},
                ($beer->{'beer_name'} // 'n/a'),
                ($beer->{'beer_style'} // 'n/a'),
                ($beer->{'brewery_name'} // 'n/a'),
                ($beer->{'brewery_loc'} // 'n/a'),
                ($beer->{'abv'} ? sprintf('%.1f%%', $beer->{'abv'}) : 'n/a'),
                ($tap->{'pct_full'} ? sprintf(', %d%% remaining', $tap->{'pct_full'} * 100) : ''),
            )
        );
    }

    return;
}

sub make_keg_api_call {
    my ($self, $path, $args) = @_;

    return unless $self->bot->config->plugins->{'kegerator'}{'api_host'};

    my $uri = URI->new;
    $uri->scheme($self->bot->config->plugins->{'kegerator'}{'api_scheme'} // 'https');
    $uri->host($self->bot->config->plugins->{'kegerator'}{'api_host'});

    if (ref($path) eq 'ARRAY') {
        $uri->path_segments(@{$path});
    } else {
        $uri->path($path);
    }

    if (defined $args && ref($args) eq 'HASH' && scalar(keys(%{$args})) > 0) {
        $uri->query_form($args);
    }

    my $req = HTTP::Request->new( GET => $uri->as_string );

    my $response = $self->ua->request($req);

    return unless $response->is_success;

    my $json;
    eval {
        $json = decode_json($response->decoded_content);
    };

    return if $@;
    return $json;
}

sub _run_watcher {
    my ($self, $bot) = @_;

    # TODO: Call base API path, get JSON

    # TODO: Loop through keg list, compare each one's last_updated with the
    #       plugin's last_check attribute. Any with a new update should be
    #       added to a list of tap#->beerid

    # TODO: If any tap#'s were marked as new, call the beer detail API endpoint
    #       to get beer name, ABV, IBU, etc.

    # TODO: If any @output to send, construct a mock Response object for each
    #       plugin->notice[server+channel], and send notifications out.

    # TODO: Update plugin's last_check timestamp.

    $self->watcher(
        AnyEvent->timer(
            after => 30,
            cb    => sub { $self->_run_watcher($bot) },
        )
    );
}

__PACKAGE__->meta->make_immutable;

1;
