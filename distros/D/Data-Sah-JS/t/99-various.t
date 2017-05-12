#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah qw();
use Data::Sah::JS qw();
use Nodejs::Util qw(get_nodejs_path);
use Test::Exception;
use Test::More 0.98;
#use Test::Warn;

#my $sah = Data::Sah->new;
#my $plc = $sah->get_compiler("perl");

my $node_path = get_nodejs_path();

subtest "[2014-01-03 ] req_keys clash between \$_ and \$dt" => sub {
    # req_keys generates this code: ... sub {!exists($dt\->{\$_})} ... When $dt
    # is '$_' there will be clash, so we need to assign $dt to another variable
    # first.
    my $sch = [array => of => [hash => req_keys => ["a"]]];
  COMPILER:
    for my $c ('perl', 'js') {
        my $v;
        if ($c eq 'js') {
            if (!$node_path) {
                diag "node.js not available, skipping JS test";
                next COMPILER;
            }
            $v = Data::Sah::JS::gen_validator($sch);
        } else {
            $v = Data::Sah::gen_validator($sch);
        }
        subtest $c => sub {
            lives_and { ok( $v->([]      )) } "[] validates";
            lives_and { ok(!$v->(["a"]   )) } "['a'] doesn't validate";
            lives_and { ok(!$v->([{}]    )) } "[{}] doesn't validate";
            lives_and { ok(!$v->([{b=>1}])) } "[{b=>1}] doesn't validate";
            lives_and { ok( $v->([{a=>1}])) } "[{a=>1}] validates";
        };
    }
};

done_testing();
