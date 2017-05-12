use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 12, (have_lwp && 
                   have_cgi && 
                   have_module('mod_perl.c'));

# mod_cgi
{
  my $url = '/cgi-bin/plain.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi GET plain.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'mod_cgi GET plain.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi HEAD plain.cgi returns 200');

    ok t_cmp('',
             $response->content,
             'mod_cgi HEAD plain.cgi returns no content');
  }
}

# Apache::Registry
{
  my $url = '/perl-bin/plain.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'Registry GET plain.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'Registry GET plain.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'Registry HEAD plain.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'Registry HEAD plain.cgi returns content (bad)');
  }
}

# HEADRegistry
{
  my $url = '/head-bin/plain.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'HEADRegistry GET plain.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'HEADRegistry GET plain.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'HEADRegistry HEAD plain.cgi returns 200');

    ok t_cmp('',
             $response->content,
             'HEADRegistry HEAD plain.cgi returns no content');
  }
}
