package BioX::Workflow::Command::Exceptions;

use Moose;
use namespace::autoclean;

has 'message' => (
    is      => 'rw',
    isa     => 'Str',
    required => 0,
    documentation => 'This is a general message for the type of error thrown.',
    predicate => 'has_message',
);

has 'info' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => 'Information specific to the error thrown',
    predicate     => 'has_info',
);

sub warn {
    my $self   = shift;
    my $logger = shift;

    if ($logger) {
        $logger->warn( $self->message ) if $self->has_message;
        $logger->warn( $self->info ) if $self->has_info;
    }
    else {
        Core::warn $self->message if $self->has_message;
        Core::warn $self->info  if $self->has_info;
    }
}

sub fatal {
    my $self   = shift;
    my $logger = shift;

    if ($logger) {
        $logger->fatal( $self->message ) if $self->has_message;
        $logger->fatal( $self->info ) if $self->has_info;
    }
    else {
        Core::warn $self->message if $self->has_message;
        Core::warn $self->info  if $self->has_info;
    }

    exit 1;
}

__PACKAGE__->meta->make_immutable;

1;
