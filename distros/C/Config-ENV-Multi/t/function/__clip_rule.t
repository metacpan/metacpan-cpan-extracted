use strict;
use Test::More;
use Test::Clear;
use Config::ENV::Multi;

my $method = \&Config::ENV::Multi::__clip_rule;

case '{template} => {rule}' => {
    template => '{ENV}_{REGION}',
    rule     => 'prod_jp',
}, sub {
    my $rules = $method->($_[0]->{template}, $_[0]->{rule});
    is_deeply $rules, [qw/prod jp/];
};

case '{template} => {rule}' => {
    template => '{ENV}%%{REGION}',
    rule     => 'prod%%jp',
}, sub {
    my $rules = $method->($_[0]->{template}, $_[0]->{rule});
    is_deeply $rules, [qw/prod jp/];
};

case '{template} => {rule}' => {
    template => '{ENV}_{REGION}_{ENV}',
    rule     => 'prod_jp_prod',
}, sub {
    my $rules = $method->($_[0]->{template}, $_[0]->{rule});
    is_deeply $rules, [qw/prod jp prod/];
};

done_testing;
