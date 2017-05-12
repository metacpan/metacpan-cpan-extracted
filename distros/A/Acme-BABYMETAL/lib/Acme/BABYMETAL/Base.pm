package Acme::BABYMETAL::Base;
use strict;
use warnings;
use DateTime;
use base qw(Class::Accessor);

our $VERSION = '0.03';

__PACKAGE__->mk_accessors(qw(
    metal_name
    name_ja
    first_name_ja
    family_name_ja
    name_en
    first_name_en
    family_name_en
    birthday
    age
    blood_type
    hometown
));

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    $self->_initialize;
    return $self;
}

sub _initialize {
    my $self = shift;
    my %info = $self->info;

    $self->{$_}      = $info{$_} for keys %info;
    $self->{name_ja} = $self->family_name_ja . $self->first_name_ja;
    $self->{name_en} = $self->first_name_en . ' ' . $self->family_name_en;
    my ($year, $month, $day) = ($self->{birthday} =~ /^(\d{4})-(\d{2})-(\d{2})$/);
    $self->{age} = (DateTime->now - DateTime->new(
        year => $year,
        month => $month,
        day => $day,
    ))->years;

    return 1;
}

sub shout {
    my $self = shift;
    print $self->metal_name . " DEATH!!\n";
}


1;

