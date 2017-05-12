package __test;

use strict;
use lib qw(blib/lib);
use Acme::Void;

sub new {
    return bless \my $self, shift;
}

sub run {
    my $self = shift;
    $self->void;
}

package main;

use strict;

print "1..1\n";

my $obj = __test->new;
eval {
    $obj->run;
};
print "not " if $@;
printf "ok %d\n", 1;

