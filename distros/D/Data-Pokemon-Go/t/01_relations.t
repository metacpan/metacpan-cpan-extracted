use utf8;
use strict;
use warnings;

use Test::More 1.302 tests => 21;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDERR,                   ":utf8";

use lib './lib';

use_ok 'Data::Pokemon::Go::Relation';                                   # 1
my @types = @Data::Pokemon::Go::Role::Types::All;
new_ok 'Data::Pokemon::Go::Relation', [ types => 'ノーマル' ];            # 2
new_ok 'Data::Pokemon::Go::Relation', [ types => [qw( みず こおり )] ];   # 3

foreach my $type1 (@types) {
    subtest $type1 => sub {
        plan tests => 18;
        foreach my $type2 (@types) {
            my( $pg, $name );
            if( $type1 eq $type2 ){
                $pg = Data::Pokemon::Go::Relation->new( types => $type1 );
                $name =  "${\$type1}タイプ";
            }else{
                $pg = Data::Pokemon::Go::Relation->new( types => [ $type1, $type2 ] );
                $name = join( '／', $type1, $type2 ) . "タイプ";
            }
            note "${\$name}の";
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

}

};

done_testing();
