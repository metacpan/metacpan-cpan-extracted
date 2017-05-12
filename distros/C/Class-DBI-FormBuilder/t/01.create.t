#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 7;

use Class::DBI::FormBuilder::DBI::Test;

{
    # Fake a submission request
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{QUERY_STRING}   = 'name=Dave&street=NiceStreet&town=1&_submitted=1';
    
    my $data = { street => 'NiceStreet',
                 name   => 'Dave',
                 town   => 1,
                 #id     => undef,
                 toys    => undef,
                 job => undef,
                 };
                 
    #Person->form_builder_defaults->{auto_validate}->{debug} = 2;

    my $form = Person->as_form; # ( debug => 3 );
    
    isa_ok( $form, 'CGI::FormBuilder' );

    is_deeply( scalar $form->field, $data );
    
    ok( $form->validate );
    
    #$form->validate || warn $form->render;
    
    my $obj;
    lives_ok { $obj = Person->create_from_form( $form ) } 'create_from_form';
    
    isa_ok( $obj, 'Class::DBI' );
    
    my $id = $obj->id;
    
    is( $id, 1 ); # test the actual value, since it is used in 02.update.t
    
    $data->{town} = 'Trumpton';
    
    my $obj_data = { map { $_ => $obj->$_ || undef } keys %$data };
    $obj_data->{id} = $obj->id;
    
    $data->{id} = 1;    
    is_deeply( $obj_data, $data );
    
    # fill up the db a bit
    Person->create_from_form( $form ) for 1 .. 20;
}    
