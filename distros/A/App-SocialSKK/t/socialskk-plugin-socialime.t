package Test::App::SocialSKK::Plugin::SocialIME;
use LWP::UserAgent;
use lib 't/lib';
use App::SocialSKK::Test;
use App::SocialSKK::Plugin::SocialIME;

sub startup : Test(startup) {
    my $self = shift;
       $self->module = App::SocialSKK::Plugin::SocialIME->new({
           ua => LWP::UserAgent->new,
       });
}

sub get_candidates : Tests {
    my $self = shift;
    my $network_is_alive = $self->ping('www.social-ime.com');

 SKIP: {
        skip 'This test requires netword connection.' if !$network_is_alive;

        desc 'When get_candidates() called,' => sub {
            it 'for the word "ああ", some candidates should be returned.';
            ok scalar $self->module->get_candidates('ああ'), spec;

            it 'for empty string, no candidate should be returned.';
            ok !scalar $self->module->get_candidates(''), spec;
        };
    }
}

__PACKAGE__->runtests;

1;
