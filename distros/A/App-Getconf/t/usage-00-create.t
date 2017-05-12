#!perl -T
#
# create App::Getconf objects
#

use strict;
use warnings;
use Test::More tests => 5;
use App::Getconf qw{:schema};

#-----------------------------------------------------------------------------

my $conf = eval { new App::Getconf() };
is(ref $conf, 'App::Getconf', 'constructor');

my $view = eval { $conf->getopt };
is(ref $view, 'App::Getconf::View', 'view creation');

my $opt = eval { opt {} };
isnt($opt, undef, 'create a single option');

my $opt_group = eval { schema(foo => 'bar', baz => undef) };
is(ref $opt_group, 'HASH', 'create option group');
is(keys(%$opt_group), 2, 'option group has exactly 2 keys');

#-----------------------------------------------------------------------------
# vim:ft=perl
