#!perl -T

use Test::More tests => 1;

use strict;
use Authen::Simple::WebForm;

my $webform = Authen::Simple::WebForm->new( login_url => 'https://host.company.com' );

ok( $webform );

