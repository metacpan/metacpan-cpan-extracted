use strict;
use warnings;
use YAML::XS ();
use Test::More tests => 2;

use_ok 'Clustericious::Config';

my %methods = map { $_ => 1 } grep { Clustericious::Config->can($_) } keys %Clustericious::Config::;

## we seem to get this once $VERSION is added to the .pm
delete $methods{$_} for qw( VERSION );

## deprecated;
## to be removed January 31 2016
delete $methods{$_} for qw( dump_as_yaml set_singleton );

## eventually I'd like to move/remove these as well.

note YAML::XS::Dump([keys %methods]);

is_deeply [sort keys %methods], [sort qw( new AUTOLOAD DESTROY )], 'the big three';
