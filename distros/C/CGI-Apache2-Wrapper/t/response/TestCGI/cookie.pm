package TestCGI::cookie;

use strict;
use warnings FATAL => 'all';

use CGI::Apache2::Wrapper ();
use CGI::Apache2::Wrapper::Cookie ();

use Apache2::Const -compile => qw(OK);
use Apache2::RequestRec;
use Apache2::RequestIO;

sub handler {
    my $r = shift;
    my $cgi = CGI::Apache2::Wrapper->new($r);
    my $req = $cgi->req;
    my %cookies = CGI::Apache2::Wrapper::Cookie->fetch($r);

    my $test = $cgi->param('test');
    my $key  = $cgi->param('key');

    if ($test eq 'cookies') {

        if ($key eq 'first') {
            my $value = $cgi->cookie('one');
            $r->print($value);
        }
        elsif ($key eq 'two') {
            my $value = $cgi->cookie('two');
            $r->print($value);
        }
        else {
            my @names = $cgi->cookie();
            $r->print(join ' ', map { $_ } sort @names);
        }
    }
    elsif ($test eq 'overload') {
        $r->print($cookies{one});
    }
    elsif ($key and $cookies{$key}) {
        if ($test eq "bake") {
            $cookies{$key}->bake($r);
        }
        elsif ($test eq "bake2") {
            $cookies{$key}->bake2($r);
        }
        $r->print($cookies{$key}->value);
    }
    else {
        my @expires;
        @expires = ("expires", $cgi->param('expires'))
	  if $cgi->param('expires');
        my $cookie = CGI::Apache2::Wrapper::Cookie->new($r, 
							name => "foo",
							value => $test,
							domain => "example.com",
							path => "/quux",
							@expires);
        if ($test eq "bake" or $test eq "") {
            $cookie->bake($req);
        }
        $r->print($cookie->value);
    }


    return Apache2::Const::OK;
}

1;

__END__
