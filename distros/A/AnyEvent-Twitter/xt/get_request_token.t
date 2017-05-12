use strict;
use utf8;
use Test::More;

use Data::Dumper;
use JSON;
use Encode;
use AnyEvent::Twitter;

plan skip_all => 'This test should not be executed by prove'
    if $ENV{HARNESS_ACTIVE};

my $config;

if (-f './xt/config.json') {
    open my $fh, '<', './xt/config-token-test.json' or die $!;
    $config = decode_json(join '', <$fh>);
    close $fh or die $!;
} else {
    plan skip_all => 'There is no setting file for testing';
}

my $screen_name = $config->{screen_name};

{
    my %token;

    my $cv = AE::cv;
    $cv->begin;
    AnyEvent::Twitter->get_request_token(
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
        callback_url    => 'http://localhost:5000/',
        auth => 'authenticate',
        cb   => sub {
            my ($location, $token, $body, $header) = @_;

            note Dumper \@_;
            like $location, qr/^http/, 'authorize location';

            %token = %$token;
            $cv->end;
        },
    );
    $cv->recv;

    print "token: ";
    my $oauth_token = <STDIN>;
    chomp $oauth_token;

    print "verifier: ";
    my $oauth_verifier = <STDIN>;
    chomp $oauth_verifier;

    $cv = AE::cv;
    $cv->begin;
    AnyEvent::Twitter->get_access_token(
        consumer_key       => $config->{consumer_key},
        consumer_secret    => $config->{consumer_secret},
        oauth_token        => $oauth_token,
        oauth_token_secret => $token{oauth_token_secret},
        oauth_verifier     => $oauth_verifier,
        cb => sub {
            my ($token, $body, $header) = @_;

            note Dumper \@_;
            note Dumper $token;

            ok defined $token->{oauth_token};
            ok defined $token->{oauth_token_secret};
            like $token->{user_id}, qr/^\d+$/, 'user_id';
            is $token->{screen_name}, $config->{screen_name};

            my $twitty = AnyEvent::Twitter->new(
                consumer_key    => $config->{consumer_key},
                consumer_secret => $config->{consumer_secret},
                token           => $token->{oauth_token},
                token_secret    => $token->{oauth_token_secret},
            );

            $twitty->get('account/verify_credentials', sub {
                my ($header, $res) = @_;

                note Dumper $res;

                is $res->{id}, $token->{user_id};
                is $res->{screen_name}, $token->{screen_name};

                $cv->end;
            });
        },
    );
    $cv->recv;
}


{
    my %token;

    my $cv = AE::cv;
    $cv->begin;
    AnyEvent::Twitter->get_request_token(
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
        callback_url    => 'http://localhost:5000/',
        cb => sub {
            my ($location, $token, $body, $header) = @_;

            note Dumper \@_;
            like $location, qr/^http/, 'authorize location';

            %token = %$token;
            $cv->end;
        },
    );
    $cv->recv;

    print "token: ";
    my $oauth_token = <STDIN>;
    chomp $oauth_token;

    print "verifier: ";
    my $oauth_verifier = <STDIN>;
    chomp $oauth_verifier;

    $cv = AE::cv;
    $cv->begin;
    AnyEvent::Twitter->get_access_token(
        consumer_key       => $config->{consumer_key},
        consumer_secret    => $config->{consumer_secret},
        oauth_token        => $oauth_token,
        oauth_token_secret => $token{oauth_token_secret},
        oauth_verifier     => $oauth_verifier,
        cb => sub {
            my ($token, $body, $header) = @_;

            note Dumper \@_;
            note Dumper $token;

            ok defined $token->{oauth_token};
            ok defined $token->{oauth_token_secret};
            like $token->{user_id}, qr/^\d+$/, 'user_id';
            is $token->{screen_name}, $config->{screen_name};

            my $twitty = AnyEvent::Twitter->new(
                consumer_key    => $config->{consumer_key},
                consumer_secret => $config->{consumer_secret},
                token           => $token->{oauth_token},
                token_secret    => $token->{oauth_token_secret},
            );

            $twitty->get('account/verify_credentials', sub {
                my ($header, $res) = @_;

                note Dumper $res;

                is $res->{id}, $token->{user_id};
                is $res->{screen_name}, $token->{screen_name};

                $cv->end;
            });
        },
    );
    $cv->recv;
}

done_testing();

