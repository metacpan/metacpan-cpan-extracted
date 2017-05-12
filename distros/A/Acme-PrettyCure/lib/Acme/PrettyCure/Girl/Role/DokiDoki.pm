package Acme::PrettyCure::Girl::Role::DokiDoki;
use utf8;
use Moo::Role;

after 'transform' => sub {
    my ($self, @buddies) = @_;

    for my $buddy (@buddies) {
        $buddy->transform;
    }

    if (scalar(@buddies) == 3) {
        $self->say("ドキドキ!プリキュア!");
    }
};



1;

