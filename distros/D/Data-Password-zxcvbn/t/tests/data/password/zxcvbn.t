#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use JSON::MaybeXS;
use Scalar::Util qw(looks_like_number);
use Test::MyVisitor;
use Data::Password::zxcvbn qw(password_strength);

my $to_json = Test::MyVisitor->new(
    object => sub { $_[0]->visit_ref($_[1]->TO_JSON) },
);
my $no_log10 = Test::MyVisitor->new(
    hash => sub { my %ret = %{$_}; delete $ret{guesses_log10}; \%ret },
);
my $lax_numbers = Test::MyVisitor->new(
    hash_value => sub {
        my ($visitor,$value,$key) = @_;
        return $visitor->visit($value) if ref($value);
        return $value unless looks_like_number($value);
        # 1% rounding
        my $tolerance = abs(int($value/100)) || 1;
        return num($value,$tolerance);
    },
);

sub to_data { $no_log10->visit($to_json->visit(shift)) }
sub to_test { $lax_numbers->visit($no_log10->visit(shift)) }

my $cases = decode_json(do {
    open my $fh,'<','t/data/regression-data.json';
    local $/;
    <$fh>;
});

plan tests => scalar @{$cases};

for my $case (@{$cases}) {
    my $got = to_data(password_strength($case->{password}));
    my $test = to_test($case->{strength});
    cmp_deeply(
        $got,
        $test,
        "checking $case->{password}",
    ) or explain $got,explain $test;
}

done_testing;
