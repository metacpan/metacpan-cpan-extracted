#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use MIME::Base64 'decode_base64';
use Unicode::UTF8 'decode_utf8';

sub verify_password { my ($user, $pass) = @_; ... }

cgi {
  my $cgi = $_;

  my $authed_user;
  if (defined(my $auth = $cgi->header('Authorization'))) {
    if (my ($hash) = $auth =~ m/^Basic (\S+)/i) {
      my ($user, $pass) = split /:/, decode_utf8(decode_base64($hash)), 2;
      $authed_user = $user if verify_password($user, $pass);
    }
  }

  unless (defined $authed_user) {
    $cgi->add_response_header('WWW-Authenticate' => 'Basic realm="My Website", charset="UTF-8"');
    $cgi->set_response_status(401)->render;
    exit;
  }

  $cgi->render(text => "Welcome, $authed_user!");
};
