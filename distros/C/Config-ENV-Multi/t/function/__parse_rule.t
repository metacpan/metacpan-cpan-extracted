use strict;
use Test::More;
use Test::Clear;
use Config::ENV::Multi;

case '{rule}' => { rule => '{ENV}_{REGION}' }, sub {
    my $rules = Config::ENV::Multi::__parse_rule($_[0]->{rule});
    is_deeply $rules, [qw/ENV REGION/];
};

case '{rule}' => { rule => '{ENV}%%{REGION}' }, sub {
    my $rules = Config::ENV::Multi::__parse_rule($_[0]->{rule});
    is_deeply $rules, [qw/ENV REGION/];
};

case '{rule}' => { rule => '{ENV}_{REGION}_{ENV}' }, sub {
    my $rules = Config::ENV::Multi::__parse_rule($_[0]->{rule});
    is_deeply $rules, [qw/ENV REGION ENV/];
};

done_testing;
