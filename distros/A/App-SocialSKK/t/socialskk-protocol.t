package Test::App::SocialSKK::Protocol;
use lib 't/lib';
use App::SocialSKK::Test;
use App::SocialSKK::Protocol;

sub startup : Test(startup) {
    my $self = shift;
       $self->module = App::SocialSKK::Protocol->new({
           on_get_candidates => \&on_get_candidates,
           on_get_version    => \&on_get_version,
           on_get_serverinfo => \&on_get_serverinfo,
       });
}

sub accept : Tests {
    my $self = shift;

    desc 'When accept() called:' => sub {
        it 'if request is get_candidates, on_get_candidates event is fired.';
        is $self->module->accept('1foo bar'), 'on_get_candidates', spec;
        it 'if request is get_serverinfo, on_get_version event is fired.';
        is $self->module->accept('2'), 'on_get_version', spec;
        it 'if request is get_serverinfo, on_get_serverinfo event is fired.';
        is $self->module->accept('3'), 'on_get_serverinfo', spec;
        it 'if request is incorrect, undef is returned.';
        ok !$self->module->accept('9unknown request'), spec;
    };
}

sub dispatch : Tests {
    my $self = shift;

    desc 'When dispatch() called:' => sub {
        it 'if code is 1, on_get_candidates event is fired.';
        is $self->module->dispatch(1, 'on_get_candidates()'), 'on_get_candidates', spec;
        it 'if code is 2, on_get_version event is fired.';
        is $self->module->dispatch(2, 'on_get_version()'), 'on_get_version', spec;
        it 'if code is 3, on_get_serverinfo event is fired.';
        is $self->module->dispatch(3, 'on_get_serverinfo()'), 'on_get_serverinfo', spec;
        it 'if code doesnt match any code, undef is returned.';
        ok !$self->module->dispatch(9, 'doesnt match any event'), spec;
    };
}

sub on_get_candidates { 'on_get_candidates' }
sub on_get_version    { 'on_get_version' }
sub on_get_serverinfo { 'on_get_serverinfo' }

__PACKAGE__->runtests;

1;
