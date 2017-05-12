package Acme::Nogizaka46::InoueSayuri;

use strict;
use warnings;

use base qw(Acme::Nogizaka46::Base);

our $VERSION = 0.3;

sub info {
    return (
        first_name_ja  => '小百合',
        family_name_ja => '井上',
        first_name_en  => 'Sayuri',
        family_name_en => 'Inoue',
        nick           => [qw(さゆにゃん)],
        birthday       => $_[0]->_datetime_from_date('1994-12-14'),
        blood_type     => 'B',
        hometown       => '埼玉',
        class          => 1,
        center         => undef,
        graduate_date  => undef,
    );
}

1;
