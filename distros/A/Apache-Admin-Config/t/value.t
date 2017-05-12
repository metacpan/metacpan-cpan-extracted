use strict;
use Test;
plan test => 40;

use Apache::Admin::Config;
ok(1);

my $conf = new Apache::Admin::Config;


foreach my $type (qw(section directive comment))
{
    my $item = $conf->add($type, test=>"test");
    ok(defined $item);
    ok($item eq 'test');
    ok($item ne 'tset');
    $item->value(40);
    ok($item == 40);
    ok($item != 20);
    $item->value('test');
    ok($item->value eq 'test');
    my $item2 = $conf->select($type, -value=>'test');
    ok(defined $item2);
    ok($item2 eq 'test');
    ok($item2->value eq 'test');
    $item2->set_value('test_change');
    ok($item2 eq 'test_change');
    ok($item2->value eq 'test_change');
    ok($item eq 'test_change');
    ok($item->value eq 'test_change');
}
