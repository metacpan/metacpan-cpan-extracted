package Example::Customer;

use strict;
use warnings;

my %customer_for = (
    1 => {
        first => 'Ovid',
        last  => 'Naso',
        id    => 1,
    },
    2 => {
        first => 'Corinna',
        last  => 'Naso',
        id    => 2,
    },
);

sub new {
    my $class = shift;
    if (@_) {
        my $id = shift;
        return unless exists $customer_for{$id};
        return bless $customer_for{$id}, $class;
    }
    else {
        return bless { map { $_ => undef } qw/id first last/ }, $class;
    }
}

sub id { shift->{id} }

sub first {
    my $self = shift;
    return $self->{first} unless @_;
    $self->{first} = shift;
    return $self;
}

sub last {
    my $self = shift;
    return $self->{last} unless @_;
    $self->{last} = shift;
    return $self;
}

1;
