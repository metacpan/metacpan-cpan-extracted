package Acme::PrettyCure::Role;
use utf8;
use Any::Moose '::Role';

use Encode;

requires qw(human_name precure_name challenge);

has 'is_precure' => (is => 'rw', isa => 'Bool', default => sub { 0 });

sub say {
    my ($self, $text) = @_;
    print encode_utf8("$text\n");
}

sub name {
    my $self = shift;

    return $self->is_precure ? $self->precure_name : $self->human_name;
}

sub transform {
    my ($self, $buddy) = @_;

    die "already transformed" if $self->is_precure;

    $self->is_precure(1);

    if ($buddy && !$buddy->is_precure) {
        $self->say($_) for $self->challenge;
    } elsif (!$buddy) {
        $self->say($_) for $self->challenge;
    }

    return $self;
}

1;
