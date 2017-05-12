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
  my $url = '/cgi-bin/cgi.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi GET cgi.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'mod_cgi GET cgi.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'mod_cgi HEAD cgi.cgi returns 200');

    ok t_cmp($response->content,
             '',
             'mod_cgi HEAD cgi.cgi returns no content');
  }
}

# Apache::Registry
{
  my $url = '/perl-bin/cgi.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'Registry GET cgi.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'Regsitry GET cgi.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'Registry HEAD cgi.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'Regsitry HEAD cgi.cgi returns content (bad)');
  }
}

# HEADRegistry
{
  my $url = '/head-bin/cgi.cgi';

  {
    my $response = GET $url;

    ok t_cmp(200,
             $response->code,
             'HEADRegistry GET cgi.cgi returns 200');

    ok t_cmp('Hello World',
             $response->content,
             'HEADRegsitry GET cgi.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(200,
             $response->code,
             'HEAD Registry HEAD cgi.cgi returns 200');

    ok t_cmp('',
             $response->content,
             'HEAD Regsitry HEAD cgi.cgi returns no content');
  }
}
