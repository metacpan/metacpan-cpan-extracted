use v5.14;
use strict;
use warnings;

use Test::More;
use App::Greple::xlate::llm::gpt5;
use App::Greple::xlate::llm::gpt6;

{
    package Local::EngineOptions;
    sub new { bless {}, shift }
    sub setopt {
        my($self, %options) = @_;
        @{$self}{keys %options} = values %options;
    }
}

subtest 'initialize selects each engine independently' => sub {
    my $gpt5 = Local::EngineOptions->new;
    my $gpt6 = Local::EngineOptions->new;
    App::Greple::xlate::llm::gpt5::initialize($gpt5, []);
    App::Greple::xlate::llm::gpt6::initialize($gpt6, []);
    is($gpt5->{default}, '-Mxlate --xlate-engine=gpt5', 'gpt5 selection');
    is($gpt6->{default}, '-Mxlate --xlate-engine=gpt6', 'gpt6 selection');
};

subtest 'shared entry points keep engine state separate' => sub {
    my @calls;
    no warnings 'redefine';
    local *App::Greple::xlate::llm::xlate_with = sub {
        my($param, @input) = @_;
        push @calls, { %$param };
        return @input;
    };
    local $App::Greple::xlate::llm::gpt5::lang_from = 'JA';
    local $App::Greple::xlate::llm::gpt5::lang_to = 'EN-US';
    local $App::Greple::xlate::llm::gpt6::lang_from = 'EN-US';
    local $App::Greple::xlate::llm::gpt6::lang_to = 'JA';

    my @out = App::Greple::xlate::llm::gpt5::xlate('one', 'two');
    is_deeply(\@out, ['one', 'two'], 'arguments and return values forwarded');
    App::Greple::xlate::llm::gpt6::xlate('three');
    $App::Greple::xlate::llm::gpt5::lang_to = 'FR';
    App::Greple::xlate::llm::gpt5::xlate('four');

    is_deeply([map { [@{$_}{qw(model lang_from lang_to)}] } @calls], [
        ['gpt-5.6-terra', 'JA', 'EN-US'],
        ['gpt-6-astra', 'EN-US', 'JA'],
        ['gpt-5.6-terra', 'JA', 'FR'],
    ], 'configuration is isolated and languages are read at call time');
    is_deeply($calls[0]{options},
              [[reasoning_effort => 'low'], [verbosity => 'low']],
              'gpt5 retains verbosity');
    is_deeply($calls[1]{options}, [[reasoning_effort => 'low']],
              'gpt6 retains its own options');
    is($calls[0]{prompt}, $calls[1]{prompt}, 'translation prompt is shared');
    is_deeply([map { $_->{max} } @calls], [3000, 3000, 3000],
              'shared batch limit');
};

done_testing;
