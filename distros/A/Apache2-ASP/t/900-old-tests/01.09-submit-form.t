#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use HTML::Form;

my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get("/simple-form.asp");
my $form = HTML::Form->parse( $res->content, '/' );
$form->find_input('color')->value('Red');
$res = $s->ua->submit_form( $form );

like
  $res->content,
  qr/Your color is "Red"/
;

