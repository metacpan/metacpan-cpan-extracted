#!perl -T

use strict;
use warnings;
use Carp;
use Test::More tests => 5;
use App::Validation::Automation::Unix;
use English qw(-no_match_vars);


my $obj = App::Validation::Automation::Unix->new();

ok( defined $obj, 'App::Validation::Automation::Unix Object Creation');

#Check what all App::Validation::Automation can do
can_ok( $obj, 'connect');
can_ok( $obj, 'validate_process');
can_ok( $obj, 'validate_mountpoint');
can_ok( $obj, 'change_unix_pwd');

