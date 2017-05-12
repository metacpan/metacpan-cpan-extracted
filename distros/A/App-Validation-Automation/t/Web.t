#!perl -T

use strict;
use warnings;
use Carp;
use Test::More tests => 7;
use App::Validation::Automation::Web;
use English qw(-no_match_vars);

my $obj = App::Validation::Automation::Web->new();

ok( defined $obj, 'App::Validation::Automation::Web Object Creation');

#Check what all App::Validation::Automation::Web can do
can_ok($obj, 'validate_url');
can_ok($obj, 'dnsrr');
can_ok($obj, 'lb');

#Check methods for functionality - App::Validation::Automation Features
is($obj->validate_url('http://cpan.org'), 1, 'Testing validate_url functionality');
is($obj->dnsrr('http://cpan.org',1,1), 1, 'Testing dnsrr functionality');
is($obj->lb('http://cpan.org',1,0), 1, 'Testing lb functionality');

