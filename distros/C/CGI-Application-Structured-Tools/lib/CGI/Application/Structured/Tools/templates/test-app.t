#!perl -T
#
# $Id: test-app.t 52 2009-01-06 03:22:31Z jaldhar $
#
use strict;
use warnings;
use Test::More tests => 1;
use Test::WWW::Mechanize::CGIApp;
use <tmpl_var main_module>;

my $mech = Test::WWW::Mechanize::CGIApp->new;

$mech->app('<tmpl_var main_module>');

$mech->get_ok();

