package Acme::HidamariSketch::Apartment;
use strict;
use warnings;
use utf8;
use Data::Dumper;


our $VERSION = "0.05";


sub new {
    my ($class, $args) = @_;


    my $self = bless {
        tenants => $args->{tenants},
        year    => $args->{year}
    }, $class;

    return $self;
}

sub knock {
    my ($self, $knock_room) = @_;
 
    if (!defined $knock_room) {
        # 部屋が存在しない
        return undef;
    }

    for my $tenant (@{$self->{tenants}}) {
        my $room_number = $tenant->{room_number}->{$self->{year}};
        if (defined $room_number and $knock_room == $room_number) {
            return $tenant;
        };
    }

    # 存在しない部屋番号
    return undef;
}

