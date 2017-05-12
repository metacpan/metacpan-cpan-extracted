package Acme::MorningMusume::IshikawaRika;

use strict;
use warnings;

use base qw(Acme::MorningMusume::Base);

our $VERSION = '0.20';

sub info {
    return (
        first_name_ja  => '梨華',
        family_name_ja => '石川',
        first_name_en  => 'Rika',
        family_name_en => 'Ishikawa',
        nick           => [qw(りかっち チャーミー)],
        birthday       => $_[0]->_datetime_from_date('1985-01-19'),
        blood_type     => 'A',
        hometown       => '神奈川県',
        emoticon       => ['（ ＾▽＾）'],
        class          => 4,
        graduate_date  => $_[0]->_datetime_from_date('2005-05-07'),
    );
}

1;
