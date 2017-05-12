# This is -*-Perl-*- code
# Bio::GMOD Test Harness Script for Modules
# $Id: mysqld.t,v 1.2 2005/05/31 22:31:58 todd Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use vars qw($NUMTESTS $DEBUG $MODULE %OPTIONS);

use lib '..','.','./blib/lib';

my $error;

BEGIN {
  $MODULE = 'Bio::GMOD::Admin::Monitor::mysqld';
  $error = 0;
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test::More; };
  if( $@ ) {
    use lib 't';
  }
  use Test::More;
  
  if (-e 't/do_monitor_mysqld.tests') {
    open IN,'t/do_monitor_mysqld.tests';
    while (<IN>) {
      chomp;
      next if /^\#/;
      next if /^\s/;
      next unless /^(.*)=(.+)/o;
      $OPTIONS{lc($1)} = $2;
    }
    close IN;
    $NUMTESTS = 3 + (scalar keys %OPTIONS);
  } else {
    $NUMTESTS = 1;
  }

  plan tests => $NUMTESTS;

  # Try to use the module
  eval { use_ok($MODULE); };
  if( $@ ) {
    print STDERR "Could not use $MODULE. Skipping tests.\n";
    $error = 1;
  }
}

exit 0 if $error;
exit 1 unless (scalar keys %OPTIONS > 0);

END {
  #    foreach ( $Test::ntest..$NUMTESTS) {
  #      skip('unable to run all of the Bio::GMOD tests',1);
  #    }
}

# Begin tests
my $monitor  = Bio::GMOD::Admin::Monitor::mysqld->new();
ok($monitor,'new constructor via Bio::GMOD');

# Check the status of mysql
my ($string,$status) = $monitor->check_status();
if ($status == 0) {  # If httpd is down, make sure the string indicates that
  like($string,qr/down/,$string);
} else {
  like($string,qr/up/,$string);
}


# Try restarting mysqld via mysqld
if ($OPTIONS{mysqld_safe}) {
  my ($string,$status) = $monitor->restart(-mysqld_safe => $OPTIONS{mysqld_safe});
  ok($status,$string);
}

if ($OPTIONS{mysql_initd}) {
  my ($string,$status) = $monitor->restart(-mysql_initd => $OPTIONS{mysql_initd});
  ok($status,$string);
}
