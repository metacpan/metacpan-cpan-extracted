#!/usr/bin/perl -I. -w

use Aw 'test_broker@localhost:6449';
require Aw::Client;
require Aw::Event;

use Data::Dumper;

my %basic		=(
	_name		=> "PerlDevKit::EventOfDoom",
	b 		=> 1,
	by		=> 0x10,
	c		=> 'c',
	d		=> 999999999,
	l		=> 111111111,
	f		=> 3.1415927,
	i		=> 100,
	's'		=> "hello",
	sh		=> 4000,
	'uc'		=> 'u',
	us 		=> 'world',
	b_array		=> [ 0, 1, 0, 1, 0 ],
	by_array	=> [ 0x0f, 0x10, 0xff ],
	c_array		=> [ 'a', 'b', 'c' ],
	d_array		=> [ 0.1, 0.2, 0.3, 0.4 ],
	f_array		=> [ 0.1, 0.2, 0.3, 0.4 ],
	i_array		=> [  10,  20,  30 ],
	l_array		=> [ 1, 2, 3, 4, 5 ],
	s_array		=> [ "String 1", "String 2", "String 3" ],
	sh_array	=> [ 1, 2, 3, 4, 5 ],
	uc_array	=> [ 'a', 'b', 'c' ],
	us_array	=> [ "UC String 1", "UC String 2", "UC String 3" ],
);

$basic{dt} = new Aw::Date;
$basic{dt}->setDateCtime ( time );

print "Sleeping for a sec...\n";
sleep 1;

my $dT = new Aw::Date;
$dT->setDateCtime ( time );

$basic{dt_array} = [ $dT, $dT, $dT, $dT ];

my %basicA = %basic;
my %basicB = %basic;

my $doom           = \%basic;

$doom->{st}        = \%basicA;
$doom->{st}{st}    = \%basicB;

my %structA        = %$doom;
my %structB        = %$doom;
my %structC        = %$doom;

$doom->{st_array}  = [ \%structA, \%structB, \%structC ];

my $client = new Aw::Client ( "PerlDemoClient" );

my $event  = new Aw::Event ( $client, $doom );

%basic = ();

my %hash = $event->toHash;

print Dumper(\%hash);

print "\$hash{dt} time is:  ", $hash{dt}->toString, "\n";
print "\$hash{st_array}[1]{st}{dt_array}[2] time is: ",  $hash{st_array}[1]{st}{dt_array}[2]->toString, "\n";

__END__

=head1 NAME

eod.pl - An Aw::Event Demonstrator.

=head1 SYNOPSIS

./eod.pl

=head1 DESCRIPTION

The script connect to the broker set on line 3 and creates a populated
PerlDevKit::EventOfDoom.  The event is converted into a hash and nested
date objects are printed as strings by invoking their "toString" methods.

The PerlDevKit::EventOfDoom and the DemoClientGroup must first be
set in the target broker from the PerlDemo.adl file.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
