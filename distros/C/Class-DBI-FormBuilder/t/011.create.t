#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 8;

use Class::DBI::FormBuilder::DBI::Test;

{   # specify a subset of fields, and check the data sent to create a new object

    # Fake a submission request
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{QUERY_STRING}   = 'name=George&town=1&_submitted=1';
    
    my $data = { name   => 'George',
                 town   => 1,
                 #id     => undef,
                 #street => undef,
                 };
                 
    # no toys or street
    my $form = Person->as_form( fields => [ qw(  name town ) ] ); # ( debug => 3 );
    
    isa_ok( $form, 'CGI::FormBuilder' );
    is_deeply( scalar $form->field, $data );
    
    # 
    # this is the new use case we are testing in this script - there should be no 'street' data
    # (not even undef) being sent to the db
    # 
    is_deeply( Class::DBI::FormBuilder->_fb_create_data( 'Person', $form ), $data );
    
    
    
    
    ok( $form->validate, 'form validates' );
    
    my $obj;
    lives_ok { $obj = Person->create_from_form( $form ) } 'create_from_form';
    
    isa_ok( $obj, 'Class::DBI' );
    
    is( $obj->id, 22 ); 
    
    $data->{town} = 'Trumpton';
    
    my $obj_data = { map { $_ => $obj->$_ || undef } keys %$data };
    $obj_data->{id} = $obj->id;
    
    $data->{id} = 22;    
    is_deeply( $obj_data, $data );
    
}    



