#!/usr/bin/perl
#
# Test of Class::Hook
# Needs FOO.PM in installation package
#
# Make method calls to FOO and check the values sent and returned
# Normally, all calls should be intercepted by Class::Hook
#
# Pierre Denis <pierre@itrelease.net>

use strict;
use warnings;
use lib 't/lib';
use Test::Simple tests => 11;
use Class::Hook;
use constant CLASS => 'FOO';

use Data::Dumper;

our ($before, $after);


Class::Hook->new(\&before, \&after);

my $param = {param1 => 'value1',
             param2 => [2,5,7] };
my $obj = FOO->new($param);
ok( defined($obj) && (ref($obj) eq CLASS), 'FOO->new() call' );
ok( ($before->{class} eq CLASS)
    &&
    ($before->{method} eq 'new')
    &&
    (Dumper($before->{param}->[0]) eq Dumper($param))
    &&
    ($before->{counter} == 0),
    'new(): before'
  );
ok( ($after->{class} eq CLASS)
    &&
    ($after->{method} eq 'new')
    &&
    (Dumper($after->{param}->[0]) eq Dumper($param))
    &&
    ($after->{counter} == 1)
	&&
	(ref $after->{'return'} eq CLASS),
    'new(): after'
  );


FOO->unknown(1, 2); # Doesn't exist
ok( ($before->{class} eq CLASS)
    &&
    ($before->{method} eq 'unknown')
    &&
    ($before->{param}->[0] == 1)
    &&
    ($before->{counter} == 0),
    'unkown(): before'
  );
ok( ($after->{class} eq CLASS)
    &&
    ($after->{method} eq 'unknown')
    &&
    ($after->{param}->[0] == 1)
    &&
    ($after->{counter} == 1)
    &&
    (not $after->{'return'}->[0]),
    'unkown(): after'
  );

$obj->bar();
ok( ($before->{class} eq CLASS)
    &&
    ($before->{method} eq 'bar')
    &&
    ($before->{counter} == 0),
    'bar(): before 1'
  );
ok( ($after->{class} eq CLASS)
    &&
    ($after->{method} eq 'bar')
    &&
    ($after->{counter} == 1)
    &&
    ($after->{'return'} eq 'Bar return string'),
    'bar(): after 1'
  );

$obj->bur();
ok( ($before->{class} eq CLASS)
    &&
    ($before->{method} eq 'bur')
    &&
    ($before->{counter} == 0),
    'bur(): before'
  );
ok( ($after->{class} eq CLASS)
    &&
    ($after->{method} eq 'bur')
    &&
    ($after->{counter} == 1)
    &&
    (not $after->{'return'}->[0]),
    'bur(): after'
  );

FOO->bar();
ok( ($before->{class} eq CLASS)
    &&
    ($before->{method} eq 'bar')
    &&
    ($before->{counter} == 1),
    'bar(): before 2'
  );
ok( ($after->{class} eq CLASS)
    &&
    ($after->{method} eq 'bar')
    &&
    ($after->{counter} == 2)
    &&
    ($after->{'return'} eq 'Bar return string'),
    'bar(): after 2'
  );


BAR->mlk(); # Doesn't exist

Class::Hook->deactivate;

sub before {
	$before = shift;
	#print "Before: ".Dumper($before);
}

sub after {
	$after = shift;
	#print "After: ".Dumper($after);
}

