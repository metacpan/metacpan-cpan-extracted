#!/usr/bin/perl

# (c) 2001 ph15h

# example3.pl
#
# show how to pass script configurations
#
use lib qw( ../../  );

{
  # well i leave it up to your phantasy what to do here :)
  my %config = ( -DUMMY=>"the dummy" );

  my ( $package ) = ( $0 =~ /\/?(\w+)\.pl/i );
  require "$package.pm";
  my $script_class = new $package;

  # we could do some tricks with CGI.pm functions before run ...

  # and pass our prepared information to run().
  $script_class->run( \%config );
}


