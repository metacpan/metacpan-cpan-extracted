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
  my $url = '/cgi-bin/printf.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi GET printf.cgi returns 200');

    ok t_cmp("Hello World 0033",
             $response->content,
             'mod_cgi GET printf.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi HEAD printf.cgi returns 200');

    ok t_cmp('',
             $response->content,
             'mod_cgi HEAD printf.cgi returns no content');
  }
}

# Apache::Registry
{
  my $url = '/perl-bin/printf.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'Registry GET printf.cgi returns 200');

    ok t_cmp("Hello World 0033",
             $response->content,
             'Registry GET printf.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'Registry HEAD printf.cgi returns 200');

    ok t_cmp("Hello World 0033",
             $response->content,
             'Registry HEAD printf.cgi returns content (bad)');
  }
}

# HEADRegistry
{
  my $url = '/head-bin/printf.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'HEADRegistry GET printf.cgi returns 200');

    ok t_cmp("Hello World 0033",
             $response->content,
             'HEADRegistry GET printf.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'HEADRegistry HEAD printf.cgi returns 200');

    ok t_cmp('',
             $response->content,
             'HEADRegistry HEAD printf.cgi returns no content');
  }
}
