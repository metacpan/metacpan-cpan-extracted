use Mojo::Base '-strict';
use Test::More;
use Mojo::UserAgent;
eval "use Test::Output;";

plan skip_all => "Test::Output required for this test" if $@;

# skip this test when offline
{
    my $ua = Mojo::UserAgent->new(max_redirects => 10);
    $ua->proxy->detect;
    my $tx = $ua->get('api.metacpan.org');
    if (not $tx->success) {
        plan(skip_all => $tx->error);

        #plan(skip_all => "Because we are offline.");
    }
}

use_ok('Ado');
my $ACV = 'Ado::Command::version';
use_ok('Ado::Command::version');
isa_ok($ACV->new(), 'Ado::Command');

stdout_like(
    sub { $ACV->new->run },
    qr/$Ado::VERSION.+Mojolicious/msx,
    'current release output ok'
);
$Ado::VERSION = '24.00';
stdout_like(
    sub { $ACV->new->run },
    qr/$Ado::VERSION.+development\sreleas.+Mojolicious/msx,
    'develelopment release output ok'
);
$Ado::VERSION = '0.22';
stdout_like(
    sub { $ACV->new->run },
    qr/$Ado::VERSION.+update\syour\sAdo.+Mojolicious/msx,
    'old release output ok'
);

done_testing();
