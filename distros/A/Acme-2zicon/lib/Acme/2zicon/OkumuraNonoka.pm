package Acme::2zicon::OkumuraNonoka;

use strict;
use warnings;

use base qw(Acme::2zicon::Base);

our $VERSION = '0.7';

sub info {
    my $self = shift;
    return (
        first_name_ja  => '野乃花',
        family_name_ja => '奥村',
        first_name_en  => 'Nonoka',
        family_name_en => 'Okumura',
        nick           => [qw(ののた)],
        birthday       => $self->_datetime_from_date('2001.01.04'),
        blood_type     => 'O',
        hometown       => '東京都',
        introduction   => "アイドルオタクの進化系。毎日がビッグバン。せーの！\n＼どーん／\n[hometown]出身の最年少[age]歳。\nののたこと[name_ja]です。",
        twitter        => 'okumura_nonoka',
    );
}

1;
