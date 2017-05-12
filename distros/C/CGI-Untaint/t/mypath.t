#!/usr/bin/perl -w

use strict;
use Test::More;
use CGI;
use CGI::Untaint;

plan tests => 9;

package My::Untaint::prime;

use base 'CGI::Untaint::object';

sub _untaint_re { qr/^(\d)$/ }
sub is_valid    { (1 x shift->value) !~ /^1?$|^(11+?)\1+$/ }

package main;

my $q = CGI->new(
	{
		ok       => 6,
		not      => 10,
		prime    => 7,
		notprime => 8,
	}
);

ok(my $data = CGI::Untaint->new({ INCLUDE_PATH => "My::Untaint" }, $q->Vars),
	"Can create the handler, with INCLUDE_PATH");

is($data->extract("-as_like_prime" => 'ok'), 6, '6 passes "like" test');
is $data->error, '', "With no errors";

ok(!$data->extract("-as_like_prime" => 'not'), '10 fails (not single digit)');
is($data->error, "not (10) does not untaint with default pattern", " - with suitable error");

is($data->extract("-as_prime" => 'prime'), 7, '7 passes prime test');
is $data->error, '', "And we have no errors";

ok(!$data->extract("-as_prime" => 'notprime'), '8 fails prime test');
is($data->error, 'notprime (8) does not pass the is_valid() check', " - with suitable error");

