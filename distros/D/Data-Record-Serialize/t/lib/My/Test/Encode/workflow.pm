package My::Test::Encode::workflow;

use Moo::Role;

has output => (
    is       => 'ro',
    required => 1,
);

sub send {    ## no critic (ProhibitBuiltinHomonyms)
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

sub close { }    ## no critic (ProhibitBuiltinHomonyms, ProhibitAmbiguousNames)

with 'Data::Record::Serialize::Role::EncodeAndSink';

1;
