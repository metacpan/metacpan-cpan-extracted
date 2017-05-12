#!perl -T

use strict;
use Test::More tests => 1;

use Acme::PlayCode;

my $from = <<'FROM';
print "a " . "print 'a' . 'b'" . "c\n";
my $a = {
    b => '/forum/' . $object->forum_id . "/$object_id",
};
FROM

my $to = <<'TO';
print "a ", "print 'a' . 'b'", "c\n";
my $a = {
    b => '/forum/' . $object->forum_id . "/$object_id",
};
TO

my $app = Acme::PlayCode->new();
$app->load_plugin('PrintComma');
my $ret = $app->play($from);

is($ret, $to, '1 ok');
