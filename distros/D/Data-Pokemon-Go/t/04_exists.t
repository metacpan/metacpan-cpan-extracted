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
        is $pg->exists($name), 1, "$name exists in data";
        $pg->name($name);
        note $pg->name() . "\[${\$pg->id}\]は" . join( '／', @{$pg->types()} ) . "タイプ";
    }
};

done_testing();
