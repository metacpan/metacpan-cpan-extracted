use Test::More;
use Test::Exception;
use Date::Period::Human;
use DateTime::Format::MySQL;

my @tests =(
    [ '2010-03-05 10:15:00', 'net precies',                    'just now',               'gerade eben' ],
    [ '2010-03-05 10:14:56', 'net precies',                    'just now',               'gerade eben' ],
    [ '2010-03-05 10:14:54', 'minder dan een minuut geleden',  'less than a minute ago', 'vor weniger als einer Minute' ],
    [ '2010-03-05 10:14:00', '1 minuut geleden',               '1 minute ago',           'vor 1 Minute' ],
    [ '2010-03-05 10:13:53', '1 minuut geleden',               '1 minute ago',           'vor 1 Minute' ],
    [ '2010-03-05 10:13:00', '2 minuten geleden',              '2 minutes ago',          'vor 2 Minuten' ],
    [ '2010-03-05 10:10:00', '5 minuten geleden',              '5 minutes ago',          'vor 5 Minuten' ],
    [ '2010-03-05 09:00:00', '1 uur 15 minuten geleden',       '1 hour 15 minutes ago',  'vor 1 Stunden 15 Minuten' ],
    [ '2010-03-05 04:00:00', '6 uur 15 minuten geleden',       '6 hour 15 minutes ago',  'vor 6 Stunden 15 Minuten' ],
    [ '2010-03-05 04:20:00', '5 uur 55 minuten geleden',       '5 hour 55 minutes ago',  'vor 5 Stunden 55 Minuten' ],
    [ '2010-03-05 10:00:00', '15 minuten geleden',             '15 minutes ago',         'vor 15 Minuten' ],
    [ '2010-03-04 10:15:00', 'gisteren om 10:15',              'yesterday at 10:15',     'Gestern um 10:15' ],
    [ '2010-03-01 10:00:00', '4 dagen geleden',                '4 days ago',             'vor 4 Tagen' ],
    [ '2010-02-26 10:00:00', 'een week geleden',               'a week ago',             'vor einer Woche' ],
    [ '2010-02-05 10:00:00', '4 weken geleden',              '4 weeks ago',            'vor 4 Wochen' ],
    [ '2009-03-05 10:00:00', 'een jaar geleden',               'a year ago',             'vor einem Jahr' ],
);

my $dt = DateTime::Format::MySQL->new();

my $d = Date::Period::Human->new({lang => 'nl', today_and_now => [2010,3,5,10,15,0]});

for (@tests) {
    my $date = $dt->parse_datetime($_->[0]);
    is($d->human_readable($date), $_->[1]);
}

$d = Date::Period::Human->new({lang => 'en', today_and_now => [2010,3,5,10,15,0]});

for (@tests) {
    my $date = $dt->parse_datetime($_->[0]);
    is($d->human_readable($date), $_->[2]);
}


$d = Date::Period::Human->new({lang => 'de', today_and_now => [2010,3,5,10,15,0]});

for (@tests) {
    my $date = $dt->parse_datetime($_->[0]);
    is($d->human_readable($date), $_->[3]);
}


done_testing();

