package BusyBird::Input::Feed::Run;
use strict;
use warnings;
use BusyBird::Input::Feed;
use LWP::UserAgent;
use JSON;
use Carp;

sub run {
    my ($class, %opts) = @_;
    my $download_url = $opts{download_url};
    my $post_url = $opts{post_url};
    my $user_agent = $opts{user_agent};
    my $level = $opts{level};
    my $input = BusyBird::Input::Feed->new(
        defined($user_agent) ? (user_agent => $user_agent) : ()
    );
    my $json = JSON->new->utf8->ascii;
    my $statuses = _parse_feed($input, $download_url);
    if(defined($level)) {
        foreach my $s (@$statuses) {
            $s->{busybird}{level} = $level;
        }
    }
    my $statuses_json = $json->encode($statuses) . "\n";
    _post_statuses(\$statuses_json, $post_url, $user_agent);
}

sub _parse_feed {
    my ($input, $download_url) = @_;
    if(defined($download_url)) {
        return $input->parse_url($download_url);
    }
    my $feed_data = do { local $/; <STDIN> };
    return $input->parse_string($feed_data);
}

sub _post_statuses {
    my ($statuses_json_ref, $post_url, $given_user_agent) = @_;
    if(!defined($post_url)) {
        print $$statuses_json_ref;
        return;
    }
    my $ua = $given_user_agent || do {
        my $ua = LWP::UserAgent->new;
        $ua->env_proxy;
        $ua;
    };
    my $res = $ua->post(
        $post_url,
        'Content-Type' => 'application/json; charset=utf-8',
        Content => $$statuses_json_ref,
    );
    if(!$res->is_success) {
        croak "Error posting statuses to $post_url: " . $res->status_line;
    }
}

1;
