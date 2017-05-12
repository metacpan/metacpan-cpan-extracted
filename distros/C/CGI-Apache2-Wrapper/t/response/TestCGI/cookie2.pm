package TestCGI::cookie2;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw(OK);

use CGI::Apache2::Wrapper ();

sub handler {
    my $r = shift;
    my $cgi = CGI::Apache2::Wrapper->new($r);
    plan $r, tests => 6;

    {
        my $cookie = $cgi->cookie(name => 'n', value => undef);
        ok t_cmp(
                 $cookie,
                 undef,
                 "value => undef return undef not a cookie"
		);
    }

    {
        my $cookie = $cgi->cookie(name => 'n');
        ok t_cmp(
                 $cookie,
                 undef,
                 "no value attribute specified"
		);
    }

    {
        my $cookie = $cgi->cookie(name => 'n', value => '');
        ok t_cmp(
                 $cookie,
                 "n=; path=/",
                 "'' returns a valid cookie object"
		);
    }

    {
        my $cookie = $cgi->cookie(name => 'n', value => []);
        ok t_cmp(
                 $cookie,
                 "n=; path=/",
                 "[] returns a valid cookie object"
		);
    }

    {
        my $cookie = $cgi->cookie(name => 'n', value => {});
        ok t_cmp(
                 $cookie,
                 "n=; path=/",
                 "{} returns a valid cookie object"
		);
    }

    {
        my $cookie = $cgi->cookie(name => 'n', value => 'qwert');
        ok t_cmp(
                 $cookie,
                 "n=qwert; path=/",
                 "value => qwert returns a valid cookie object"
		);
    }

    return Apache2::Const::OK;
}

1;

__END__
