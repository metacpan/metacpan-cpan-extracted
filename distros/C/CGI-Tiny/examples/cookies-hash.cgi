#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Cpanel::JSON::XS qw(decode_json encode_json);
use MIME::Base64 qw(decode_base64 encode_base64);

cgi {
  my $cgi = $_;

  my $key = $cgi->param('cookie_key');
  my $hashref;
  if (defined $key) {
    $hashref->{$key} = $cgi->param('cookie_value');
  } else {
    my $cookie = $cgi->cookie('hash');
    $hashref = decode_json decode_base64 $cookie if defined $cookie;
    $key = (keys %$hashref)[0] if defined $hashref;
  }

  if (defined $hashref) {
    my $encoded_value = encode_base64 encode_json($hashref), '';
    $cgi->add_response_cookie(hash => $encoded_value, Path => '/');
    $cgi->render(text => "Set cookie hash key $key: $hashref->{$key}");
  } else {
    $cgi->render(text => "No cookie value set");
  }
};
