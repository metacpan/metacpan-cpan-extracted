package Acme::MilkyHolmes::Character::KazumiTokiwa;
use Mouse;
extends 'Acme::MilkyHolmes::Group::MilkyHolmes';

use utf8;
use Time::Piece;

no Mouse;

sub voiced_by { #override
    my ($self) = @_;
    my $now = localtime();
    my $threshold = Time::Piece->strptime('2013-12-25T00:00:00Z', '%Y-%m-%dT%H:%M:%SZ');
    if ( $now >= $threshold ) {
        return $self->_localized_field('voiced_by');
    }
    return $self->_localized_field('voiced_by_before');
}


1;

__DATA__

@@ common
---
color: black
color_enable: 0

@@ en
---
firstname: Kazumi
familyname: Tokiwa
birthday: November 20
voiced_by: Aimi
nickname_voiced_by: aimin
voiced_by_before: Aimi Terakawa
toys: Arrow

@@ ja
---
firstname: カズミ
familyname: 常盤
birthday: 11/20
voiced_by: 愛美
nickname_voiced_by: あいみん
voiced_by_before: 寺川 愛美
toys: アロー
