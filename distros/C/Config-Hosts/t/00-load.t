#!perl

use Test::More tests => 4;

BEGIN {
    use_ok( 'Config::Hosts' ) || print "Bail out!
";
}

diag( "Testing Config::Hosts $Config::Hosts::VERSION, Perl $], $^X" );

my $hosts = Config::Hosts->new();

isa_ok($hosts, 'Config::Hosts');
$hosts = Config::Hosts->new(file => '/tmp/hjhj');
isa_ok($hosts, 'Config::Hosts');
is($hosts->{_file}, '/tmp/hjhj', "using custom file");
