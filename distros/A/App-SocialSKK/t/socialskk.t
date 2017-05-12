package Test::App::SocialSKK;
use LWP::UserAgent;
use lib 't/lib';
use App::SocialSKK;
use App::SocialSKK::Test;

sub startup : Test(startup) {
    my $self = shift;
       $self->module = App::SocialSKK->new({
           ua       => LWP::UserAgent->new,
           hostname => 'localhost',
           address  => '127.0.0.1',
           config   => {
               plugins => [
                   { name => 'SocialIME'},
                   { name => 'Wikipedia'},
               ],
           }
       });
}

sub constructor : Tests {
    my $self = shift;

    desc 'When App::SocialSKK is instanciated,' => sub {
        it 'App::SocialSKK object should be returned.';
        isa_ok $self->module, 'App::SocialSKK';
    };
}

sub init : Tests {
    my $self = shift;

    desc 'When init() called,' => sub {
        it 'App::SocialSKK object should be returned.';
        isa_ok $self->module, 'App::SocialSKK';

        it 'App::SocialSKK::Protocol object should be set.';
        ok $self->module->protocol, spec;
        isa_ok $self->module->protocol, 'App::SocialSKK::Protocol';

        it 'plugins should be set appropriately.';
        ok $self->module->plugins, spec;
        isa_ok $self->module->plugins->[0], 'App::SocialSKK::Plugin::SocialIME';
        isa_ok $self->module->plugins->[1], 'App::SocialSKK::Plugin::Wikipedia';
    };
}

sub ua {
    my $self = shift;

    desc 'When ua() called,' => sub {
        it 'LWP::UserAgent object should be returned.';
        isa_ok $self->module->ua, 'LWP::UserAgent';
    };
}

sub get_version : Tests {
    my $self = shift;

    desc 'When get_version() called,' => sub {
        it 'correct version string should be returned.';
        is $self->module->get_version,
           sprintf('App::SocialSKK/%s ', $App::SocialSKK::VERSION),
           spec;
    };
}

sub get_serverinfo : Tests {
    my $self = shift;

    desc 'When get_version() called,' => sub {
        it 'correct serverinfo string should be returned.';
        is $self->module->get_serverinfo, 'localhost:127.0.0.1: ', spec;
    };
}

sub get_serverinfo : Tests {
    my $self = shift;

    desc 'When get_version() called,' => sub {
        it 'correct serverinfo string should be returned.';
        is $self->module->get_serverinfo, 'localhost:127.0.0.1: ', spec;
    };
}

sub get_candidates : Tests {
    my $self = shift;
    my $network_is_alive = $self->ping('www.social-ime.com') &&
                           $self->ping('ja.wikipedia.org');

 SKIP: {
        skip 'This test requires netword connection.' if !$network_is_alive;

        desc 'When get_candidates() called,' => sub {
            it 'for the word "ああ", some candidates should be returned.';
            like $self->module->get_candidates('ああ'), qr/^1.+/, spec;

            it 'for empty string, no candidate should be returned.';
            like $self->module->get_candidates(''), qr/^4/, spec;
        };
    }
}

__PACKAGE__->runtests;

1;
