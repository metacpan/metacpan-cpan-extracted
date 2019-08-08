use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Data::Recursive 'lclone';

subtest 'number IV' => sub {
    my $val = 10;
    my $copy = lclone($val);
    $val++;
    is($val, 11);
    is($copy, 10);
};

subtest 'number NV' => sub {
    my $val = 0.333;
    my $copy = lclone($val);
    $val++;
    is($val, 1.333);
    is($copy, 0.333);
};

subtest 'string' => sub {
    my $val = "abcd";
    my $copy = lclone($val);
    substr($val, 0, 2, '');
    is($val, 'cd');
    is($copy, 'abcd');
};

subtest 'string + number IV' => sub {
    my $val = 10;
    my $copy = "$val";
    $copy = lclone($val);
    $val++;
    is($val, 11);
    is($copy, 10);
};

subtest 'string + number NV' => sub {
    my $val = 0.333;
    my $copy = "$val";
    $copy = lclone($val);
    $val++;
    is($val, 1.333);
    is($copy, 0.333);
};

subtest 'reference to scalar' => sub {
    my $tmp = 10;
    my $val = \$tmp;
    my $copy = lclone($val);
    $$val++;
    is($$val, 11);
    is($$copy, 10);
};

subtest 'reference to reference' => sub {
    my $tmp = 10;
    my $val = \\$tmp;
    my $copy = lclone($val);
    $$$val++;
    is($$$val, 11);
    is($$$copy, 10);
};

subtest 'reference to array' => sub {
    my $val = [1,2,3];
    my $copy = lclone($val);
    shift @$val;
    cmp_deeply($copy, [1,2,3]);
};

subtest 'reference to hash' => sub {
    my $val = {a => 1, b => 2};
    my $copy = lclone($val);
    $val->{b} = 3;
    cmp_deeply($copy, {a => 1, b => 2});
};

subtest 'object' => sub {
    #package main;
    my $val = bless {a => 1, b => 2}, 'MySimple';
    my $copy = lclone($val);
    $val->{b} = 3;
    cmp_deeply($copy, bless {a => 1, b => 2}, 'MySimple');
    is(ref $copy, 'MySimple');
};

subtest 'mixed' => sub {
    my $val = {a => 1, b => [1,2,3], c => bless {a => 1, b => 2}, 'MySimple'};
    my $copy = lclone($val);
    shift @{$val->{b}};
    cmp_deeply($copy, {a => 1, b => [1,2,3], c => bless {a => 1, b => 2}, 'MySimple'});
};

subtest 'code reference' => sub {
    my $val = sub { return 25 };
    my $copy = lclone($val);
    is(ref($copy), 'CODE');
    is($val->(), $copy->());
};

subtest 'regexp' => sub {
    my $val = qr/asdf/;
    my $copy = lclone($val);
    is(ref($copy), 'Regexp');
    ok("123asdf321" =~ $copy);
};

subtest 'typeglob' => sub {
    sub suka { return 10 }
    my $val = *suka;
    my $copy = lclone($val);
    is(ref(\$copy), 'GLOB');
    is($copy->(), 10);
};

subtest 'IO' => sub {
    my $val = *STDERR{IO};
    my $copy = lclone($val);
    is(ref($copy), 'IO::File');
    is(fileno($copy), fileno($val));
};

done_testing();
