#!/usr/bin/perl -w
use strict;

use Cache::Historical;
use File::Temp qw(tempfile);
use DateTime::Format::Strptime;
use Test::More tests => 15;

my($fh, $tmpfile) = tempfile( UNLINK => 1 );
unlink $tmpfile; # unlink so db gets initialized

my $c = Cache::Historical->new(
        cache_dir   => "/tmp",
        sqlite_file => $tmpfile,
);

my $fmt = DateTime::Format::Strptime->new(
              pattern => "%Y-%m-%d");

$c->set( $fmt->parse_datetime("2008-01-03"), "msft", 35.37 );
$c->set( $fmt->parse_datetime("2008-01-02"), "msft", 35.22 );
sleep 1; # so the update time is never the same for all the rows
$c->set( $fmt->parse_datetime("2008-01-04"), "msft", 34.38 );
$c->set( $fmt->parse_datetime("2008-01-07"), "msft", 34.61 );

#print "tempfile=$tmpfile", "\n";

is( $c->get( $fmt->parse_datetime("2008-01-03"), "msft"), 35.37, 
    "get value" );
is( $c->get( $fmt->parse_datetime("2008-01-05"), "msft"), undef, 
    "get undef value" );

my($from, $to) = $c->time_range( "msft" );

is("$from", "2008-01-02T00:00:00", "time range from");
is("$to",   "2008-01-07T00:00:00", "time range to");

# interpolated
is( $c->get_interpolated( $fmt->parse_datetime("2008-01-06"), "msft"), 34.38, 
    "get interpolated value" );

is( $c->get_interpolated( $fmt->parse_datetime("2008-01-09"), "msft"), 34.61, 
    "get interpolated value" );

is( $c->get_interpolated( $fmt->parse_datetime("2008-01-01"), "msft"), undef, 
    "get interpolated value" );

is( $c->get_interpolated( $fmt->parse_datetime("2007-01-01"), "msft"), undef, 
    "get interpolated value" );

is( $c->get_interpolated( $fmt->parse_datetime("2009-01-01"), "twx"), undef, 
    "get interpolated value" );

$c->set( $fmt->parse_datetime("2008-01-02"), "twx", 35.22 );

# keys/values

my @values = $c->values('msft');
my $str;
for (@values) {
    my($dt, $val) = @$_;
    $str .= $dt->day() . " " . $val . " ";
}
is($str, "2 35.22 3 35.37 4 34.38 7 34.61 ", "values()");

my @keys = $c->keys();
is($keys[0], "msft", "keys()");
is($keys[1], "twx",  "keys()");

# clear
$c->clear("msft");
is( $c->get_interpolated( $fmt->parse_datetime("2009-01-01"), "msft"), undef, 
    "get after clear" );
is( $c->get_interpolated( $fmt->parse_datetime("2008-01-02"), "twx"), 35.22, 
    "get after clear" );

$c->clear();
is( $c->get_interpolated( $fmt->parse_datetime("2009-01-02"), "twx"), undef, 
    "get after clear" );

