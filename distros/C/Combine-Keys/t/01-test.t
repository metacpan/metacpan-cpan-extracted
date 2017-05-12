use Test::More;

use Combine::Keys qw/ckeys combine_keys/;

my $combined = ckeys([{ one => 'two' }, { three => 'four' }, { five => 'six' }]);

is_deeply($combined, [qw/five one three/]); 

my $combined = ckeys([{ 123 => 'two' }, { 456 => 'four' }, { 789 => 'six' }]);

is_deeply($combined, [qw/123 456 789/]);

my @combined = combine_keys({ 123 => 'two' }, { 456 => 'four' }, { 789 => 'six' });

is_deeply(\@combined, [qw/123 456 789/]);


my $args = {
    a => [qw/a b c/],
    b => {
        d => 'e',
    }
};

my $args2 = {
    a => [qw/a b c/],
    d => {
        d => 'e',
    },
    e => 'sad',
};

my $args3 = {
    a => [qw/a b c/],
    b => {
        d => 'e',
    },
    e => 'sad',
};

my $keysss = ckeys([$args, $args2, $args3]);
is_deeply($keysss, [qw/a b d e/]);
is_deeply([combine_keys($args, $args2, $args3)], [qw/a b d e/]);

done_testing();
