use lib 't';
use lib '.';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 2;
}
use Data::Stag qw(:all);
use strict;

my $x = Data::Stag->parsestr("(set(component(part_of(c2))))");
print $x->xml;

my $p = $x->get('component/part_of');
ok($p);
print $p->xml;
ok(!$p->sget_c2);
