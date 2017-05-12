use strict;
use warnings;
use utf8;
use Test::More;
use Devel::CodeObserver;
use Data::Dumper;

subtest 'return true value', sub {
    my ($retval, $out) = Devel::CodeObserver->new->call(sub { 2 });
    is $retval, 2;
};

subtest 'return undef value', sub {
    my ($retval, $out) = Devel::CodeObserver->new->call(sub { undef });
    is $retval, undef;
};

subtest 'expect data', sub {
    my @p;
    my ($retval, $result) = Devel::CodeObserver->new->call(sub { expect(\@p)->to_be(['a']) });
    ok !$retval;
    my $out = $result->dump_pairs;
    ok @$out > 0;
    like $out->[0][0], qr/expect/;
    diag Dumper($out);
};

done_testing;

{
    package E;
    sub to_be { 0 }
}

sub expect { bless +{}, E:: }
