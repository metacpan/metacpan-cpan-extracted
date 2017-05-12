#! /usr/bin/env perl

use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use Test::More;
use Test::Deep;
use Data::DPath 'dpath';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

BEGIN {
        if ($] < 5.010) {
                plan skip_all => "Perl 5.010 required for the smartmatch overloaded tests. This is ".$];
        } else {
                plan tests => 5;
        }
}

use_ok( 'Data::DPath' );

my $datacontent='';
{
        local $/;
        open F, "<", "t/bigdata.dump" or die;
        $datacontent = <F>;
        close F;
}
my $VAR1;
eval $datacontent;
my $data = $VAR1;

my $res;

$res = $data ~~ dpath('/report');
is($res->[0]{reportgroup_testrun_id}, 30862, "simple dpath" );

$res = $data ~~ dpath('//data//benchmark[ value eq "call_simple"]/../mean/..');
cmp_bag($res, [
               {
                'glibc'              => 'glibc, 2.4',
                'count'              => '150',
                'language_series'    => 'arch_barcelona',
                'standard_deviation' => '0.0164822946672',
                'language_binary'    => '/opt/artemis/slbench/python/arch_barcelona/2.7/bin/python',
                'release'            => '2.6.30.10-105.2.23.fc11.x86_64',
                'operating_system'   => 'Linux',
                'hostname'           => 'foo.dept.lhm.com',
                'mean'               => '0.592707689603',
                'median'             => '0.58355140686',
                'architecture'       => '64bit',
                'number_CPUs'        => '16',
                'benchmark'          => 'call_simple',
                'machine'            => 'x86_64'
               }
              ]
        , "very complicated dpath" );

$datacontent='';
{
        local $/;
        open F, "<", "t/bigdata2.dump" or die;
        $datacontent = <F>;
        close F;
}
eval $datacontent;
$data = $VAR1;

$res = $data ~~ dpath('/report');
is($res->[0]{reportgroup_testrun_id}, 30862, "simple dpath 2" );

$res = $data ~~ dpath('//data//benchmark[ value eq "xcall_simple"]/../mean/..');
cmp_bag($res, [
               {
                'glibc'              => 'xglibc, 2.4',
                'count'              => 'x150',
                'language_series'    => 'xarch_barcelona',
                'standard_deviation' => 'x0.0164822946672',
                'language_binary'    => 'x/opt/artemis/slbench/python/arch_barcelona/2.7/bin/python',
                'release'            => 'x2.6.30.10-105.2.23.fc11.x86_64',
                'operating_system'   => 'xLinux',
                'hostname'           => 'xfoo.dept.lhm.com',
                'mean'               => 'x0.592707689603',
                'median'             => 'x0.58355140686',
                'architecture'       => 'x64bit',
                'number_CPUs'        => 'x16',
                'benchmark'          => 'xcall_simple',
                'machine'            => 'xx86_64'
               }
              ]
        , "dpath on complex blessed ARRAYs" );
