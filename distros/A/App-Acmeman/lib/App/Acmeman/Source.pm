package App::Acmeman::Source;

use strict;
use warnings;
use Carp;

sub set {
    my $self = shift;
    croak "improper use of the set method"
	unless exists $self->{_cfg};
    return $self->{_cfg}->set(@_);
}

sub add {
    my $self = shift;
    croak "improper use of the add method"
	unless exists $self->{_cfg};
    return $self->{_cfg}->add_value(@_);
}

sub get {
    my $self = shift;
    croak "improper use of the get method"
	unless exists $self->{_cfg};
    return $self->{_cfg}->get(@_);
}

sub is_set {
    my $self = shift;
    croak "improper use of the get method"
	unless exists $self->{_cfg};
    return $self->{_cfg}->is_set(@_);
}

sub define_domain {
    my $self = shift;
    my $cn = shift || croak "domain name must be given";
    $self->set('domain', $cn, 'files', 'default');
}

sub define_alias {
    my $self = shift;
    my $cn = shift || croak "domain name must be given";
    foreach my $alias (@_) {
	$self->add(['domain', $cn, 'alt'], $alias);
    }
}

sub configure {
    my ($self, $config) = @_;
    $self->{_cfg} = $config;
    return $self->scan();
}

sub setup { 1 }

1;
