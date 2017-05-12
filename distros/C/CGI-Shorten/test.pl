# $Id: test.pl,v 1.2 2003/09/09 07:23:48 cvspub Exp $
use Test::More qw(no_plan);
ok(1);
BEGIN{ use_ok 'CGI::Shorten'; }

$sh = new CGI::Shorten(db_prefix => ".shorten_");
ok(ref($sh));
foreach (map{'http://'.$_.'.com'} A..Z,a..z){
    $sh->shorten($_);
}
like($sh->lengthen('http://127.0.0.1/shorten.pl?aa'), qr'a\.com');
like($sh->lengthen('http://127.0.0.1/shorten.pl?a'), qr'A');
like($sh->redirect('http://127.0.0.1/shorten.pl?aa'), qr'302 Moved');
like($sh->redirect('http://127.0.0.1/shorten.pl?aaa'), qr'404');
undef $sh;
ok(!ref($sh));



$sh = new CGI::Shorten(db_prefix => ".shorten_");
ok(ref($sh));
foreach (map{'http://'.$_.'.com'} 0..9){
    $sh->shorten($_);
}
like($sh->lengthen('http://127.0.0.1/shorten.pl?ba'), qr'0\.com');

undef $sh;
ok(!ref($sh));




unlink glob(".shorten_*");
ok(!-e".shorten__lndb");
