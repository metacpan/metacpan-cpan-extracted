# $Id: 01-key.t 32 2008-08-25 17:18:34Z johntrammell $
# $URL: https://algorithm-voting.googlecode.com/svn/trunk/t/sortition/01-key.t $

use strict;
use warnings;
use Test::More 'no_plan';
use Algorithm::Voting::Sortition;

# make sure $sortition->n() is working

{
    my @c = ('a' .. 'j');
    my $s = Algorithm::Voting::Sortition->new(candidates => \@c);
    is($s->n, scalar @c);
}

{
    my @c = ('a' .. 'j');
    my $s = Algorithm::Voting::Sortition->new(candidates => \@c, n => 0);
    is($s->n, scalar @c);
}

