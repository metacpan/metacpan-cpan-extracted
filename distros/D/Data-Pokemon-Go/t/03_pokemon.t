use utf8;
use strict;
use warnings;

use Test::More 1.302 tests => 3;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDERR,                   ":utf8";

use lib './lib';

use_ok 'Data::Pokemon::Go::Pokemon';                                    # 1
my $pg = new_ok 'Data::Pokemon::Go::Pokemon';                           # 2

subtest 'Recommend' => sub {                                            # 3
    plan tests => scalar @Data::Pokemon::Go::Pokemon::All;
    foreach my $name (@Data::Pokemon::Go::Pokemon::All) {
        next unless $pg->exists($name);
        $pg->name($name);
        my $id = $pg->id;
        note $pg->name . "($id)は" . join( '／', @{$pg->types()} ) . "タイプ";
        note 'こうかばつぐんは ', join ',', $pg->effective();
        note 'いまひとつは ', join ',', $pg->invalid();
        note '有利なタイプは ', join ',', $pg->advantage();
        note '不利なタイプは ', join ',', $pg->disadvantage();
        note 'オススメのタイプは ', join ',', $pg->recommended();

        my $count = 0;
        foreach my $type ( $pg->recommended() ){
            $count += grep{ $_ eq $type } @Data::Pokemon::Go::Role::Types::All;
        }

        is $count > 0, 1, "recommended types for $name is ok";
    }
};

done_testing();
