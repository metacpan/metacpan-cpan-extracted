use strict;
use warnings;
use Test::More 0.98;

use Captcha::Cloudflare::Turnstile;

sub exception(&) {
    my ($code) = @_;
    my $err = eval { $code->(); 1 } ? '' : $@;
    return $err;
}

{
    package Captcha::Cloudflare::Turnstile::TestDouble;
    use parent 'Captcha::Cloudflare::Turnstile';

    sub verify {
        my ( $self, $response ) = @_;
        return $self->{_verify_map}{$response};
    }

    sub set_verify_map {
        my ( $self, $map ) = @_;
        $self->{_verify_map} = $map;
    }
}

subtest 'constructor and helper tags' => sub {
    my $ts = Captcha::Cloudflare::Turnstile->new(
        secret     => 'secret',
        sitekey    => 'sitekey',
        query_name => 'custom-response',
    );

    is $ts->name, 'custom-response', 'name() uses query_name from constructor';
    is "$ts",     'custom-response', 'stringify reflects query_name';

    is $ts->widgetTag, '<div class="cf-turnstile" data-sitekey="sitekey"></div>',
        'widgetTag uses stored sitekey';
    is $ts->widgetTag( sitekey => 'override', action => 'login' ),
        '<div class="cf-turnstile" data-sitekey="override" data-action="login"></div>',
        'widgetTag supports sitekey override and action';

    like $ts->scripts, qr/data-action="homepage"/, 'scripts() defaults action to homepage';
    like $ts->scripts, qr/<script src="/, 'scripts() includes script tag';
};

subtest 'constructor and widget error cases' => sub {
    like(
        exception { Captcha::Cloudflare::Turnstile->new() },
        qr/missing param 'secret'/,
        'constructor requires secret',
    );

    my $no_sitekey = Captcha::Cloudflare::Turnstile->new( secret => 'secret' );
    like(
        exception { $no_sitekey->widgetTag },
        qr/missing 'sitekey'/,
        'widgetTag requires sitekey when none is set',
    );
};

subtest 'verify_or_die and deny_by_score' => sub {
    my $ts = Captcha::Cloudflare::Turnstile::TestDouble->new(
        secret     => 'secret',
        sitekey    => 'sitekey',
        query_name => 'custom-response',
    );

    my $verify_map = {
        pass => { success => 1 },
        fail => { success => 0, 'error-codes' => ['invalid-input-response'] },
    };
    $ts->set_verify_map($verify_map);

    is_deeply $ts->verify_or_die( response => 'pass' ),
        { success => 1 }, 'verify_or_die returns content on success';

    like(
        exception { $ts->verify_or_die( response => 'fail' ) },
        qr/fail to verify Turnstile: invalid-input-response/,
        'verify_or_die dies with first error code',
    );

    like(
        exception { $ts->verify_or_die() },
        qr/missing response token/,
        'verify_or_die requires response',
    );

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    is_deeply $ts->deny_by_score( response => 'pass' ),
        { success => 1 }, 'deny_by_score delegates to verify';
    is scalar @warnings, 1, 'deny_by_score emits one warning';
    like $warnings[0], qr/not applicable for Cloudflare Turnstile/, 'deny_by_score warns';

    like(
        exception { $ts->deny_by_score() },
        qr/missing response token/,
        'deny_by_score requires response',
    );
};

done_testing;
