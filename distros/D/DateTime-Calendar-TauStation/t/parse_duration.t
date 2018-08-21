use strict;
use warnings;
use Test::More tests => 32;
use DateTime::Format::TauStation;

# don't test per-second accuracy - many test report failures

{
    my $dt = DateTime::Format::TauStation->parse_datetime('000.00/00:000 GCT');

    my $dur = DateTime::Format::TauStation->parse_duration('D4.3/02:001 GCT');

    is($dur->gct_sign(),           "", 'duration gct_sign');
    is($dur->gct_cycles(),        004, 'duration gct_cycles');
    is($dur->gct_days(),           03, 'duration gct_days');
    is($dur->gct_segments(),       02, 'duration gct_segments');

    $dt->add_duration($dur);

    is($dt->gct_sign(),          "", 'gct_sign');
    is($dt->gct_cycle(),        004, 'gct_cycle');
    is($dt->gct_day(),           03, 'gct_day');
    is($dt->gct_segment(),       02, 'gct_segment');
}

{
    my $dt = DateTime::Format::TauStation->parse_datetime('198.15/03:973 GCT');

    my $dur = DateTime::Format::TauStation->parse_duration('D3/02:001 GCT');

    is($dur->gct_sign(),           "", 'duration gct_sign');
    is($dur->gct_cycles(),        000, 'duration gct_cycles');
    is($dur->gct_days(),           03, 'duration gct_days');
    is($dur->gct_segments(),       02, 'duration gct_segments');

    $dt->add_duration($dur);

    is($dt->gct_sign(),          "", 'gct_sign');
    is($dt->gct_cycle(),        198, 'gct_cycle');
    is($dt->gct_day(),           18, 'gct_day');
    is($dt->gct_segment(),       05, 'gct_segment');
}

{
    my $dt = DateTime::Format::TauStation->parse_datetime('198.15/03:973 GCT');

    my $dur = DateTime::Format::TauStation->parse_duration('D/02:001 GCT');

    is($dur->gct_sign(),           "", 'duration gct_sign');
    is($dur->gct_cycles(),        000, 'duration gct_cycles');
    is($dur->gct_days(),           00, 'duration gct_days');
    is($dur->gct_segments(),       02, 'duration gct_segments');

    $dt->add_duration($dur);

    is($dt->gct_sign(),          "", 'gct_sign');
    is($dt->gct_cycle(),        198, 'gct_cycle');
    is($dt->gct_day(),           15, 'gct_day');
    is($dt->gct_segment(),       05, 'gct_segment');
}

{
    my $dt = DateTime::Format::TauStation->parse_datetime('198.15/03:973 GCT');

    my $dur = DateTime::Format::TauStation->parse_duration('D-/02:001 GCT');

    is($dur->gct_sign(),          "-", 'duration gct_sign');
    is($dur->gct_cycles(),        000, 'duration gct_cycles');
    is($dur->gct_days(),           00, 'duration gct_days');
    is($dur->gct_segments(),       02, 'duration gct_segments');

    $dt->add_duration($dur);

    is($dt->gct_sign(),          "", 'gct_sign');
    is($dt->gct_cycle(),        198, 'gct_cycle');
    is($dt->gct_day(),           15, 'gct_day');
    is($dt->gct_segment(),       01, 'gct_segment');
}
