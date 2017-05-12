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
        api_version     => '1.0',
        token           => $config->{access_token},
        token_secret    => $config->{access_token_secret},
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
    );

    my $cv = AE::cv;

    $cv->begin;
    $ua->post('statuses/update', { status => 'いろはにほへと ' . time . rand }, sub {
        my ($hdr, $res, $reason) = @_;
        is($res->{user}{screen_name}, $screen_name, "account/verify_credentials")
            or note explain \@_;
        $cv->end;
    });

    $cv->begin;
    $ua->post('http://api.twitter.com/1/statuses/update.json', { status => 'いろはにほへと ' . time . rand }, sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{user}{screen_name}, $screen_name, "account/verify_credentials")
                or note explain \@_;
            $cv->end;
        }
    );

    $cv->recv;
};

subtest 'v1.1' => sub {
    my $ua = AnyEvent::Twitter->new(
        api_version     => '1.1',
        token           => $config->{access_token},
        token_secret    => $config->{access_token_secret},
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
    );

    my $cv = AE::cv;

    $cv->begin;
    $ua->post('statuses/update', { status => 'いろはにほへと ' . time .rand }, sub {
        my ($hdr, $res, $reason) = @_;
        is($res->{user}{screen_name}, $screen_name, "account/verify_credentials")
            or note explain \@_;
        $cv->end;
    });

    $cv->begin;
    $ua->post('http://api.twitter.com/1.1/statuses/update.json', { status => 'いろはにほへと ' . time . rand }, sub {
        my ($hdr, $res, $reason) = @_;
        is($res->{user}{screen_name}, $screen_name, "account/verify_credentials")
            or note explain \@_;
        $cv->end;
    });

    $cv->recv;
};

done_testing();

