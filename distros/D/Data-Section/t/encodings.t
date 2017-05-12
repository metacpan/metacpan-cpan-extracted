use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::FailWarnings;
use Encode;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $unicode = "\x{263a}";
my $latin1  = "Ricardo Juli\x{E1}n Besteiro Signes";

my %test_data = (
    Unicode_nopragma => $unicode,
    Unicode_pragma   => $unicode,
    Latin1           => $latin1,
);

for my $class ( keys %test_data ) {
    eval "require $class; 1" or die $@; ## no critic
    chomp( my $got = ${ $class->section_data("a") } );
    is( $got, $test_data{$class}, "$class: section_data is text, not bytes" );
}

done_testing;
