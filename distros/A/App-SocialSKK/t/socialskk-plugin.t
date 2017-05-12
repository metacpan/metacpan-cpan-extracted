package Test::App::SocialSKK::Plugin;
use lib 't/lib';
use App::SocialSKK::Test;
use App::SocialSKK::Plugin;

sub startup : Test(startup) {
    my $self = shift;
       $self->module = App::SocialSKK::Plugin->new;
}

sub accept : Tests {
    my $self = shift;

    desc 'When get_candidates() called,' => sub {
        it 'should die immediately because this it must be overridden by subclass.';
        dies_ok { $self->module->get_candidates } spec;
    };
}

__PACKAGE__->runtests;

1;
