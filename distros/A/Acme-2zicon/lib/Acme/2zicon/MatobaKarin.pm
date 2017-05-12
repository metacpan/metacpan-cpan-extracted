package Acme::2zicon::MatobaKarin;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '華鈴',
        family_name_ja => '的場',
        first_name_en  => 'Karin',
        family_name_en => 'Matoba',
        nick           => [qw(かりん かりんさま)],
        birthday       => $self->_datetime_from_date('2000.12.30'),
        blood_type     => 'A',
        hometown       => '埼玉県',
        introduction   => "[hometown]からやってきた最年少の[age]歳。かりんさまってよんでもいいよ。\n＼かりんさまー！／\nダンスと梅干しが大好きな[name_ja]です。",
        twitter        => 'matoba_karin',
    );
}

1;
