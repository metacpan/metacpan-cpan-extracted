#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use_ok('App::yajg');

my %elements = (
    'HASH' => {
        '{0}'   => '0',
        '{}'    => '',
        '{\.}'  => '.',
        '{{}}'  => '{}',
        '{abc}' => 'abc',
        '{123}' => '123',
    },
    'SLICE' => {
        '[1]'                        => [1],
        '[0]'                        => [0],
        '[1,,,2,3]'                  => [1,2,3],
        '[ +5 ]'                     => [5],
        '[  12 , -12, +87, 0, -0, ]' => [12, -12, 87, 0, 0],
    },
    'REGEXP' => {
        '/a/b(c)/' => qr/a\/b(c)/u,
        '/\./'     => qr/./u,
        '////'     => qr/\/\//u,
        '//'       => qr//u,
        '/0/'      => qr/0/u,
    },
    'UNKNOWN' => {
        '\{\}'    => '{}',
        '\[\]'    => '[]',
        '\/\/'    => '//',
        '0'       => '0',
        '0\.0'    => '0.0',
        'abc/\./' => 'abc/./',
        '\.'      => '.',
    },
);

subtest 'each element parsing' => sub {
    for my $type (sort keys %elements) {
        for (sort keys %{ $elements{$type} }) {
            my @parsed = App::yajg::parse_select($_);
            is scalar @parsed, 1, "'$_' parsed only one element";
            is $parsed[0]->{'type'}, $type, "'$_' has type '$type'";
            my $got      = $parsed[0]->{'val'};
            my $expected = $elements{$type}->{$_};
            is_deeply $got, $expected, "'$_' got is what has been expected";
        }
    }
    done_testing();
};

my %mixed_elements;
for my $i (1 .. 100) {
    my @key;
    my @val;
    for my $type (
        sort { substr($a, $i % length($a), 1) cmp substr($b, $i % length($b), 1) }
        keys %elements
      ) {
        my @e = keys %{ $elements{$type} };
        my $e = $e[$i % @e];
        push @key, $e;
        push @val, { type => $type, val => $elements{$type}->{$e} };
    }
    $mixed_elements{ join '.' => @key } = \@val;
}

subtest 'mixed elements parsing' => sub {
    for (sort keys %mixed_elements) {
        my $expected = $mixed_elements{$_};
        my $got      = [App::yajg::parse_select($_)];
        is_deeply $got, $expected, "'$_' got is what has been expected";
    }
    done_testing();
};

my @bad_slices = (qw/[asdf] [] [0\.0]/, '[0, 2, 4, -2, +ff]', '[      ]');
subtest 'bad slices' => sub {
    for (@bad_slices) {
        my $res = eval { local $SIG{__WARN__} = sub { }; App::yajg::parse_select($_) };
        ok not($res), "parsing fails for '$_'";
        like $@, qr/not a number or list of numbers/, "got correct error msg for '$_'";
    }
};

my @bad_regexp = qw' /[0-5/ /(dddd/';
subtest 'bad regexp' => sub {
    for (@bad_regexp) {
        my $res = eval { local $SIG{__WARN__} = sub { }; App::yajg::parse_select($_) };
        ok not($res), "parsing fails for '$_'";
        like $@, qr/regex/, "got correct error msg for '$_'";
    }
};

subtest 'ignore case' => sub {
    my %elements_ic = (
        'HASH_IC' => {
            '{abc}' => 'abc',
            '{aBc}' => 'abc',
            '{ABC}' => 'abc',
        },
        'REGEXP' => {
            '/a/b(c)/' => qr/(?i)a\/b(c)/u,
            '/\./'     => qr/(?i)./u,
            '/0/'      => qr/(?i)0/u,
        },
        'UNKNOWN_IC' => {
            'abc' => 'abc',
            'aBc' => 'abc',
            'ABC' => 'abc',
        },
    );
    for my $type (sort keys %elements_ic) {
        for (sort keys %{ $elements_ic{$type} }) {
            my @parsed = App::yajg::parse_select($_, { ignore_case => 1 });
            is scalar @parsed, 1, "'$_' parsed only one element";
            is $parsed[0]->{'type'}, $type, "'$_' has type '$type'";
            my $got      = $parsed[0]->{'val'};
            my $expected = $elements_ic{$type}->{$_};
            is_deeply $got, $expected, "'$_' got is what has been expected";
        }
    }
    done_testing();
};

done_testing();

