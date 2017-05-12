#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  eval "use Test::Warn";
  plan skip_all => "Test::Warn required to test warn" if $@;
  plan tests => 5;
}

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(:all) );
  use_ok( 'Text::CSV_XS' );
}

my @vals = qw(one);

warning_like {
  xsv_report({
    iterator   => sub { while ( @vals ) { return [ splice @vals, 0, 1 ] } },
    headers_cb => sub { [ qw(One) ] },
  })
}
  qr/passing empty fields list to headers_cb/i,
  'xsv_report: warning on empty fields list with headers callback';

warning_like {
  xsv_report({
    values     => [ [1] ],
    get_row_cb => sub { [ 1 ] },
  })
}
  qr/get_row_cb is deprecated/i,
  'xsv_report: warning on use of deprecated get_row_cb parameter';

warning_like {
  xsv_report({
    values     => [ [1] ],
    get_row_cb => sub { [ 1 ] },
    row_filter => sub { [ 1 ] },
  })
}
  qr/ignoring use of deprecated get_row_cb/i,
  'xsv_report: warning on use of both get_row_cb and row_filter';

