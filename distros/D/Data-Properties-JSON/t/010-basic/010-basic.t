#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use JSON::XS;
use_ok('Data::Properties::JSON');

FILE: {
  ok( my $props = Data::Properties::JSON->new( properties_file => "t/test.json" ), "Got properties object" );

  is( $props->contact_form->first_name => 'John', "props.contact_form.first_name is 'John'" );
  is( $props->contact_form->last_name => 'Doe', "props.contact_form.last_name is 'Doe'" );
  is( $props->contact_form->email => 'john.doe@test.com', "props.contact_form.email is 'john.doe\@test.com'" );
  is( $props->contact_form->message => 'This is a test message...just a test.', "props.contact_form.message is 'This is a test message...just a test.'" );
};

STRING: {
  open my $ifh, '<', 't/test.json'
    or die "Cannot open 't/test.json' for reading: $!";
  local $/;
  ok( my $props = Data::Properties::JSON->new( json => scalar(<$ifh>) ), "Got properties object" );

  is( $props->contact_form->first_name => 'John', "props.contact_form.first_name is 'John'" );
  is( $props->contact_form->last_name => 'Doe', "props.contact_form.last_name is 'Doe'" );
  is( $props->contact_form->email => 'john.doe@test.com', "props.contact_form.email is 'john.doe\@test.com'" );
  is( $props->contact_form->message => 'This is a test message...just a test.', "props.contact_form.message is 'This is a test message...just a test.'" );
};

DATA: {
  open my $ifh, '<', 't/test.json'
    or die "Cannot open 't/test.json' for reading: $!";
  local $/;
  my $data = decode_json( scalar(<$ifh>) );
  ok( my $props = Data::Properties::JSON->new( data => $data ), "Got properties object" );

  is( $props->contact_form->first_name => 'John', "props.contact_form.first_name is 'John'" );
  is( $props->contact_form->last_name => 'Doe', "props.contact_form.last_name is 'Doe'" );
  is( $props->contact_form->email => 'john.doe@test.com', "props.contact_form.email is 'john.doe\@test.com'" );
  is( $props->contact_form->message => 'This is a test message...just a test.', "props.contact_form.message is 'This is a test message...just a test.'" );
};

