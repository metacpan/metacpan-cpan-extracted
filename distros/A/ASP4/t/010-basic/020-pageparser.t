#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('ASP4::PageParser');
use_ok('ASP4::Page');
use_ok('ASP4::MasterPage' );


{
  my $parser = ASP4::PageParser->new( script_name => '/pageparser/010.asp');
  my $page = $parser->parse();

  use Data::Dumper;
#  warn Dumper( $page );
}


{
  my $parser = ASP4::PageParser->new( script_name => '/pageparser/master.asp' );
  ok( my $page = $parser->parse() );
  
  use Data::Dumper;
#  warn Dumper( $page );
}

{
  my $parser = ASP4::PageParser->new( script_name => '/pageparser/child-outer.asp' );
  ok( my $page = $parser->parse() );
  
  use Data::Dumper;
#  warn Dumper( $page );
}

{
  my $parser = ASP4::PageParser->new( script_name => '/pageparser/child-inner1.asp' );
  ok( my $page = $parser->parse() );
  
  use Data::Dumper;
#  warn Dumper( $page );
}

{
  my $parser = ASP4::PageParser->new( script_name => '/pageparser/child-inner2.asp' );
  ok( my $page = $parser->parse() );
  
  use Data::Dumper;
#  warn Dumper( $page );
}

