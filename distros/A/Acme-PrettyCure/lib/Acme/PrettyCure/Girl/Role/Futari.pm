package Acme::PrettyCure::Girl::Role::Futari;
use utf8;
use Moo::Role;

around 'transform' => sub {
    my $transform = shift;
    my ($self, $buddy) = @_;

    $self->$transform;

    unless ($buddy->is_precure) {
        $buddy->is_precure(1);
    }
};


1;

