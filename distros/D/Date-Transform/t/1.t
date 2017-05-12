# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use lib '..';

use Test::Simple tests => 3;
use Date::Transform;

# use Data::Dumper;
# use Date::Manip;
# use Benchmark qw(:all);

#########################
# TESTS

ok( 1, "Everything fine so far." );    # If we made it this far, we're ok.

my $output =
"Fri Friday Jul July Fri Jul  23:15:55 Pacific Daylight Time 1982 02 23 11 183 07 15 PM 55 26 5 26 07/02/82 23:15:55 82 1982 Pacific Daylight Time";

# 					  '%a %A   %b %B %c                                                             %d%H%I  %j %m%M%p%S%U%w%W%x     %X           %y %Y %Z'

my $dt = new Date::Transform( '%B/%e/%y %i:%M:%S %p',
    '%a %A %b %B %c %d %H %I %j %m %M %p %S %U %w %W %x %X %y %Y %Z' );
ok( defined $dt, "Date::Transform::new(). " )
  ;                                    # Object successfully constructed.

my $tr = $dt->transform("july/ 2/82 11:15:55 PM");

# timethis( -3, sub { $dt->transform("july/ 2/82 11:15:55 PM") } );
# timethis( -5, sub { UnixDate( 'july/ 2/1972 12:15:55 PM', '%T %Y-%B-%d' ) } );
# print "\n\n-->$tr<--\n";

ok( $tr eq $output, "Successfully executed strftime." );

