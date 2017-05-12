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

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'colour=orange&fruit=orange&town=2&_submitted=1';

# basic tests
SKIP: {
    
    skip 'aliased column names not yet supported', 4;
{

    my $data = { colour => 'orange', 
                 fruit  => 'orange',
                 town   => 2,
                 };
                 
                 
    my $form = CDBIFB::Alias->as_form;
    
    ok( $form->submitted, 'form submitted' );
    
    # fails because of mangled column name/mutator/accessor in auto-validate code
    ok( $form->validate, 'form validated' );
    
    #warn $form->render unless $form->validate;
    
    my $orange;
     
    lives_ok { $orange = CDBIFB::Alias->create_from_form( $form ) };
    
    # this fails ($orange is undefined) because the form data are keyed by column name, 
    # but need to be sent to CDBI keyed by mutator name
    isa_ok( $orange, 'Class::DBI' );
    
    
    #warn $form->render( PrettyPrint => 1 );
    
    
}
} # / SKIP
