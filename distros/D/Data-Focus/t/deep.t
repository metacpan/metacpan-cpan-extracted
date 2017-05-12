use strict;
use warnings FATAL => "all";
use Test::More;
use Scalar::Util qw(refaddr);
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;

sub lens {
    return Data::Focus::Lens::HashArray::Index->new(index => shift);
}

sub level {
    my ($level) = @_;
    return map { lens(1) } 1..$level;
}

my $target = [0, [1, [2, [3, [4]]]]];

subtest "new() method" => sub {
    is(Data::Focus->new(target => $target)->get()->[0], 0, "no focus. level 0");
    is(Data::Focus->new(target => $target, lens => lens(1))->get()->[0], 1, "1 lens. level 1");
    is(Data::Focus->new(target => $target, lens => [level(2)])->get()->[0], 2, "2 lenses. level 2");
};

subtest "focus() function" => sub {
    is focus($target, level(3))->get()->[0], 3, "level 3 OK";
};

subtest "into() method" => sub {
    my $level1 = focus($target, level(1));
    my $level3 = $level1->into(level(2));
    isa_ok $level3, "Data::Focus";
    is $level3->get()->[0], 3, "go into() level 3.";
    is $level1->get()->[0], 1, "level1 is unchanged";
    isnt refaddr($level3), refaddr($level1), "into() method returns a new Data::Focus instance";
    
    my $another_level3 = $level3->into();
    isnt refaddr($another_level3), refaddr($level3), "into() method always returns a new Data::Focus instance";
    is $another_level3->get()->[0], 3, "level 3 OK";
};

subtest "focus deeper into zero focal points" => sub {
    my $deep_focus = focus($target)->into(lens(0), lens(1), lens(1), lens(1));
    is $deep_focus->get, undef, "zero focal points return undef from get()";
    is_deeply [$deep_focus->list], [], "zero focal points return a empty list from list()";
    my $ret = $deep_focus->set("xxx");
    is_deeply $ret, [0,[1,[2,[3,[4]]]]], "target is not modified by set() because there's no focal point";
};

done_testing;
