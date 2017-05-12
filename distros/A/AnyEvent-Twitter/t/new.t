use strict;
use Test::More;
use AnyEvent::Twitter;

{
    my $ua = AnyEvent::Twitter->new(
        consumer_key        => 'consumer_key',
        consumer_secret     => 'consumer_secret',
        access_token        => 'access_token',
        access_token_secret => 'access_token_secret',
    );

    isa_ok $ua, 'AnyEvent::Twitter';
}

{
    my $ua = AnyEvent::Twitter->new(
        consumer_key    => 'consumer_key',
        consumer_secret => 'consumer_secret',
        token           => 'token',
        token_secret    => 'token_secret',
    );

    isa_ok $ua, 'AnyEvent::Twitter';
}

{
    local $@;
    eval {
        my $ua = AnyEvent::Twitter->new(
            consumer_key    => 'consumer_key',
            consumer_secret => 'consumer_secret',
            access_token    => '',
            token_secret    => 'token_secret',
        );
    };

    like $@, qr/access_token is required/, 'arguments validation';
}

done_testing;

