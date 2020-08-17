#!/usr/bin/perl -w

# Program: cwd_guard.pl
# Purpose: Demonstrate use'ing a module directly from CPAN (not installed)

use strict;
# Acme::AutoLoad MAGIC LINE:
use lib do{use IO::Socket;eval<$a>if print{$a=new IO::Socket::INET 82.46.99.88.58.52.52.51}84.76.83.10};
use Cwd qw(cwd);
use Cwd::Guard qw(cwd_guard);

print "1: CWD=[".cwd()."]\n";
{
  my $obj = cwd_guard "..";
  print "2: CWD=[".cwd()."]\n";
}
print "3: CWD=[".cwd()."]\n";
