use strict;
use warnings;
use Test::More;

# API parity: every variant must implement the core contract. Catches silent
# drift when a method is added to one variant but forgotten in others.

my @variants = qw(I16 I16A I16S I32 I32A I32S IA II IS SA SI16 SI32 SI SS);

my @common_methods = qw(
    new put get remove exists size max_size ttl lru_skip capacity
    keys values items each iter_reset drain pop shift
    clone from_hash merge swap clear reserve purge
    persist put_ttl get_or_set
);

my %integer_value_methods = map { $_ => 1 } qw(I16 I32 II SI16 SI32 SI);
my @counter_methods = qw(incr decr incr_by cas);

my %string_value_methods = map { $_ => 1 } qw(IS I16S I32S SS);
my @string_value_extra = qw(get_direct);

# Freeze/thaw is only available on variants whose values can be serialized
# as plain bytes. SV* variants (SA/IA/I16A/I32A) hold arbitrary Perl SVs
# and intentionally don't serialize.
my %serializable = map { $_ => 1 } qw(I16 I16S I32 I32S II IS SI SI16 SI32 SS);
my @serialize_methods = qw(freeze thaw);

for my $v (@variants) {
    my $class = "Data::HashMap::$v";
    eval "require $class; 1" or do {
        fail "$class: require failed: $@";
        next;
    };

    for my $m (@common_methods) {
        ok $class->can($m), "$v: has $m";
    }
    if ($integer_value_methods{$v}) {
        ok $class->can($_), "$v (int-value): has $_" for @counter_methods;
    }
    if ($string_value_methods{$v}) {
        ok $class->can($_), "$v (string-value): has $_" for @string_value_extra;
    }
    if ($serializable{$v}) {
        ok $class->can($_), "$v (serializable): has $_" for @serialize_methods;
    }
}

done_testing;
