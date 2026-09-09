package My::Test::Encode::store;

use Moo::Role;

has output => (
    is      => 'ro',
    default => sub { [] } );

sub send {    ## no critic (ProhibitBuiltinHomonyms)
    my $self = shift;
    push @{ $self->output }, @_;
}

sub close { }    ## no critic (ProhibitBuiltinHomonyms, ProhibitAmbiguousNames)

with 'Data::Record::Serialize::Role::EncodeAndSink';

1;
