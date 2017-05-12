#!perl -T

use strict;
use Test::More tests => 1;

use Acme::PlayCode;

my $from = <<'FROM';
                    if ($object_type eq 'topic'
                    and $reply_to == $comments[0]->{comment_id} ); 
FROM

my $to = <<'TO';
                    if ('topic' eq $object_type
                    and $reply_to == $comments[0]->{comment_id} ); 
TO

my $app = Acme::PlayCode->new();
$app->load_plugin('ExchangeCondition');
my $ret = $app->play($from);

is($ret, $to, '1 ok');
