package Test::App::SocialSKK::Base;
use lib 't/lib';
use App::SocialSKK::Test;
use App::SocialSKK::Base;

sub startup : Test(startup) {
    my $self = shift;
       $self->module = App::SocialSKK::Base->new;
}

sub constructor : Tests {
    my $self = shift;

    desc 'When an App::SocialSKK::Base is instanciated,' => sub {
        it 'Class::Accessor::Lvalue::Fast object should be returned.';
        isa_ok $self->module, 'Class::Accessor::Lvalue::Fast';
    };
}

__PACKAGE__->runtests;

1;
