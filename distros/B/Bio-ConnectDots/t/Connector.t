#!/usr/bin/perl
use strict;
no warnings;
use lib qw(./t blib/lib);
use Test::More qw(no_plan);
use Data::Dumper;


use Bio::ConnectDots::Connector;
use Bio::ConnectDots::ConnectorSet;
use Bio::ConnectDots::Dot;
use Bio::ConnectDots::DotSet;

# test constructor
my $connector = new Bio::ConnectDots::Connector;
is(ref($connector), 'Bio::ConnectDots::Connector', 'check constructor');

# test name
$connector->{connectorset} = new Bio::ConnectDots::ConnectorSet(-name=>'testSet');
is($connector->name(), 'testSet', 'check name()');

# test put & get_dots
my $dot1 = new Bio::ConnectDots::Dot(-id=>'dot1');
$connector->put('happydot', $dot1);
my $ret_dot = $connector->get_dots('happydot')->[0];
is($ret_dot->{id}, $dot1->{id}, 'check put(label, dot) and get_dots(label)');

# test labels()
my $first_label = $connector->labels()->[0];
is($first_label, 'happydot', 'check labels()');

# test put_dots()
my $connector = new Bio::ConnectDots::Connector;
$dot1 = new Bio::ConnectDots::Dot(-id=>'dot1');
my $dot2 =  new Bio::ConnectDots::Dot(-id=>'dot2');
my %dots; $dots{'happydot'} = 'dot1'; $dots{'saddot'} = 'dot2';
my $dot_set = new Bio::ConnectDots::DotSet;
$dot_set->id2dot('dot1',$dot1); $dot_set->id2dot('dot2',$dot2);

$connector->{connectorset} = new Bio::ConnectDots::ConnectorSet(-name=>'testSet');
$connector->{connectorset}->{label2dotset}->{'happydot'} = $dot_set;
$connector->{connectorset}->{label2dotset}->{'saddot'} = $dot_set;
$connector->put_dots(%dots);

my @labels = $connector->labels(); @labels = sort @labels;
is($labels[0] eq 'happydot' && $labels[1] eq 'saddot', 1, 'check that put_dots(%dots) adds dots to Connector');

is($dot1->connectors()->[0], $connector, 'check that put_dots(%dots) adds this Connector to the dots');


1;