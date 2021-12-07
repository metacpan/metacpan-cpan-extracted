#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::DefaultValue;
use Data::Sah::DefaultValueCommon;
use Data::Sah::DefaultValueJS;
use Nodejs::Util qw(get_nodejs_path);

sub test_no_dupes {
    my $rules = shift;
    my %seen;
    for (@$rules) {
        if ($seen{$_->{name}}++) {
            ok 0, "Duplicate rule in rules: $_->{name}";
        }
    }
}

subtest "rule args" => sub {
    my $c_pl;

    $c_pl = Data::Sah::DefaultValue::gen_default_value_code(
        default_value_rules=>[["Str::repeat", {str=>"foo",n=>3}]]);
    is_deeply($c_pl->(undef), "foofoofoo");

    subtest js => sub {
        plan skip_all => 'node.js is not available' unless get_nodejs_path();
        my $c_js = Data::Sah::DefaultValueJS::gen_default_value_code(
            default_value_rules=>[["Str::repeat", {str=>"foo",n=>3}]]);
        is_deeply($c_js->(undef), "foofoofoo");
    };
};

subtest "opt:default_value_rules" => sub {
    subtest "unknown name -> dies" => sub {
        dies_ok {
            Data::Sah::DefaultValueCommon::get_default_value_rules(
                compiler=>"perl",
                default_value_rules => ['Str::FoO'],
            );
        };
    };
    subtest "unknown name in !name -> ignored" => sub {
        my $rules = Data::Sah::DefaultValueCommon::get_default_value_rules(
            compiler=>"perl",
            default_value_rules => ['!Str::FoO'],
        );
        test_no_dupes($rules);
        #ok(@$rules);
        ok(!(grep { $_->{name} eq 'Str::FoO' } @$rules));
    };

    subtest "basics" => sub {
        my $rules = Data::Sah::DefaultValueCommon::get_default_value_rules(
            compiler=>"perl",
            default_value_rules => ['Math::random','!R3'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(grep { $_->{name} eq 'Math::random' } @$rules);
        ok(!(grep { $_->{name} eq 'R3' } @$rules));
    };
};

DONE_TESTING:
done_testing;
