use strict;
use warnings;
use lib qw(blib);
use Test::More tests => 12;

BEGIN {
    use_ok 'App::Mowyw::Datasource';
    use_ok 'App::Mowyw::Datasource::Array';
}

my $a = eval {
    App::Mowyw::Datasource->new({
            type    => 'Array',
            source  => [qw(foo bar baz)],
    });
};

print $@ if $@;
ok !$@, 'No errors while creating App::Mowyw::Datasource::Array instance';

ok !$a->is_exhausted(),        'fresh iterator not exhausted';
is $a->get(),       'foo',      'First item correct';

$a->next();
ok !$a->is_exhausted(),        'iterator not exhausted';
is $a->get(),       'bar',      'Second item correct';

$a->next();
ok !$a->is_exhausted(),        'iterator not exhausted';
is $a->get(),       'baz',      'Third item correct';

$a->next();
ok $a->is_exhausted,            'Iterator now exhausted';

eval {
    App::Mowyw::Datasource->new({
            type    => 'Array',
    });
};

ok $@,                          'new() dies when "source" argument is missing';

eval {
    App::Mowyw::Datasource->new({
            type    => 'Array',
            source  => { a => 'b' },
    });
};

ok $@,                          'new() dies on non-array source';
