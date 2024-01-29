package My::Test::Encode::workflow;

use Moo::Role;

has output => (
    is      => 'ro',
    required => 1,
);

sub send {
    my $self = shift;
    push @{ $self->output }, @_;
}

sub setup {
    my $self = shift;
    push @{ $self->output }, 'start';
}

sub finalize {
    my $self = shift;
    push @{ $self->output }, 'finalize';
}

with 'Data::Record::Serialize::Role::EncodeAndSink';

1;
