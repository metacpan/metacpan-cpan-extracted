use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan test => 12, (have_lwp &&
                  have_cgi &&
                  have_module('mod_perl.c'));

# mod_cgi
{
  my $url = '/cgi-bin/die.cgi';

  {
    my $response = GET $url;

    ok t_cmp(500,
             $response->code,
             'mod_cgi GET die.cgi returns 500');

    ok t_cmp(qr/The server encountered an internal error/,
             $response->content,
             'mod_cgi GET die.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(500,
             $response->code,
             'mod_cgi HEAD die.cgi returns 500');

    ok t_cmp('',
             $response->content,
             'mod_cgi HEAD die.cgi returns no content');
  }
}

# Apache::Registry
{
  my $url = '/perl-bin/die.cgi';

  {
    my $response = GET $url;

    ok t_cmp(500,
             $response->code,
             'Registry GET die.cgi returns 500');

    ok t_cmp(qr/The server encountered an internal error/,
             $response->content,
             'Registry GET die.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(500,
             $response->code,
             'Registry HEAD die.cgi returns 500');

    ok t_cmp('',
             $response->content,
             'Registry HEAD die.cgi returns no content');
  }
}

# HEADRegistry
{
  my $url = '/head-bin/die.cgi';

  {
    my $response = GET $url;

    ok t_cmp(500,
             $response->code,
             'HEADRegistry GET die.cgi returns 500');

    ok t_cmp(qr/The server encountered an internal error/,
             $response->content,
             'HEADRegistry GET die.cgi returns content');
  }

  {
    my $response = HEAD $url;

    ok t_cmp(500,
             $response->code,
             'HEADRegistry HEAD die.cgi returns 500');

    ok t_cmp('',
             $response->content,
             'HEADRegistry HEAD die.cgi returns no content');
  }
}
