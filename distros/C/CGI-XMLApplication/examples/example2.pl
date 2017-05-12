#!/usr/bin/perl

# (c) 2001 ph15h

# example2.pl

use lib qw( ../../  );

{
  # this script will figure by its calling name, which module to load
  my ( $package ) = ( $0 =~ /\/?(\w+)\.pl/i );
  require "$package.pm";

  # some times there are already information available at this level.
  my %ctxt = (-test=>1);

  my $script_class = new $package;
  $script_class->setStylesheetPath( "your/path" );
  $script_class->run(\%ctxt);
}


