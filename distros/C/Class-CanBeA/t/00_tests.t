#!/usr/bin/perl -w

my $loaded;

use strict;
use warnings;

use Class::CanBeA;

use lib 't/lib';
use Class::CanBeA::Parent;
use Class::CanBeA::Son;
use Class::CanBeA::Daughter;
use Class::CanBeA::Grandchild;

BEGIN { $| = 1; print "1..3\n"; }
END { print "not ok 1 load module\n" unless $loaded; }

$loaded=1;
my $test = 0;
print "ok ".(++$test)." load module\n";

my %subclasses = map { ($_, 1) } @{Class::CanBeA::subclasses('Class::CanBeA')};

print 'not ' if(
    (
        grep { !$subclasses{$_} }
        map { 'Class::CanBeA::'.$_ }
        qw(Parent Son Daughter Grandchild)
    ) || (
        keys %subclasses != 4
    )
);
print 'ok '.(++$test)." correct subclasses for something with no parents\n";

%subclasses = map { ($_, 1) } @{Class::CanBeA::subclasses('Class::CanBeA::Son')};
print 'not ' if(
    !$subclasses{'Class::CanBeA::Grandchild'} || keys %subclasses != 1
);
print 'ok '.(++$test)." correct subclasses for something with a parent\n";
