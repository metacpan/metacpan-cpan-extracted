package Acme::PrettyCure::Girl::Role::Five;
use utf8;
use Moo::Role;


after 'transform' => sub {
    my ($self, @buddies) = @_;

    for my $buddy (@buddies) {
        $buddy->transform;
    }

    if (scalar(@buddies) == 4) {
        $self->say("希望の力と、未来の光");
        $self->say("華麗に羽ばたく五つの心!");
        $self->say("Yes! プリキュア5!");
    }
};


1;

