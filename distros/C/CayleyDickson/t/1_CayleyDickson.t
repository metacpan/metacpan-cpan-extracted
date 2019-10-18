#!/usr/bin/perl -wT
use Test::More tests => 9;

use 5.010;
use warnings;
use strict;

use CayleyDickson;
use Data::Dumper;

use constant DEBUG   => 0;
use constant VERBOSE => 0;
use constant PRECISION => 0.0001;

use constant PACKAGE => 'CayleyDickson';
use constant METHODS => qw(new add subtract multiply divide conjugate inverse norm tensor);

sub d {
   my %a = @_;
   my @k = keys %a;
   my $d = Data::Dumper->new([@a{@k}],[@k]); $d->Purity(1)->Deepcopy(1); print $d->Dump;
}

diag "\n###\n### class method tests ...\n###\n\n" if VERBOSE;
foreach my $method (METHODS) {
   can_ok(PACKAGE, $method);
}


1;

__END__

