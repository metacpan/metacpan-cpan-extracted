use Test::Most  qw/defer_plan/;

my $builder = Test::More->builder;
my $module = 'Dancer::Plugin::ElasticSearch';

#========= Basics =========
use_ok( $module );

#========== Fin ===========
all_done;


