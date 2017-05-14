package Acme::PrettyCure::CureDream;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'夢原のぞみ'}
sub precure_name {'キュアドリーム'}
sub age          {14}
sub challenge { '大いなる希望の力、キュアドリーム!' }

after 'transform' => sub {
    my ($self, @buddies) = @_;

    for my $buddy (@buddies) {
        $buddy->transform;
    }

    $self->say("希望の力と、未来の光");
    $self->say("華麗に羽ばたく五つの心!");
    $self->say("Yes! プリキュア5!");
};


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
