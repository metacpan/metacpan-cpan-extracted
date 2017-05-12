#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('ASP4::PageLoader');


{
  my $page = ASP4::PageLoader->load( script_name => '/pageparser/010.asp');
  
  ok( $page );
  
  is( $page->script_name =>   '/pageparser/010.asp', "Script name is correct");
}


{
  my $page = ASP4::PageLoader->load( script_name => '/pageparser/master.asp');
  
  is( $page->script_name =>   '/pageparser/master.asp', "Script name is correct");
}


{
  my $page = ASP4::PageLoader->load( script_name => '/pageparser/child-outer.asp');
  
  is( $page->script_name =>   '/pageparser/child-outer.asp', "Script name is correct");
}


{
  my $page = ASP4::PageLoader->load( script_name => '/pageparser/child-inner1.asp');
  
  is( $page->script_name =>   '/pageparser/child-inner1.asp', "Script name is correct");
}

{
  my $page = ASP4::PageLoader->load( script_name => '/pageparser/child-inner2.asp');
  
  is( $page->script_name =>   '/pageparser/child-inner2.asp', "Script name is correct");
}

