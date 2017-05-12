# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..204\n"; }
END   { print "not ok 1\n" unless $loaded; }

my $ok_count = 1;
sub ok {
  my $ok = shift;
  $ok or print "not ";
  print "ok $ok_count\n";
  ++$ok_count;
  $ok;
}

use DateTime::Precise qw(:TimeVars);

package EmptySubclass;
use vars qw(@ISA);
use DateTime::Precise;
@ISA = qw(DateTime::Precise);
package main;

# If we got here, then the package being tested was loaded.
$loaded = 1;
ok(1);									#   1

sub Print {
  my $msg = shift;
  defined($msg) and print "$msg\n";
}

my $a = new EmptySubclass;
my $form = "time %h:%m:%s  date %D.%M.%^Y";

# tests 2-8 are dprintf/dscanf tests

# could also be %-D or %^Y, etc.  but not %*M or %M
# the %s is just tossed, not saved
# dscanf shouldn't print anything, unless there's an error.
Print $a->dscanf("%c %~M %D %h:%m:%s %Y",  "Fri Jun  6 12:55:44 1997");
ok( $a->dprintf($form) eq "time 12:55:44  date 06.06.1997" );		#   2

Print $a->dscanf("%Y/%M/%D %h:%m:%s", " 1997/04/29 22:45:51 ");
ok( $a->dprintf($form) eq "time 22:45:51  date 29.04.1997" );		#   3

Print $a->dscanf("%c %~M %D %h:%m:%s %c %Y", "Mon Jul 28 20:44:11 CDT 1997");
ok( $a->dprintf($form) eq "time 20:44:11  date 28.07.1997" );		#   4

# the strings can be specified, or left vague (as %c)
my $x = "*** leibniz.er.usgs.gov Monday July 28 1997 -- 20: 47 -43:00   ";
Print $a->dscanf("*** %c %c %*M %D %Y -- %h: %m %c", $x);
ok( $a->dprintf($form) eq "time 20:47:00  date 28.07.1997" );		#   5

# %p =~ /[a|p]m?/
Print $a->dscanf("%M.%D.%Y @ %h:%m%p", "12.3.97 @ 12:30a");
ok( $a->dprintf($form) eq "time 00:30:00  date 03.12.1997" );		#   6

Print $a->dscanf("%4Y%2M%2D%2h%2m%2s", "19971225101112");
ok( $a->dprintf($form) eq "time 10:11:12  date 25.12.1997" );		#   7

Print $a->dscanf("%u", "870310593"); # Unix GMT epochtime
ok( $a->dprintf($form) eq "time 00:56:33  date 31.07.1997" );		#   8

# tests 9-14 are various function tests

# new DateTime::Precise from datetime format
$a = EmptySubclass->new('1974.11.02 12:33:44');
ok( $a->internal eq "19741102123344" );					#   9

# new DateTime::Precise from internal format
$a = EmptySubclass->new('19741102123344');
ok( $a->internal eq "19741102123344" );					#  10

# new from nothing
$a = EmptySubclass->new();
ok( $a->internal() );							#  11

$a->set_from_datetime('1974.11.02 12:33:44');
ok( $a->internal eq "19741102123344" );					#  12

my $b = EmptySubclass->new();
$b->set_from_serial_day( $a->serial_day() );
ok( $a->internal() - $b->internal() == 0 );				#  13

$a->set_localtime_from_epoch_time($^T);
ok( $a->dprintf("%~w %~M %-D %h:%m:%s %^Y") eq scalar(localtime($^T)) ); # 14

# test 15-22 are overloaded op tests

$a->set_from_datetime('1974.11.02 12:33:44');
$b->set_from_datetime('1997.05.01 00:00:00');

# op-op tests
ok( $a < $b );								#  15
ok( !($a==$b) );							#  16

# test subtraction
ok( $b-$a ==  709817176 );						#  17
ok( $a-$b == -709817176 );						#  18

# op-num compares
ok( "$a" > 251 );							#  19

# addition
$a+=10;

# cmps vs strings and numerics (and see if the add worked)
ok( $a eq "19741102123354" );						#  20
ok( 19741102123354==$a );						#  21

# test stringification some
$b->internal( $a );
ok( $a==$b );								#  22
ok( $a eq $b );								#  23

# skipping inc/dec, floor/ciel ops, mostly
$a = EmptySubclass->new("1997.09.01 00:15:33");
$a-=(3*3600);
ok( $a eq "19970831211533" );						#  24

# tests 24-26 are new() tests (yeah, they should be at the top :)
$a = EmptySubclass->new("1997.12.25 12:01:33");
ok( $a eq "19971225120133" );						#  25
$a = EmptySubclass->new("1997.12.13");
ok( $a eq "19971213000000" );						#  26
$a = EmptySubclass->new("19971210101010");
ok( $a eq "19971210101010" );						#  27

# tests 27-36 are Julian day tests.
$a->set_from_day_of_year(1998, 1);
ok( $a eq "19980101000000" );						#  28
ok( $a->day_of_year == 1 );						#  29
$a->set_from_day_of_year(1998, 1.5);
ok( $a eq "19980101120000" );						#  30
$a->set_from_day_of_year(1998, 32);
ok( $a eq "19980201000000" );						#  31
$a->set_from_day_of_year(1998, 59);
ok( $a eq "19980228000000" );						#  32
$a->set_from_day_of_year(1998, 60);
ok( $a eq "19980301000000" );						#  33
$a->set_from_day_of_year(1998, 365);
ok( $a eq "19981231000000" );						#  34
$a->set_from_day_of_year(1996, 59);
ok( $a eq "19960228000000" );						#  35
$a->set_from_day_of_year(1996, 60);
ok( $a eq "19960229000000" );						#  36
$a->set_from_day_of_year(1996, 61);
ok( $a eq "19960301000000" );						#  37

$b = 366.56017361 + 0.2/Secs_per_day;
$a->set_from_day_of_year(1996, $b);
$a->round_sec;
ok( $a eq "19961231132639" );						#  38
ok( $a->year    == 1996 );						#  39
ok( $a->month   == 12 );						#  40
ok( $a->day     == 31 );						#  41
ok( $a->hours   == 13 );						#  42
ok( $a->minutes == 26 );						#  43
ok( $a->seconds == 39 );						#  44
ok( abs($b - $a->day_of_year) < 1/Secs_per_day );			#  45

$a->year(1876);  ok( $a eq "18761231132639" );				#  46
$a->month(7);    ok( $a eq "18760731132639" );				#  47
$a->day(13);     ok( $a eq "18760713132639" );				#  48
$a->hours(1);	 ok( $a eq "18760713012639" );				#  49
$a->minutes(49); ok( $a eq "18760713014939" );				#  50
$a->seconds(2);  ok( $a eq "18760713014902" );				#  51

$b = EmptySubclass->new();
foreach my $sec (0..60) {
  $a->seconds($sec);
  $b->set_from_serial_day( $a->serial_day() );
  ok( $a->internal() - $b->internal() == 0 );				#  52-112
}

my $now = time;

$a = EmptySubclass->new("1998. 4. 3 05:06:07");
ok( $a->asctime eq 'Fri Apr  3 05:06:07 GMT 1998' );			# 113
my %values = %{$a->_strftime_values};
ok( $values{'%'} eq '%' );						# 114
ok( $values{'a'} eq 'Fri' );						# 115
ok( $values{'A'} eq 'Friday' );						# 116
ok( $values{'b'} eq 'Apr' );						# 117
ok( $values{'B'} eq 'April' );						# 118
ok( $values{'c'} eq 'Fri Apr  3 05:06:07 GMT 1998' );			# 119
ok( $values{'C'} eq '19' );						# 120
ok( $values{'d'} eq '03' );						# 121
ok( $values{'D'} eq '04/03/98' );					# 122
ok( $values{'e'} eq ' 3' );						# 123
ok( $values{'f'} == 5 );						# 124
ok( $values{'F'} == 6 );						# 125
ok( $values{'g'} == 450367 );						# 126
ok( $values{'G'} eq '0951' );						# 127
ok( $values{'h'} eq 'Apr' );						# 128
ok( $values{'H'} eq '05' );						# 129
ok( $values{'I'} eq '05' );						# 130
ok( ($a + 10*60*60)->_strftime_values->{'I'} eq '03' );			# 131
ok( $values{'j'} eq '093' );						# 132
ok( $values{'k'} eq ' 5' );						# 133
ok( $values{'l'} eq ' 5' );						# 134
ok( $values{'m'} eq '04' );						# 135
ok( $values{'M'} eq '06' );						# 136
ok( $values{'n'} eq "\n" );						# 137
ok( $values{'p'} eq 'AM' );						# 138
ok( ($a + 12*60*60)->_strftime_values->{'p'} eq 'PM' );			# 139
ok( $values{'r'} eq '05:06:07 AM' );					# 140
ok( $values{'R'} eq '05:06' );						# 141
ok( $values{'s'} == 891579967 );					# 142
ok( $values{'S'} eq '07' );						# 143
ok( $values{'t'} eq "\t" );						# 144
ok( $values{'T'} eq '05:06:07' );					# 145
ok( $values{'u'} == 5 );						# 146
ok( $values{'U'} == 13 );						# 147
ok( EmptySubclass->new('1998 1  9')->_strftime_values->{'U'} eq '01' );	# 148
ok( EmptySubclass->new('1998 1 10')->_strftime_values->{'U'} eq '01' );	# 149
ok( EmptySubclass->new('1998 1 11')->_strftime_values->{'U'} eq '02' );	# 150
ok( EmptySubclass->new('1998 1 12')->_strftime_values->{'U'} eq '02' );	# 151
ok( $values{'V'} == 14);						# 152
ok( EmptySubclass->new('1993 1  1')->_strftime_values->{'V'} eq '53' );	# 153
ok( EmptySubclass->new('1993 1  2')->_strftime_values->{'V'} eq '53' );	# 154
ok( EmptySubclass->new('1993 1  3')->_strftime_values->{'V'} eq '53' );	# 155
ok( EmptySubclass->new('1993 1  4')->_strftime_values->{'V'} eq '01' );	# 156
ok( $values{'w'} == 5);							# 157
ok( $values{'W'} == 13);						# 158
ok( EmptySubclass->new('1998 1  9')->_strftime_values->{'W'} eq '01' );	# 159
ok( EmptySubclass->new('1998 1 10')->_strftime_values->{'W'} eq '01' );	# 160
ok( EmptySubclass->new('1998 1 11')->_strftime_values->{'W'} eq '01' );	# 161
ok( EmptySubclass->new('1998 1 12')->_strftime_values->{'W'} eq '02' );	# 162
ok( $values{'x'} eq '04/03/98' );					# 163
ok( $values{'X'} eq '05:06:07' );					# 164
ok( $values{'y'} eq '98' );						# 165
ok( $values{'Y'} eq '1998' );						# 166
ok( $values{'Z'} eq 'GMT' );						# 167
ok( JANUARY_1_1970->asctime eq 'Thu Jan  1 00:00:00 GMT 1970' ); 	# 168
ok( JANUARY_6_1980->asctime eq 'Sun Jan  6 00:00:00 GMT 1980' ); 	# 169

ok( $a->strftime("A%n%A B%B c%c Z%Z %% %g\n") eq "A\nFriday BApril cFri Apr  3 05:06:07 GMT 1998 ZGMT % 450367\n" ); # 170
ok( join('X', $a->get_time('YGg')) eq '1998X0951X450367' );		# 171

$a->set_gmtime_from_epoch_time($now);
ok( $a->_strftime_values->{'s'} == $now );				# 172

ok( $a->set_time('N') );						# 173
$a->set_time('YBDHMS', 1975, 9, 26, 13, 46, 53);
ok( $a->internal eq '19751026134653' );					# 174
$a->set_time('YBDHMS', 1975, 9, 26, 13, 46, 53.247);
ok( $a->internal eq '19751026134653.247' );				# 175
$a += 3;
ok( $a->internal eq '19751026134656.247' );				# 176
# Ensure that the fractional seconds are ignored when setting a new time.
$a->set_time('YBDHMS', 1975, 9, 26, 15, 46, 53);
ok( $a->internal eq '19751026154653' );					# 177
# Test the failure of set_time (the time should not change).
ok( !$a->set_time('NW') );						# 178
ok( $a->internal eq '19751026154653' );					# 179

# Test the GPS week and seconds.
$a = EmptySubclass->new;
$b = $a->new;
$b->clone($a);
my ($gps_week, $gps_seconds) = $a->gps_week_seconds_day;
$a->clone(JANUARY_1_1970);
$a->set_from_gps_week_seconds($gps_week, $gps_seconds);
ok( $a == $b );								# 180

# Test the comparisons of fractional times.
$a = EmptySubclass->new;
$b = $a->new;
$b->clone($a);
$b += 0.3333333333;
ok( $a != $b );								# 181
ok( $a < $b );								# 182
ok( $b > $a );								# 183
ok( $a ne $b );								# 184
ok( $a le $b );								# 185
ok( $b ge $a );								# 186

# Test the copy method.
$a->clone(JANUARY_1_1970);
$b->clone(JANUARY_6_1980);
ok( $a != $b );								# 187
ok( $a ne $b );								# 188
$b = $a->copy;
ok( $a == $b );								# 189
ok( $a eq $b );								# 190

# Test the new method that uses set_time.
$a = DateTime::Precise->new('YDHMS', 1998, 177, 9, 15, 26.5);
ok( $a->year    == 1998   );						# 191
ok( $a->month   ==    6   );						# 192
ok( $a->day     ==   26   );						# 193
ok( $a->hours   ==    9   );						# 194
ok( $a->minutes ==   15   );						# 195
ok( $a->seconds ==   26.5 );						# 196

# Test julian_day.
ok( abs($a->day_of_year - $a->julian_day - 1) < 1/Secs_per_day );	# 197
ok( abs($a->julian_day - 176.38572337963)     < 1/Secs_per_day );	# 198

# Test the new() taking a Unix epoch time.
$a = DateTime::Precise->new(1000000000);
ok( $a->year    == 2001 );						# 199
ok( $a->month   ==    9 );						# 200
ok( $a->day     ==    9 );						# 201
ok( $a->hours   ==    1 );						# 202
ok( $a->minutes ==   46 );						# 203
ok( $a->seconds ==   40 );						# 204
