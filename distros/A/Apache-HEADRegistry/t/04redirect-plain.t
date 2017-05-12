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
  my $url = '/cgi-bin/redirect-plain.cgi';

  {
    my $response = GET $url;

    ok t_cmp(302,
             $response->code,
             'mod_cgi GET redirect-plain.cgi returns 302');

    ok t_cmp(qr/The document has moved/,
             $response->content,
             'mod_cgi GET redirect-plain.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(302,
             $response->code,
             'mod_cgi HEAD redirect-plain.cgi returns 302');

    ok t_cmp('',
             $response->content,
             'mod_cgi HEAD redirect-plain.cgi returns no content');
  }
}

# Apache::Registry
{
  my $url = '/perl-bin/redirect-plain.cgi';

  {
    my $response = GET $url;

    ok t_cmp(302,
             $response->code,
             'Registry GET redirect-plain.cgi returns 302');

    ok t_cmp(qr/The document has moved/,
             $response->content,
             'Registry GET redirect-plain.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(302,
             $response->code,
             'Registry HEAD redirect-plain.cgi returns 302');

    ok t_cmp(qr/The document has moved/,
             $response->content,
             'Registry HEAD redirect-plain.cgi returns content (bad)');
  }
}

# HEADRegistry
{
  my $url = '/head-bin/redirect-plain.cgi';

  {
    my $response = GET $url;

    ok t_cmp(302,
             $response->code,
             'HEADRegistry GET redirect-plain.cgi returns 302');

    ok t_cmp(qr/The document has moved/,
             $response->content,
             'HEADRegistry GET redirect-plain.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(302,
             $response->code,
             'HEADRegistry HEAD redirect-plain.cgi returns 302');

    ok t_cmp('',
             $response->content,
             'HEADRegistry HEAD redirect-plain.cgi returns no content');
  }
}
