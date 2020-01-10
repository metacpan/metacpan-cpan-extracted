use utf8;
use strict;
use warnings;

use Test::More 1.302 tests => 3;
use Test::More::UTF8;

use lib './lib';
BEGIN{
    use_ok 'Data::Pokemon::Go::Pokemon', qw(@List);                 # 1
}

my $pg = new_ok( 'Data::Pokemon::Go::Pokemon');                     # 2
my @list = ();
foreach my $name (@Data::Pokemon::Go::Pokemon::List){
    $pg->name($name);
    next unless $pg->hasForms();
    push @list, $name;
}

subtest 'Forms' => sub {                                            # 3
    plan tests => scalar @list;
    my $all = $Data::Pokemon::Go::Pokemon::All;
    foreach my $fullname (@list) {
        warn "unvalid names or forms" unless $pg->exists($fullname);
        $pg->name($fullname);
        my $name = $pg->get_Pokemon_name( $all->{$fullname}, 'ja' );
        my $form = $pg->hasForms();
        ok 1, "$form Form for $name is ok";
        note $fullname . "\[${\$pg->id}\]は" . join( '／', @{$pg->types()} ) . "タイプ";
    }
};

done_testing();
