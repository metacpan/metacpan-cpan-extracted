use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;

use Test::More;
use Mojo::Log;
use Mojo::Promise;

use CallBackery::GuiPlugin::AbstractForm;

# A getter may do real work: probe a server, run a command, change system
# state. getAllFieldValues answers every form load and every form reset,
# so it must run each getter exactly once.

package TestForm;
use Mojo::Base 'CallBackery::GuiPlugin::AbstractForm', -signatures;

has calls => sub { {} };
has log => sub { Mojo::Log->new(level => 'fatal') };

has formCfg => sub ($self) {
    return [
        {
            key    => 'plain',
            widget => 'text',
            getter => sub ($plugin) { $plugin->calls->{plain}++; return 'p' },
        },
        {
            key    => 'async',
            widget => 'text',
            getter => sub ($plugin) {
                $plugin->calls->{async}++;
                return Mojo::Promise->resolve('a');
            },
        },
    ];
};

package main;

subtest 'a plain getter runs once' => sub {
    my $form = TestForm->new;
    my $map = $form->getAllFieldValues({}, {}, {});
    $map->wait if eval { $map->isa('Mojo::Promise') };
    is($form->calls->{plain}, 1, 'plain getter called once');
};

subtest 'an async getter runs once' => sub {
    my $form = TestForm->new;
    my $map = $form->getAllFieldValues({}, {}, {});
    $map->wait if eval { $map->isa('Mojo::Promise') };
    is($form->calls->{async}, 1, 'async getter called once');
};

subtest 'every value still arrives' => sub {
    my $form = TestForm->new;
    my $got;
    $form->getAllFieldValues({}, {}, {})->then(sub { $got = shift })->wait;
    is_deeply($got, { plain => 'p', async => 'a' }, 'both values in the map');
};

done_testing();
