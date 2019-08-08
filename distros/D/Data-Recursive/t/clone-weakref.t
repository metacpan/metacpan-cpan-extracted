use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Data::Recursive qw/clone lclone/;
use Scalar::Util qw/weaken isweak/;

subtest 'lclone makes all weak refs strong refs' => sub {
    my $data = [1,2,3];
    my $val = {data => $data};
    weaken($val->{data});
    my $copy = lclone($val);
    cmp_deeply($copy, {data => [1,2,3]});
    isnt $copy->{data}, $val->{data};
    ok !isweak($copy->{data});
};

subtest 'weakref to CV/IO' => sub {
    my $sub = sub { return 123};
    my $io = *STDERR{IO};
    my $val = [$sub, $io];
    weaken($val->[0]); weaken($val->[1]);
    my $copy = clone($val);
    cmp_deeply $copy, [$sub, $io], "data ok";
    ok isweak($copy->[0]) && isweak($copy->[1]), "ref copied as weak";
};

subtest 'alone weak ref dissapears' => sub {
    my $data = [1,2,3];
    my $val = {data => $data};
    weaken($val->{data});
    my $copy = clone($val);
    my @a = ({}) x 200;
    is $copy->{data}, undef;
};

subtest 'cloning strong before weak' => sub {
    my $data = {a => 1};
    my $val = [$data, $data];
    weaken($val->[1]);
    my $copy = clone($val);
    cmp_deeply $copy, $val, "data ok";
    ok isweak($copy->[1]), "ref copied as weak";
};

subtest 'cloning weak before strong' => sub {
    my $data = {a => 1};
    my $val = [$data, $data];
    weaken($val->[0]);
    my $copy = clone($val);
    cmp_deeply $copy, $val, "data ok";
    ok isweak($copy->[0]), "ref copied as weak";
};

done_testing();
