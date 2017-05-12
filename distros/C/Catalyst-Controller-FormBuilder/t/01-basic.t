package main;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;
my $page = "books/basic";
$mech->get_ok( "http://localhost/$page", "GET /$page" );

my $form = $mech->current_form;
ok( $form, "Form found" ) or BAIL_OUT("Can't do anything without a form");

my @inputs = $form->inputs;

is( scalar(@inputs), 3, "Form has expected number of fields" );

my $email = $form->find_input( "email", "text" );
ok( $email, "Found email field" );

