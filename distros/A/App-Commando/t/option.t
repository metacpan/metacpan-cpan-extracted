use strict;
use warnings;

use Test::More;

BEGIN { use_ok('App::Commando::Option'); }

my $option = App::Commando::Option->new;
isa_ok $option, 'App::Commando::Option', '$option';

$option = App::Commando::Option->new('foo', '-f', '--foo', '=s', 'Foo');
is $option->config_key, 'foo', 'Config key is correct';
is $option->description, 'Foo', 'Description is correct';
is $option->long, '--foo', 'Long switch is correct';
is $option->short, '-f', 'Short switch is correct';
is $option->spec, '=s', 'Spec is correct';

my $option2 = App::Commando::Option->new('foo', 'Foo', '=s', '--foo', '-f');
is_deeply $option2, $option, 'Order of constructor arguments doesn\'t matter';

is $option->for_get_options, 'f|foo=s', 'for_get_options is correct';

is_deeply $option->switches, [ '-f', '--foo' ], 'switches are correct';
is $option->formatted_switches, '        -f, --foo        ',
    'formatted_switches are correct';

subtest 'Long switch only' => sub {
    my $option = App::Commando::Option->new('foo', '--foo', '=s', 'Foo');
    is_deeply $option->switches, [ '', '--foo' ],
        'Short switch is an empty string';
    is $option->formatted_switches, '            --foo        ',
        'formatted_switches are correct';
};

subtest 'Short switch only' => sub {
    my $option = App::Commando::Option->new('foo', '-f', '=s', 'Foo');
    is_deeply $option->switches, [ '-f', '' ],
        'Long switch is an empty string';
    is $option->formatted_switches, '        -f               ',
        'formatted_switches are correct';
};

is $option->as_string, '        -f, --foo          Foo',
    'as_string returns the expected string';

done_testing;
