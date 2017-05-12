#!/usr/bin/env perl
use strict;
use warnings;

use App::DH;
{
  package    # hide from pause
    MyApp;
  use Moose;
  extends 'App::DH';
  has '+connection_name' => ( default => sub { 'production' } );
  has '+schema'          => ( default => sub { 'MyApp::Schema' } );
  __PACKAGE__->meta->make_immutable;

}

MyApp->new_with_options->run;

