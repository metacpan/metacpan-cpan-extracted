#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón Barbero
#  Licensed under the GNU GPL.
#
#  CPAN:
#  http://search.cpan.org/dist/Nes/
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
# 
#  Version 1.04
#
#  test_script_handler.pl
#
# -----------------------------------------------------------------------------

# for test Secure Login
sub test_function_handler {
  my $user  = shift;
  my $pass  = shift;
  
  return 0 if !$user || !$pass;
  
  return $user if $pass eq '1234';
  
  return 0;
}

1;
