use Test::Most 0.25;

use Date::Easy;


# invalid dates

my %BAD_DATES =
(
	28999999		=>	qr/Illegal date/,								# looks like a datestring, but not valid date
	10000000		=>	qr/Illegal date/,								# looks like a datestring, but not valid date
	'2001-02-29'	=>	qr|Illegal date: 2001/2/29|,					# day doesn't exist (not a leap year)
	'06:43am'		=>	qr/Illegal date/,								# only a time
	bmoogle			=>	qr/Illegal date/,								# just completely bogus
);

my $t;
foreach (keys %BAD_DATES)
{
	throws_ok { $t = date($_) } $BAD_DATES{$_}, "found date error: $_" or diag("got date: $t");
}


# invalid datetimes

foreach (qw<
				bmoogle
		>)
{
	throws_ok { $t = datetime($_) } qr/Illegal datetime/, "found datetime error: $_" or diag("got datetime: $t");
}

throws_ok { Date::Easy::Datetime->new(2001, 2, 29, 0, 0, 0) }
		qr|Illegal datetime: 2001/2/29 0:0:0|, "catches exception from Time::Local";


# bad number of args when constructing a datetime

foreach (3,4,5,8,9)
{
	my @args = (1) x $_;
	throws_ok { Date::Easy::Datetime->new(@args) } qr/Illegal number of arguments/,
			"proper datetime ctor failure on $_ args";
}


# bad zone specifier when constructing a datetime

throws_ok { Date::Easy::Datetime->new(bmoogle => 0) } qr/Unrecognized timezone specifier/,
		"proper failure for bogus zonespec";


# convert _from_ an unknown class
my $bmoogle = bless {}, 'Bmoogle';

foreach (qw< Date::Easy::Date Date::Easy::Datetime >)
{
	throws_ok { $_->new($bmoogle) } qr/Don't know how to convert Bmoogle to $_/, "error on unknown conv to $_";
	throws_ok { $_->new($bmoogle) } qr/Don't know how to convert Bmoogle to $_/, "error on unknown conv to $_";
}


# convert _to_ an unknown class

# we don't have to worry about ::Date this time
# it just inherits the `as` method from ::Datetime
my $dt = now;
my $class = 'Date::Easy::Datetime';
throws_ok { $dt->as('Bmoogle') } qr/Don't know how to convert $class to Bmoogle/, "error on unknown conv from $class";


done_testing;
