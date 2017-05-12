package Acme::HidamariSketch;
use 5.008005;
use strict;
use warnings;
use utf8;

our $VERSION = "0.05";


my @characters = qw(
    Yuno
    Miyako
    Hiro
    Sae
    Nori
    Nazuna
    Matsuri
    Riri
    Misato
);

my %year = (
    before => 0,   # 前年  (ゆの入学前)
    first  => 1,   # 1年目 (ゆの入学)
    second => 2,   # 2年目
    third  => 3,   # 3年目 (現在)
);

my $SINGLETON;


sub new {
    if ($SINGLETON) {
        return $SINGLETON;
    }
    else {
        my $class = shift;

        my $SINGLETON = bless {characters => [], year => 'third'}, $class;

        $SINGLETON->_init;

        return $SINGLETON;
    }
}

sub characters {
    my ($self, %options) = @_;

    return @{$self->{characters}};
}

sub apartment {
    my $self = shift;

    my $module_name = 'Acme::HidamariSketch::Apartment';

    eval "require $module_name";

    my @tenant;
    for my $character (@{$self->{characters}}) {
        if (defined $character->{room_number}->{$self->year}) {
            push @tenant, $character;
        }
    }

    return $module_name->new({
        tenants => [@tenant],
        year    => $self->{year},
    });
}

sub year {
    my $self = shift;
    if (@_) {
        my $year = shift;
        for my $key (keys %year) {
            $self->{year} = $year if ($key eq $year);
        }
    }
    return $self->{year};
}

sub _init {
    my $self = shift;

    for my $character (@characters) {
        my $module_name = 'Acme::HidamariSketch::' . $character;

        eval "require $module_name;";
        push @{$self->{characters}}, $module_name->new;
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::HidamariSketch - This module of the Hidamalar, by the Hidamalar, for the Hidamalar.

=head1 SYNOPSIS

    use Acme::HidamariSketch;

    # Let's make the Hidamari-world first.
    my $hidamari = Acme::HidamariSketch->new;
   
    # You can see the character information.
    my @characters = $hidamari->characters;

    # You can build a Hidamari-apartment.
    my $apartment = $hidamari->apartment;

    # You can knock on the room.
    my $yuno = $apartment->knock(201);

    # You can change the year.
    $hidamari->year('second');
    $apartment = $hidamari->apartment;

    # You also meet Sae and Hiro.
    my $hiro = $apartment->knock(101);
    my $sae  = $apartment->knock(102);

=head1 DESCRIPTION

Hidamari Sketch is a Japanese manga that are loved by many people.

=head1 METHODS

=head2 new

    my $hidamari = Acme::HidamariSketch->new;

=head2 characters

    my @characters = $hidamari->characters;

=head2 apartment

    my $apartment = $hidamari->apartment;

    my $yuno = $apartment->knock(201);

=head2 year

    my $year = $hidamari->year('second');

=head1 SEE ALSO

=over 4

=item Hidamari Sketch (Wikipedia - ja)

http://ja.wikipedia.org/wiki/%E3%81%B2%E3%81%A0%E3%81%BE%E3%82%8A%E3%82%B9%E3%82%B1%E3%83%83%E3%83%81

=item Hidamari Sketch (Wikipedia - en)

http://en.wikipedia.org/wiki/Hidamari_Sketch

=item Blog of authorship

http://ap.sakuraweb.com/

=back

=head1 REFERENCE

=over 4

=item Acme::MorningMusume

https://github.com/kentaro/perl-acme-morningmusume

=item Acme::PrettyCure

https://github.com/kan/p5-acme-prettycure

=item Acme::MilkyHolmes

https://github.com/tsucchi/p5-Acme-MilkyHolmes

=back

=head1 LICENSE

Copyright (C) akihiro_0228.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

akihiro_0228 E<lt>nano.universe.0228@gmail.comE<gt>

=cut

