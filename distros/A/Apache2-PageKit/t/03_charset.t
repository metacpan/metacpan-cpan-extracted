use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
plan tests => 9;

BEGIN {
  eval {
    if ( $] < 5.008 ) {
      require Text::Iconv;
    }
    else { 
      require Encode;
      require encoding;
      encoding->import('latin1');
    }
  };
}

# simple load test
ok 1;

# check if we can request a page
my $url = '/charset';
my $s1  = 'index.tmpl: stra&#223;e   straße ööäöüäüöüü';
my $s2  = 'straße ßßöäöäöüäöäüü';

# preform the test twice, the first time to fill the cache and a
# second time to use the results.
for ( 1 .. 2 ) {
  my $data = GET_BODY $url, 'Accept-Charset', 'iso-8859-1';
  ok t_cmp( $data, qr~$s1~, "street ok? (iso-8859-1)" );
  ok t_cmp( $data, qr~$s2~, "street from content_var ok? (iso-8859-1)" );
}

for ( 1 .. 2 ) {
  my $data = GET_BODY $url, 'Accept-Charset', 'utf8';
  unless ( $] < 5.008 ) {
    Encode::from_to( $data, utf8 => 'iso-8859-1' );
  }
  else {
    my $c = Text::Iconv->new( utf8 => "iso-8859-1");
    $data = $c->convert( $data );
  }
  ok t_cmp( $data, qr~$s1~, "street ok? (utf8)" );
  ok t_cmp( $data, qr~$s2~, "street from content_var ok? (utf8)" );
}
