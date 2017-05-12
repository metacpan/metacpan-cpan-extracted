#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 4;

use Class::DBI::FormBuilder::DBI::Test; 

{
    my $apple = CDBIFB::Alias->retrieve( 1 );
    
    isa_ok( $apple, 'Class::DBI' );
    
    my $form;
    
    # this dies because CDBI::FB looks for columns called 'colour' and 'fruit', 
    # but should use the appropriate accessor/mutator names instead 
    lives_ok { $form = $apple->as_form };
    
    my $html;
     
    lives_ok { $html = $form->render };
    
    # an extra pk field is getting added
    # ref: the test in 05.update_or_create.t confirms only 1 field is expected
    my @matches = $html =~ /(name="id")/g;
    is( scalar( @matches ), 1 );

    #warn $html;
}