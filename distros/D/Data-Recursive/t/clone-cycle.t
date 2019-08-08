use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Recursive qw/clone lclone TRACK_REFS/;

subtest 'same references' => sub {
    subtest 'lclone - all are different copies' => sub {
        my $tmp = [1,2,3];
        my $val = {a => $tmp, b => $tmp};
        my $copy = lclone($val);
        shift @{$val->{a}};
        cmp_deeply($copy, {a => [1,2,3], b => [1,2,3]});
        ok($copy->{a} ne $copy->{b});
        shift @{$copy->{a}};
        cmp_deeply($copy, {a => [2,3], b => [1,2,3]});
    };
    
    subtest 'clone - all are references to the same data' => sub {
        my $tmp = [1,2,3];
        my $val = {a => $tmp, b => $tmp};
        my $copy = clone($val);
        shift @{$val->{a}};
        cmp_deeply($copy, {a => [1,2,3], b => [1,2,3]});
        is($copy->{a}, $copy->{b});
        shift @{$copy->{a}};
        cmp_deeply($copy, {a => [2,3], b => [2,3]});
    };
};

subtest 'cycled structure' => sub {
    my $val = bless {a => 1, b => [1,2,3]}, 'MySimple';
    $val->{c} = $val;
    $val = [$val];
    subtest 'lclone' => sub {
        my $exc_re = qr/max depth .+ reached/;
        throws_ok { lclone($val) } $exc_re;
        throws_ok { clone($val, 0) } $exc_re;
    };
    subtest 'clone' => sub {
        my $copy = clone($val);
        my $tmp = shift @{$val->[0]{b}};
        cmp_deeply($copy->[0]{c}{c}{c}{c}{c}{c}{c}{c}{b}, [1,2,3]);
        unshift @{$val->[0]{b}}, $tmp;
        $copy = clone($val, TRACK_REFS); # should behave like without flags
        shift @{$val->[0]{b}};
        cmp_deeply($copy->[0]{c}{c}{c}{c}{c}{c}{c}{c}{b}, [1,2,3]);
    };
};

done_testing();
