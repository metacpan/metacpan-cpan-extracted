use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::DynamicValidator qw/validator/;
use aliased qw/Data::DynamicValidator::Path/;

subtest 'escaped-in-to_string' => sub {
    my $ps = '/`a/b`/`c/d`/0';
    my $p1 = Path->new($ps);
    is "$p1", $ps;
};

subtest 'escape-in-path-object' => sub {
    my $p1 = Path->new('/v1:`a/b`/v2:`c/d`/v3:0');
    is_deeply $p1->components, ['','a/b', 'c/d', 0];
    my $p2 = Path->new('/v1:`a///b/`/v2:`c/d`/v3:0');
    is_deeply $p2->components, ['','a///b/', 'c/d', 0];
};

subtest 'simple-escaping' => sub {
    my $data = {
        'a/b' => { 'c/d' => [5] }
    };
    my $p1 = validator($data)->_expand_routes('/v1:*/v2:*/v3:0')->[0];
    is $p1->value($data), 5, 'got 5';
    my $p2 = validator($data)->_expand_routes('/v1:`a/b`/v2:`c/d`/v3:0')->[0];
    is $p2->value($data), 5, 'got 5';
    is "$p1", "$p2";
};

subtest 'escape-in-expression' => sub {
    my $paths = validator([10,20,30])->_expand_routes('/`*[index == 2]`');
    is @$paths, 1;
    is $paths->[0], "/2";
};

done_testing;
