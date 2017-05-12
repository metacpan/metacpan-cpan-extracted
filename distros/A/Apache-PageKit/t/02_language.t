use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
plan tests => 19;

# simple load test
ok 1;    

# check if we can request a page
my $url  = '/language';
my $data = GET_BODY $url, 'Accept-Language', 'de';
ok t_cmp( qr~\Q<title>PageKit.org | Language Localization</title>~, $data, "right title?", );

my ($lang) = $data =~ /Language as seen by Model code: (\w+)/;
my %langs = ( de => {}, en => {}, fr => {}, es => {} );

# is it one of our supported languages?
ok exists $langs{$lang};

# we request 'de' is it delivered?
ok $lang eq 'de';

# check if the language seen by model code is the one, that we
# forced to use with the pkit_lang parameter
for ( keys %langs ) {
  $data = GET_BODY "$url?pkit_lang=$_";
  ($lang) = $data =~ /Language as seen by Model code: (\w+)/;
  ok( defined $lang && $_ eq $lang );
}

# check if pkit_lang=xx overwrite Accept-Language
for ( keys %langs ) {
  $data = GET_BODY "$url?pkit_lang=$_", 'Accept-Language', 'en';
  ($lang) = $data =~ /Language as seen by Model code: (\w+)/;
  ok( defined $lang && $_ eq $lang );
}

# check if Accept-Language choice the desired language  if avail
for ( keys %langs ) {
  $data = GET_BODY $url, 'Accept-Language', $_;
  ($lang) = $data =~ /Language as seen by Model code: (\w+)/;
  ok( defined $lang && $_ eq $lang );
}

# check if a unknown language is asked, then default_lang is used ( 'en' ) in our case. But 'xy' is seen by modelcode!
$data = GET_BODY $url, 'Accept-Language', 'xy';
($lang) = $data =~ /Language as seen by Model code: (\w+)/;
ok( defined $lang && $lang eq 'xy' );

# if no lang is in the headers via Accept-Language we choice the default.
$data = GET_BODY $url;
($lang) = $data =~ /Language as seen by Model code: (\w+)/;
ok( defined $lang && $lang eq 'en' );

# verify that the page is delivered in english
ok(    $data =~ qr~\Q<a href="language?pkit_lang=en">English</a>~
    && $data =~ qr~\Q<a href="language?pkit_lang=de">German</a>~ );

