#!perl -w

use strict;

use Benchmark qw(:all);

use Data::Clone;

BEGIN{
    package Object;
    sub new {
        my $class = shift;
        return bless { @_ }, $class;
    }
    package DC;
    use Data::Clone qw(clone);
    our @ISA = qw(Object);
}

my %args = (
    foo => 42,
    inc => { %INC },
);

my $o  = DC->new(%args);

print "Method vs. Function:\n";
cmpthese -1 => {
    'method' => sub{
        my $x = $o->clone;
    },
    'function' => sub{
        my $x = clone($o);
    },
};
