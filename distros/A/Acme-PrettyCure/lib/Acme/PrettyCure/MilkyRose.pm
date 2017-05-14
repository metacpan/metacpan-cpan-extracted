package Acme::PrettyCure::MilkyRose;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

has 'is_fairy' => (is => 'rw', isa => 'Bool', default => sub { 0 });

sub fairy_name   {'ミルク'}
sub human_name   {'美々野くるみ'}
sub precure_name {'ミルキィーローズ'}
sub age          {14}
sub challenge { '青いバラは秘密の印、ミルキィローズ!' }

sub name {
    my $self = shift;

    return
          $self->is_fairy   ? $self->fairy_name
        : $self->is_precure ? $self->precure_name
        :                     $self->human_name;
}

sub powerdown {
    my $self = shift;

    $self->is_precure(0);
    $self->is_fairy(1);
}

before 'transform' => sub {
    my $self = shift;

    $self->is_fairy(0);
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
