use utf8;
use strict;
use warnings;

use Test::More 1.302 tests => 3;
use Test::More::UTF8;

use lib './lib';

BEGIN{
    use_ok( 'Data::Pokemon::Go::Pokemon', qw( @List @Types ) );          # 1
}
my $pg = new_ok 'Data::Pokemon::Go::Pokemon';                           # 2
my @list = @Data::Pokemon::Go::Pokemon::List;
my @types = @Data::Pokemon::Go::Pokemon::Types;

subtest 'Recommend' => sub {                                            # 3
    plan tests => scalar @list;
    foreach my $name (@list) {
        next unless $pg->exists($name);
        $pg->name($name);
        note $name . "\[${\$pg->id}\]は" . join( '／', @{$pg->types()} ) . "タイプ";
        note 'こうかばつぐんは ', join ',', $pg->effective();
        note 'いまひとつは ', join ',', $pg->invalid();
        note '有利なタイプは ', join ',', $pg->advantage();
        note '不利なタイプは ', join ',', $pg->disadvantage();
        note 'オススメのタイプは ', join ',', $pg->recommended();

        my $count = 0;
        foreach my $type ( $pg->recommended() ){
            $count += grep{ $_ eq $type } @types;
        }

        is $count > 0, 1, "recommended types for $name is ok";
    }
};

done_testing();
