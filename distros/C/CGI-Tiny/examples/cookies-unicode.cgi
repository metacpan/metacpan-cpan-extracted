#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use MIME::Base64 qw(decode_base64 encode_base64);

cgi {
  my $cgi = $_;

  my $value = $cgi->param('cookie_value');
  unless (defined $value) {
    my $cookie = $cgi->cookie('unicode');
    $value = decode_utf8 decode_base64 $cookie if defined $cookie;
  }

  if (defined $value) {
    my $encoded_value = encode_base64 encode_utf8($value), '';
    $cgi->add_response_cookie(unicode => $encoded_value, Path => '/');
    $cgi->render(text => "Set cookie value: $value");
  } else {
    $cgi->render(text => "No cookie value set");
  }
};
