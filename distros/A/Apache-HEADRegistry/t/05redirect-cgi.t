use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 12, 
     todo  => [12], (have_lwp &&
                     have_cgi &&
                     have_module('mod_perl.c'));

local $Apache::TestRequest::RedirectOK = 0;

# mod_cgi
{
  my $url = '/cgi-bin/redirect-cgi.cgi';

  {
    my $response = GET $url;

    ok t_cmp(302,
             $response->code,
             'mod_cgi GET redirect-cgi.cgi returns 302');

    ok t_cmp('',
             $response->content,
             'mod_cgi GET redirect-cgi.cgi returns as expected');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(302,
             $response->code,
             'mod_cgi HEAD redirect-cgi.cgi returns 302');

    ok t_cmp('',
             $response->content,
             'mod_cgi HEAD redirect-cgi.cgi returns no content');
  }
}

# Apache::Registry
{
  my $url = '/perl-bin/redirect-cgi.cgi';

  {
    my $response = GET $url;

    ok t_cmp(302,
             $response->code,
             'Registry GET redirect-cgi.cgi returns 302');

    ok t_cmp(qr/The document has moved/,
             $response->content,
             'Registry GET redirect-cgi.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(302,
             $response->code,
             'Registry HEAD redirect-cgi.cgi returns 302');

    ok t_cmp(qr/The document has moved/,
             $response->content,
             'Registry HEAD redirect-cgi.cgi returns content (bad)');
  }
}

# HEADRegistry
{
  my $url = '/head-bin/redirect-cgi.cgi';

  {
    my $response = GET $url;

    ok t_cmp(302,
             $response->code,
             'HEADRegistry GET redirect-cgi.cgi returns 302');

    ok t_cmp(qr/The document has moved/,
             $response->content,
             'HEADRegistry GET redirect-cgi.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(302,
             $response->code,
             'HEADRegistry HEAD redirect-cgi.cgi returns 302');

    ok t_cmp('',
             $response->content,
             'HEADRegistry HEAD redirect-cgi.cgi returns no content');
  }
}
