#
# Test script for ticket RT 40116
#
use strict;
use Test::More;

package Acme::MetaSyntactic::yeye;
no warnings 'once';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );

my $real_names = {
    default => 'chats_sauvages',
    names   => {
        idole_des_jeunes   => "Jean_Philippe Smet",
        chaussettes_noires => "Claude Moine",
        chats_sauvages     => "Herve Fornieri",
    }
};

__PACKAGE__->init($real_names);

package main;
plan('tests', 7);
is( $Acme::MetaSyntactic::yeye::Default, 'chats_sauvages', "Default category");
is( $Acme::MetaSyntactic::yeye::MultiList{idole_des_jeunes}[0],   'Jean_Philippe', 'Christian name of idole des jeunes');
is( $Acme::MetaSyntactic::yeye::MultiList{idole_des_jeunes}[1],   'Smet',          'Surname of idole des jeunes');
is( $Acme::MetaSyntactic::yeye::MultiList{chaussettes_noires}[0], 'Claude',        'Christian name of the singer of chaussettes noires');
is( $Acme::MetaSyntactic::yeye::MultiList{chaussettes_noires}[1], 'Moine',         'Surname of the singer of chaussettes noires');
is( $Acme::MetaSyntactic::yeye::MultiList{chats_sauvages}[0],     'Herve',         'Christian name of the singer of chats sauvages');
is( $Acme::MetaSyntactic::yeye::MultiList{chats_sauvages}[1],     'Fornieri',      'Surname of the singer of chats sauvages');

package Acme::MetaSyntactic::yeye;
__DATA__

# default
chaussettes_noires
# names idole_des_jeunes
Johnny Halliday
# names chaussettes_noires
Eddy Mitchell
# names chats_sauvages
Dick Rivers

