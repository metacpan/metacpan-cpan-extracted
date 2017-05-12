#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Digest::MD5 'md5_hex';
use ASP4::API;
use HTML::Form;

my $api; BEGIN { $api = ASP4::API->new }


for( 1..4 )
{
  # Get the form:
  my $res = $api->ua->get('/form.asp');
  ok( $res->is_success => "Got /form.asp");

  # Also retrieve the captcha image as though we were a browser:
  ok(
    $api->ua->get('/handlers/dev.captcha?r=' . rand()),
    "Got the captcha image"
  );
  ok(
    my ($form) = HTML::Form->parse( $res->content, '/' ),
    "Got the form"
  );


  # Figure out what the security code is:
  my $Session = $api->context->session;
  my $wordLength = $api->context->config->system->settings->captcha_length;
  my $secret = $api->context->config->system->settings->captcha_key;
  my ($word) = grep {
    length($_) == $wordLength &&
    md5_hex($_ . $secret) eq $Session->{asp4captcha}->{$_};
  } keys %{ $Session->{asp4captcha} };


  # Fill out the form - lowercase:
  $form->find_input('security_code')->value( lc($word) );
  $res = $api->ua->submit_form( $form );
  is( $res->content => "CORRECT", "Validated correctly (A)" );


  # Fill out the form - uppercase:
  $form->find_input('security_code')->value( uc($word) );
  $res = $api->ua->submit_form( $form );
  is( $res->content => "CORRECT", "Validated correctly (B)" );

  # Fill out the form - WRONG:
  $form->find_input('security_code')->value( 'no-way-jose' );
  $res = $api->ua->submit_form( $form );
  is( $res->content => "WRONG", "Validated correctly (C)" );
}# end for()

