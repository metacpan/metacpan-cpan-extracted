package Acme::Keyakizaka46;

use strict;
use warnings;

use Carp  qw(croak);
use DateTime;

our $VERSION = '0.0.1';

my @members = qw(
    NijikaIshimori
    YuiImaizumi
    RinaUemura
    RikaOzeki
    NanaOda
    MinamiKoike
    YuiKobayashi
    FuyukaSaito
    ShioriSato
    ManakaShida
    YuukaSugai
    MiyuSuzumoto
    NanakoNagasawa
    MizuhoHabu
    AoiHarada
    YurinaHirate
    AkaneMoriya
    NanamiYonetani
    RikaWatanabe
    RisaWatanabe
    NeruNagahama
    MaoIguchi
    SarinaUshio
    MemiKakizaki
    YukaKageyama
    ShihoKato
    KyokoSaito
    KumiSasaki
    MireiSasaki
    ManaTakase
    AyakaTakamoto
    MeiHigashimura
    MikuKanemura
    HinaKawata
    NaoKosaka
    SuzukaTomita
    AkariNibu
    HiyoriHamagishi
    KonokaMatsuda
    ManamoMiyata
    MihoWatanabe
);

sub new {
    my $class = shift;
    my $self  = bless {members => []}, $class;

    $self->_initialize;

    return $self;
}

sub team_members {
    my ($self, $type, @members) = @_;
    @members = @{$self->{members}} unless @members;

    $type = $type ? $type : '';

    if ($type eq 'kanji') {
        return grep {$_->team eq 'kanji'} @members;
    }
    elsif ($type eq 'hiragana') {
        return grep {$_->team eq 'hiragana'} @members;
    }

    return @members;
}

sub sort {
    my ($self, $type, $order, @members) = @_;
    @members = $self->team_members() unless @members;

    if ($order eq 'desc') {
        return sort {$b->$type <=> $a->$type} @members;
    } else {
        return sort {$a->$type <=> $b->$type} @members;
    }
}

sub select {
    my ($self, $type, $num_or_str, $operator, @members) = @_;

    @members = $self->team_members() unless @members;

    if ($type eq 'center') {
        $self->_die('too many args...')
            if ($num_or_str || $operator);

        return grep {$_->{name_en} eq 'Yurina Hirate'} @members;
    }
    else {
        $self->_die('invalid operator was passed in')
            unless grep {$operator eq $_} qw(== >= <= > < eq ne);

        my $compare = eval "(sub { \$num_or_str $operator \$_[0] })";

        return grep { $compare->($_->$type) } @members;
    }

}

sub _initialize {
    my $self = shift;

    for my $member (@members) {
        my $module_name = 'Acme::Keyakizaka46::'.$member;

        eval qq|require $module_name;|;
        push @{$self->{members}}, $module_name->new;
    }

    return 1;
}

sub _die {
    my ($self, $message) = @_;
    Carp::croak($message);
}

1;

__END__

=head1 NAME

Acme::Keyakizaka46 - All about Japanse idol group "Keyakizaka46"

=head1 SYNOPSIS

  use Acme::Keyakizaka46;

  my $keyaki = Acme::Keyakizaka46->new;

  # retrieve the members on their activities
  my @members              = $keyaki->team_members;             # retrieve all
  my @kanji_members        = $keyaki->team_members('kanji');
  my @hiragana_members     = $keyaki->team_members('hiragana');

  # retrieve the members under some conditions
  my @sorted_by_age        = $keyaki->sort('age', 'asc');
  my @sorted_by_class      = $keyaki->sort('class','desc');
  my @selected_by_age      = $keyaki->select('age', 18, '>=');
  my @selected_by_class    = $keyaki->select('class', 2, '==');

=head1 DESCRIPTION

"Keyakizaka46" is a Japanese famous idol group.
This module, Acme::Keyakizaka46, provides an easy method to catch up
with Keyakizaka46.

=head1 METHODS

=head2 new

=over 4

  my $keyaki = Acme::Keyakizaka46->new;

Creates and returns a new Acme::Keyakizaka46 object.

=back

=head2 members ( $type )

=over 4

  # $type can be one of the values below:
  #  + kanji               : kanji Keyaki members
  #  + hiragana            : hiragana Keyaki members
  #  + undef               : all members

  my @members = $keyaki->team_members('kanji');

Returns the members as a list of the L<Acme::Keyakizaka46::Base>
based object represents each member. See also the documentation of
L<Acme::Keyakizaka46::Base> for more details.

=back

=head2 sort ( $type, $order [ , @members ] )

=over 4

  # $type can be one of the values below:
  #  + age   :  sort by age
  #  + class :  sort by class
  #
  # $order can be a one of the values below:
  #  + desc                :  sort in descending order
  #  + asc (anything else) :  sort in ascending order

  my @sorted_members = $keyaki->sort('age','desc'); # sort by age in descending order

Returns the members sorted by the I<$type> field.

=back

=head2 select ( $type, $number, $operator [, @members] )

=over 4

  # $type can be one of the same values above:
  my @selected_members = $keyaki->select('age', 18, '>=');

Returns the members satisfy the given I<$type> condition. I<$operator>
must be a one of '==', '>=', '<=', '>', and '<'. This method compares
the given I<$type> to the member's one in the order below:

  $number $operator $member_value

=back

=head1 SEE ALSO

=over 4

=item * Keyakizaka46 (Official Site)

L<http://www.keyakizaka46.com/>

=item * Acme::Nogizaka46

L<http://search.cpan.org/~twogmon/Acme-Nogizaka46-0.3/lib/Acme/Nogizaka46.pm>

=back

=head1 AUTHOR

Okawara Ayato E<lt>2044taiga@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Okwara Ayato.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
