#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88;            # done_testing

plan tests => 20;

use Apache2::Const qw(OK DECLINED);
use Apache2::HttpEquiv;
use File::Temp;

#=====================================================================
{
  package Mock_Request;

  use Moo;

  has content_type => qw(
    is      rw
    default text/html
  );

  has is_initial_req => qw(
    is      ro
    default 1
  );

  has filename => qw(
    is       ro
  );

  has _headers => (qw(
    is          ro
    default) => sub { [] },
  );

  sub headers_out { shift }     # Just return the same mock object

  sub set
  {
    my $self = shift;

    push @{ $self->_headers }, [ @_ ];
  } # end set

  sub _test_results
  {
    my $self = shift;

    [ $self->content_type, @{ $self->_headers } ];
  } # end _test_results
} # end class Mock_Request
#=====================================================================

sub test
{
  my ($name, $params, $text, $expected, $exResult) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $tmp = File::Temp->new(UNLINK => 1);

  binmode $tmp, ':encoding(latin1)';
  print $tmp $text;
  $tmp->close;

  my $r = Mock_Request->new(filename => "$tmp", %$params);

  $exResult = OK unless defined $exResult;

  is(Apache2::HttpEquiv::handler($r), $exResult, "$name result");

  is_deeply($r->_test_results, $expected, "$name headers");
} # end test

#---------------------------------------------------------------------

test('meta charset', {}, <<'END',
<html><head><meta charset="UTF-8"></head>
END
     [ 'text/html; charset=UTF-8' ]);

test('meta charset and http-equiv', {}, <<'END',
<html><head><meta charset="UTF-8">
<meta http-equiv="New-Header" content="value">
</head><body></body></html>
END
     [ 'text/html; charset=UTF-8',
       [ 'New-Header' => 'value' ] ]);

test('http-equiv in body', {}, <<'END',
<html><head><meta charset="UTF-8"></head><body>
<meta http-equiv="New-Header" content="value">
</body></html>
END
     [ 'text/html; charset=UTF-8' ]);

test('not initial request', {is_initial_req => 0}, <<'END',
<html><head><meta charset="UTF-8">
<meta http-equiv="New-Header" content="value">
</head><body></body></html>
END
     [ 'text/html'], DECLINED);

test('not text/html', {content_type => 'text/plain'}, <<'END',
<html><head><meta charset="UTF-8">
<meta http-equiv="New-Header" content="value">
</head><body></body></html>
END
     [ 'text/plain'], DECLINED);

test('multiple headers', {}, <<'END',
<html><head><meta charset="Windows-1252">
<meta http-equiv="New-Header" content="header 1">
<meta content="header 2" http-equiv="Another-Header">
</head><body></body></html>
END
     [ 'text/html; charset=Windows-1252',
       [ 'New-Header'     => 'header 1' ],
       [ 'Another-Header' => 'header 2' ] ]);

test('repeated header', {}, <<'END',
<html><head><meta charset="ISO-8859-1">
<meta http-equiv="New-Header" content="header 1">
<meta content="header 2" http-equiv="New-Header">
</head><body></body></html>
END
     [ 'text/html; charset=ISO-8859-1',
       [ 'New-Header' => 'header 1' ],
       [ 'New-Header' => 'header 2' ] ]);

test('http-equiv content-type', {}, <<'END',
<html><head>
<meta http-equiv="New-Header" content="header 1">
<meta content="header 2" http-equiv="New-Header">
<meta http-equiv="Content-Type" content="text/html; charset='Windows-1252'">
</head><body></body></html>
END
     [ "text/html; charset='Windows-1252'",
       [ 'New-Header' => 'header 1' ],
       [ 'New-Header' => 'header 2' ] ]);

test('claims text/xhtml', {}, <<'END',
<html><head>
<meta http-equiv="Content-Type" content="text/xhtml; charset=UTF-8">
</head><body></body></html>
END
     [ "text/html; charset=UTF-8" ]);

{
  my $r = Mock_Request->new(filename => 'does_not_exist');

  is(Apache2::HttpEquiv::handler($r), DECLINED, 'missing file is not error');
  is_deeply($r->_test_results, [ 'text/html' ], 'missing file no changes');
}

done_testing;
