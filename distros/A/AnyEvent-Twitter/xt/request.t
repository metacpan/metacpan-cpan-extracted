use strict;
use utf8;
use Test::More;

use JSON;
use Encode;
use AnyEvent::Twitter;

my $config;

if (-f './xt/config.json') {
    open my $fh, '<', './xt/config.json' or die $!;
    $config = decode_json(join '', <$fh>);
    close $fh or die $!;
} else {
    plan skip_all => 'There is no setting file for testing';
}

my $screen_name = $config->{screen_name};

subtest 'v1.0' => sub {
    my $ua = AnyEvent::Twitter->new(
        %$config,
        api_version => '1.0',
    );

    my $cv = AE::cv;

    $cv->begin;
    $ua->request(
        method => 'GET',
        api    => 'account/verify_credentials',
        sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{screen_name}, $screen_name, "account/verify_credentials");
            $cv->end;
        }
    );

    $cv->begin;
    $ua->request(
        method => 'POST',
        api    => 'statuses/update',
        params => { status => '(#`ω´)クポー クポー via api ' . scalar(localtime) . __LINE__ },
        sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{user}{screen_name}, $screen_name, "statuses/update");
            $cv->end;
        }
    );

    $cv->begin;
    $ua->request(
        method => 'POST',
        url    => 'http://api.twitter.com/1/statuses/update.json',
        params => { status => '(#`ω´)クポー クポー via url ' . time . __LINE__ },
        sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{user}{screen_name}, $screen_name, "update.json");
            $cv->end;
        }
    );

    $cv->recv;
};

subtest 'v1.1' => sub {
    my $ua = AnyEvent::Twitter->new(
        %$config,
        api_version => '1.1',
    );

    my $cv = AE::cv;

    $cv->begin;
    $ua->request(
        method => 'GET',
        api    => 'account/verify_credentials',
        sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{screen_name}, $screen_name, "account/verify_credentials")
                or note explain \@_;
            $cv->end;
        }
    );

    $cv->begin;
    $ua->request(
        method => 'POST',
        api    => 'statuses/update',
        params => { status => '(#`ω´)クポー クポー via api ' . scalar(localtime) . __LINE__ },
        sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{user}{screen_name}, $screen_name, "statuses/update")
                or note explain \@_;
            $cv->end;
        }
    );

    $cv->begin;
    $ua->request(
        method => 'POST',
        url    => 'https://api.twitter.com/1.1/statuses/update.json',
        params => { status => '(#`ω´)クポー クポー via url ' . time . __LINE__ },
        sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{user}{screen_name}, $screen_name, "update.json")
                or note explain \@_;
            $cv->end;
        }
    );

    $cv->recv;
};

done_testing();

