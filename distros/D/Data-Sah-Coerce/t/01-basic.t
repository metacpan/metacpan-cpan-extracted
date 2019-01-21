#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Coerce;
use Data::Sah::CoerceCommon;
use Data::Sah::CoerceJS;
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

    subtest "default + R" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"bool", data_term=>'$data',
            coerce_rules => ['str'],
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
        #diag explain $rules;
        ok(!grep { $_->{name} eq 'float_epoch' } @$rules);
    };
    subtest "default - R1 - R2" => sub {
        my $rules = Data::Sah::CoerceCommon::get_coerce_rules(
            compiler=>"perl", type=>"date", coerce_to=>"float(epoch)", data_term=>'$data',
            coerce_rules=>['!str_iso8601', '!obj_DateTime'],
        );
        test_no_dupes($rules);
        ok(@$rules);
        #diag explain $rules;
        ok(!grep { $_->{name} eq 'str_iso8601' } @$rules);
        ok(!grep { $_->{name} eq 'obj_DateTime' } @$rules);
    };
};

subtest "opt:return_type=status+val" => sub {
    subtest "perl" => sub {
        test_needs "Time::Duration::Parse::AsHash";

        my $c_pl = Data::Sah::Coerce::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"status+val");
        is_deeply($c_pl->("1h"), [1, 3600]);
        is_deeply($c_pl->("foo"), [undef, "foo"]);
    };

    subtest "js" => sub {
        plan skip_all => "node.js not available" unless get_nodejs_path();

        my $c_js = Data::Sah::CoerceJS::gen_coercer(type=>"duration", coerce_to=>"float(secs)", return_type=>"status+val");
        my $res;

        $res = $c_js->(3600);
        #diag explain $res;
        ok($res->[0]);
        is($res->[1], 3600);

        $res = $c_js->("foo");
        ok(!$res->[0]);
        is($res->[1], "foo");
    };
};

subtest "opt:return_type=status+err+val" => sub {
    subtest "perl" => sub {
        test_needs "DateTime";

        my $c_pl = Data::Sah::Coerce::gen_coercer(type=>"date", coerce_to=>"DateTime", return_type=>"status+err+val");
        my $res;

        $res = $c_pl->(1527889633);
        #diag explain $res;
        $res->[2] = $res->[2]->epoch;
        is_deeply($res, [1, undef, 1527889633]);

        $res = $c_pl->([]);
        is_deeply($res, [undef, undef, []]);

        $res = $c_pl->("2018-06-32");
        is_deeply($res, [1, "Invalid date/time: Day '32' out of range 1..30", undef]);
    };

    subtest "js" => sub {
        plan skip_all => "node.js not available" unless get_nodejs_path();

        my $c_js = Data::Sah::CoerceJS::gen_coercer(type=>"date", return_type=>"status+err+val");
        my $res;

        $res = $c_js->(1527889633);
        #diag explain $res;
        ok($res->[0]);
        ok(!$res->[1]);
        is($res->[2], "2018-06-01T21:47:13.000Z");

        $res = $c_js->([]);
        #diag explain $res;
        ok(!$res->[0]);
        ok(!$res->[1]);
        is_deeply($res->[2], []);

        $res = $c_js->("2018-06-32");
        #diag explain $res;
        ok($res->[0]);
        is($res->[1], "Invalid date");
        is_deeply($res->[2], undef);
    };
};

done_testing;
