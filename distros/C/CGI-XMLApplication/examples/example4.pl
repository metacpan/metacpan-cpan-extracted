#!/usr/bin/perl

# (c) 2001 ph15h

# example4.pl
#
# show how to pass script configurations
#
use lib qw( ../../  );

{
  # well i leave it up to your phantasy what to do here :)
  my %config = ( -DUMMY=>"the dummy" );

  require "example4.pm";
  my $script_class = new example4;

  # we could do some tricks with CGI.pm functions before run ...

  # and pass our prepared information to run().
  $script_class->run( \%config );
}


