#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce;
use Data::Sah::CoerceCommon;
use Data::Sah::CoerceJS;
use Nodejs::Util qw(get_nodejs_path);
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

sub test_no_dupes {
    my $rules = shift;
    my %seen;
    for (@$rules) {
        if ($seen{$_->{name}}++) {
            ok 0, "Duplicate rule in rules: $_->{name}";
        }
    }
}

# XXX check no duplicates in $rules
subtest "opt:coerce_rules" => sub {
    subtest "unknown name -> dies" => sub {
        dies_ok {
            Data::Sah::CoerceCommon::get_coerce_rules(
                compiler=>"perl", type=>"date", coerce_to=>'float(epoch)', data_term=>'$data',
                coerce_rules => ['FoO'],
            );
        };
    };
    subtest "unknown name in !name -> ignored" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>'float(epoch)', data_term=>'$data',
            coerce_rules => ['!FoO'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(!(grep { $_->{name} eq 'FoO' } @$rules));
    };

    subtest "default (date)" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>'float(epoch)', data_term=>'$data',
        );
        test_no_dupes($rules);
        ok(@$rules);
    };
    subtest "default (bool)" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"bool", data_term=>'$data',
        );
        test_no_dupes($rules);
        #ok(@$rules); # this dies happens to not include any enabled-by-default rule for bool
        ok(!(grep { $_->{name} eq 'str' } @$rules));
    };

    subtest "all" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"bool", data_term=>'$data',
            coerce_rules=> ['.'],
        );
        ok(@$rules) or diag explain $rules;
        ok((grep { $_->{name} eq 'str' } @$rules));
    };

    subtest "none" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!.'],
        );
        test_no_dupes($rules);
        is(@$rules, 0);
    };

    subtest "only R" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!.', 'float_epoch'],
        );
        test_no_dupes($rules);
        is(@$rules, 1);
        is($rules->[0]{name}, 'float_epoch');
    };
    subtest "only /^R/" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!.', '^float_'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(grep { $_->{name} eq 'float_epoch' } @$rules);
    };

    subtest "default + R" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"bool", data_term=>'$data',
            coerce_rules => ['str'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(grep { $_->{name} eq 'str' } @$rules);
    };
    subtest "default + /^R/" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"bool", data_term=>'$data',
            coerce_rules => ['^str'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(grep { $_->{name} eq 'str' } @$rules);
    };

    subtest "default - R" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!float_epoch'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(!grep { $_->{name} eq 'float_epoch' } @$rules);
    };
    subtest "default - /^R/" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!^float_'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        ok(!grep { $_->{name} eq 'float_epoch' } @$rules);
    };
};

subtest "opt:return_type=sah+val" => sub {
    subtest "perl" => sub {
        test_needs "Time::Duration::Parse::AsHash";

        my $c_pl = Data::Sah::Coerce::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"str+val");
        is_deeply($c_pl->("1h"), ["str_human", 3600]);
        is_deeply($c_pl->("foo"), [undef, "foo"]);
    };

    subtest "js" => sub {
        plan skip_all => "node.js not available" unless get_nodejs_path();

        my $c_js = Data::Sah::CoerceJS::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"str+val");
        my $res;
        is_deeply($c_js->(3600), ["float_secs", 3600]);
        is_deeply($c_js->("foo"), [undef, "foo"]);
    };
};

done_testing;
