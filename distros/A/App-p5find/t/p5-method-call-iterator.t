#!/usr/bin/env perl
use v5.18;
use warnings;
use Test2::V0;
use PPI::Document;
use App::p5find qw( p5_method_call_iterator );

subtest p5_method_call_iterator => sub {
    my $code = ' $obj->compute && $obj->$meh; ';
    my $doc = PPI::Document->new( \$code );

    my $methods = 0;
    my @method_names;
    my $iter = p5_method_call_iterator($doc);
    while (my $tok = $iter->()) {
        my $name = $tok->snext_sibling;
        push @method_names, $name;
        $methods++;
    }
    is $methods, 2, "2 method calls";
    is \@method_names, [ 'compute', '$meh' ];
};

subtest 'no method calls' => sub {
    my $code = 'sub foo_and_bar { $o->{foo} && $o->{bar} }';
    my $doc = PPI::Document->new( \$code );

    my $methods = 0;
    my $iter = p5_method_call_iterator($doc);
    while (my $tok = $iter->()) {
        $methods++;
    }

    is $methods, 0;
};

done_testing;
