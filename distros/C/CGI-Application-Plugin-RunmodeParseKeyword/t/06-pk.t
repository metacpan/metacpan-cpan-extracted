
use strict;
use warnings;
use Test::More;
use utf8;

package MyAppPK1 {
    BEGIN { $ENV{'CGI_APP_RETURN_ONLY'} = 1 }
    use base 'CGI::Application';
    use CGI::Application::Plugin::RunmodeParseKeyword;
    use Attribute::Handlers;
    use utf8;

    sub Authz  : ATTR(CODE,BEGIN) {
        my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;
    }

    sub cgiapp_prerun
    {
        shift->header_type('none')
    }


    errormode oops ($error) {
        return "Oh no! $error";
    }
    startmode start () {
        return "Hello world!";
    }
    runmode foo ($id = 1, $name = "person") {
        return "Welcome, $name, to foo #$id!";
    }
    runmode bar :Authz(me, you) {
        return "ok bro";
    }
    runmode quirk {
        die "ach!";
    }

}

use CGI;

my $cgi = CGI->new('rm=foo&id=2&name=karel');
my $app = MyAppPK1->new(QUERY => $cgi);
my $out = $app->run;
like $out, qr/#2/;

$out = $app->foo(4, "rhesa");
like $out, qr/#4/;
like $out, qr/rhesa/;

$out = $app->foo(3);
like $out, qr/#3/;

my $app2 = MyAppPK1->new;
$out = $app2->foo();
like $out, qr/#1/;
like $out, qr/person/;

$out = $app2->bar;
like $out, qr/ok bro/;

$cgi = CGI->new('rm=quirk&id=2&name=karel');
$app = MyAppPK1->new(QUERY => $cgi);
$out = $app->run;
like $out, qr/Oh no! ach/;

done_testing;

__END__

