package Acme::PrettyCure::Girl::Role::Smile;
use utf8;
use Moo::Role;


after 'transform' => sub {
    my ($self, @buddies) = @_;

    for my $buddy (@buddies) {
        $buddy->transform;
    }

    if (scalar(@buddies) == 4) {
        $self->say("五つの心が導く未来!");
        $self->say("輝け! スマイルプリキュア!");
    }
};


1;

