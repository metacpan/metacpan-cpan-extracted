
use strict;
use Test;

plan tests => 2;

{
    my $r = eval 'use CPAN::CachingProxy; 1';
    warn " [load fail]: $@\n" unless $r;
    ok($r, 1);
}

{
    my $r = eval 'my $n = CPAN::CachingProxy->new(mirrors=>["blah"]); 1';
    warn " [new fail]: $@\n" unless $r;
    ok($r, 1);
}
