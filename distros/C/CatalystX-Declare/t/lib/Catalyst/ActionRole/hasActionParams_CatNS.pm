package Catalyst::ActionRole::hasActionParams_CatNS;
use Moose::Role;

has [qw/p1 p2/] => (is=>'ro', lazy_build=>1);

sub _build_p1 {
    my $self = shift @_;
    return join ',', @{$self->attributes->{p1}};
}

sub _build_p2 {
    my $self = shift @_;
    return join ',', @{$self->attributes->{p2}};
}

1;
