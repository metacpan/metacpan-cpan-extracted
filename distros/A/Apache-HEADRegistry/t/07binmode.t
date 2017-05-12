use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 12, (have_lwp && 
                   have_cgi && 
                   have_module(qw(MIME::Base64 mod_perl.c)));

my $image = MIME::Base64::decode_base64(do { local $/; <DATA> });

# mod_cgi
{
  my $url = '/cgi-bin/binmode.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi GET binmode.cgi returns 200');

    ok t_cmp($image,
             $response->content,
             'mod_cgi GET binmode.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi HEAD binmode.cgi returns 200');

    ok t_cmp('',
             $response->content,
             'mod_cgi HEAD binmode.cgi returns no content');
  }
}

# Apache::Registry
{
  my $url = '/perl-bin/binmode.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'Registry GET binmode.cgi returns 200');

    ok t_cmp($image,
             $response->content,
             'Registry GET binmode.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'Registry HEAD binmode.cgi returns 200');

    ok t_cmp($image,
             $response->content,
             'Registry HEAD binmode.cgi returns content (bad)');
  }
}

# HEADRegistry
{
  my $url = '/head-bin/binmode.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'HEADRegistry GET binmode.cgi returns 200');

    ok t_cmp($image,
             $response->content,
             'HEADRegistry GET binmode.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'HEADRegistry HEAD binmode.cgi returns 200');

    ok t_cmp('',
             $response->content,
             'HEADRegistry HEAD binmode.cgi returns no content');
  }
}

__END__
R0lGODlhFAAWAOMAAP////8zM8z//8zMzJmZmWZmZmYAADMzMwCZzACZMwAzZgAAAAAAAAAAAAAA
AAAAACH+TlRoaXMgYXJ0IGlzIGluIHRoZSBwdWJsaWMgZG9tYWluLiBLZXZpbiBIdWdoZXMsIGtl
dmluaEBlaXQuY29tLCBTZXB0ZW1iZXIgMTk5NQAh+QQBAAACACwAAAAAFAAWAAAEkPDISae4WBzA
u99Hdm1eSYYZWXYqOgJBLAcDoNrYNssGsBy/4GsX6y2OyMWQ2OMQngSlBjZLWBM1AFSqkyU4A2tW
ywUMYt/wlTSIvgYGA/Zq3QwU7mmHvh4g8GUsfAUHCH95NwMHV4SGh4EdihOOjy8rZpSVeiV+mYCW
HncKo6Sfm5cliAdQrK1PQBlJsrNSEQA7
