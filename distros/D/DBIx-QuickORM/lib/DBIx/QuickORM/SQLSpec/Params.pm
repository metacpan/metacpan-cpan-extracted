package DBIx::QuickORM::SQLSpec::Params;
use strict;
use warnings;

our $VERSION = '0.000002';

sub new {
    my $class = shift;

    my %params;
    if (@_ == 1 && ref($_[0]) eq 'HASH') {
        %params = %{$_[0]};
    }
    else {
        %params = @_;
    }

    return bless(\%params, $class);
}

sub param { $_[0]->{$_[1]} // undef }
sub set_param { $_[0]->{$_[1]} = $_[2] }

sub clone {
    my $self = shift;
    my %params = @_;

    return ref($self)->new(%$self, %params);
}

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    return ref($self)->new(%$other, %$self, %params);
}

1;
