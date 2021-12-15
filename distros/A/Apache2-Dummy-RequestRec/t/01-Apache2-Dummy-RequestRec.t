#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use Test::More;
use Test::Needs;
use Test::Output;
use Data::Printer;
use Data::Compare;

my $tno = 1;

use_ok('Apache2::Dummy::RequestRec');
$tno++;

my $r = Apache2::Dummy::RequestRec->new('bla=blu');
ok($r->args() eq 'bla=blu', "args()" . $r->args);
$tno++;

$r->args('blo=bli');
ok($r->args eq 'blo=bli', "args(\$new_args)");
$tno++;

ok($r->ap_auth_type eq 'Basic', "ap_auth_type() == 'Basic'");
$tno++;

ok($r->assbackwards == 1, "assbackwards() == 1");
$tno++;

ok($r->handler eq 'perl-script', "handler() == 'perl-script'");
$tno++;

ok($r->hostname eq 'localhost', "hostname() == 'localhost'");
$tno++;

ok($r->proto_num == 1001, "prot_num() == 1001");
$tno++;

(my $mtime = DateTime->from_epoch(epoch => $r->mtime)) =~ s/[T\s].*$//;
(my $now = DateTime->now) =~ s/[T\s].*$//;
ok($mtime eq $now, "mtime()");
$tno++;

ok($r->method_number eq 2, "method_number(POST) == 2");
$tno++;

$r = Apache2::Dummy::RequestRec->new(
    {
        args       => 'bla=blu',
        'method'   => 'GET',
        headers_in => { 'Content-Language' => 'EN' }
    }
                                    );

ok($r->args eq 'bla=blu', "args()");
$tno++;

ok($r->method_number eq 0, "method_number(GET) == 0");
$tno++;

ok($r->content_languages eq 'EN', "content-languages() == 'EN'");
$tno++;

$r->content_type("text/html");
ok($r->content_type eq 'text/html', "content-type('text/html') == 'text/html'");
$tno++;

my $headers_out =
{
    'Content-Language' => "EN",
    'Content-Type'     => "text/html"
};
my %ho = %{$r->err_headers_out()};
ok(Compare(\%ho, $headers_out), "(err_)headers_out()");
$tno++;

my $msg =
'Content-Language: EN
Content-Type: text/html
Content-Length: 31

{"key1":"value1","key2:value2"}';

stdout_is(sub {$r->print('{"key1":"value1","key2:value2"}')}, $msg, "print()");

$r = Apache2::Dummy::RequestRec->new(
    {
        args => 'bla=blu&blu=bla',
        body => 'ble=blo&bli=bli',
    }
                                    );

ok($r->body eq 'ble=blo&bli=bli', "body()");
$tno++;

$r->useragent_ip('127.0.0.1');
ok($r->useragent_ip eq '127.0.0.1', "AUTOLOAD");
$tno++;

done_testing($tno);
