#!perl -w

use strict;
use warnings;

use Test::Most tests => 6;
use Test::Needs 'CGI::Untaint';

BEGIN {
	use_ok('CGI::Info');
}

CGI::Untaint->import();

$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&i=123';

my $i = new_ok('CGI::Info');
my %p = %{$i->params()};
ok($p{i} == 123);
ok($i->as_string() eq 'foo=bar; fred=wilma; i=123');

my $u = CGI::Untaint->new(%p);

cmp_ok($u->extract(-as_integer => 'i'), '==', 123, 'as_integer works');
ok($u->extract(-as_printable => 'foo') eq 'bar');
