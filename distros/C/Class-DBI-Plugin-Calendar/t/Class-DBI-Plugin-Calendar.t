# gratefully lifted from Class::DBI::Plugin::CountSearch
use strict;

use Test::More;
use DBI;

my @DSN;
my $dbh;

BEGIN {
	my $dbname = $ENV{DBD_MYSQL_DBNAME}	|| 'test';
	my $db		= "dbi:mysql:$dbname";
	my $user	=  $ENV{DBD_MYSQL_USER}		|| '';
	my $pass	=  $ENV{DBD_MYSQL_PASSWD}	|| '';

	@DSN = ($db, $user, $pass, {RaiseError=>1});

	eval {
		$dbh = DBI->connect(@DSN) or die $DBI::errstr;
		$dbh->do(qq[ DROP TABLE IF EXISTS movies ]);
		$dbh->do(qq[
		     CREATE TABLE movies (
    	    	id     int(2) unsigned not null primary key auto_increment,
    	    	title  VARCHAR(255),
    	    	date   DATETIME
    		 )
		]) or die $DBI::errstr;
	};
	plan $@ ? (skip_all => 'needs a mysql account with create/drop table privs for testing') : (tests => 5);
}

# clean the db
END {
	$dbh->do(q{ DROP TABLE movies });
};


package My::Film;

use base 'Class::DBI';
use Class::DBI::Plugin::Calendar qw(date);

__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('movies');
__PACKAGE__->columns(All => qw/id title date/);

__PACKAGE__->has_a(date => 'Time::Piece',
	inflate => sub { Time::Piece->strptime(shift,'%Y-%m-%d %H:%M:%S') },
	deflate => sub { shift->strftime('%Y-%m-%d %H:%M:%S') },
);

package main;

my @lt = localtime;
$lt[4] = sprintf '%02d', $lt[4] + 1;
$lt[5] += 1900;

# other month
my $om = $lt[4] == 12 ? 11 : 12;

# other year
my $oy = $lt[5] == 2004 ? 2005 : 2004;

my %films = (

		# example
	Veronique => '1991-01-01 00:00:00',

		# this month
	Rocky     => "$lt[5]-$lt[4]-01 00:00:00",
	Nashville => "$lt[5]-$lt[4]-01 12:00:00",
	Ape       => "$lt[5]-$lt[4]-02 00:00:00",
	JFK       => "$lt[5]-$lt[4]-03 00:00:00",

		# other month
	Jaws      => "$lt[5]-$om-01 00:00:00",
	Manhattan => "$lt[5]-$om-01 01:00:00",
	Network   => "$lt[5]-$om-01 02:00:00",

		# other year
	Red       => "$oy-$om-01 00:00:00",
	White     => "$oy-$om-01 01:00:00",
	Blue      => "$oy-$om-01 02:00:00",
	Dekalog   => "$oy-$om-01 03:00:00",
	Hospital  => "$oy-$om-01 04:00:00",
	Heaven    => "$oy-$om-01 05:00:00",
);

while (my ($title, $year) = each %films) {
	My::Film->create({ title => $title, date => $year });
}

{
	my @films = My::Film->retrieve_all;
	is @films, 14, "Got 14 films";
}

# no args
{
	my @weeks = My::Film->calendar;
	my $ok = 1;

	my($one) = grep { $_->ok && $_->date->mday == 1 } grep $_->ok, @{$weeks[0]};
	my(@one) = $one->agenda;
	$ok = 0 unless @one == 2;
	$ok = 0 unless $one[0]->title eq 'Rocky';
	$ok = 0 unless $one[1]->title eq 'Nashville';

	my($two) = grep { $_->ok && $_->date->mday == 2 } (@{$weeks[0]},@{$weeks[1]});
	my(@two) = $two->agenda;
	$ok = 0 unless @two == 1 and $two[0]->title eq 'Ape';

	my($thr) = grep { $_->ok && $_->date->mday == 3 } (@{$weeks[0]},@{$weeks[1]});
	my(@thr) = $thr->agenda;
	$ok = 0 unless @thr == 1 and $thr[0]->title eq 'JFK';

	ok($ok,"calendar()");
}

# month
{
	my @weeks = My::Film->calendar($om);
	my $ok = 1;

	my($one) = grep { $_->date->mday == 1 } grep $_->ok, @{$weeks[0]};
	my(@one) = $one->agenda;
	$ok = 0 unless @one == 3;
	$ok = 0 unless $one[0]->title eq 'Jaws';
	$ok = 0 unless $one[1]->title eq 'Manhattan';
	$ok = 0 unless $one[2]->title eq 'Network';

	ok($ok,'calendar($m)');
}

# year
my $day1 = 0;
{
	my @weeks = My::Film->calendar($om,$oy);
	my $ok = 1;

	for(my $count = 0; $count < @{$weeks[0]}; $count++) {
		next unless $weeks[0]->[$count]->ok && $weeks[0]->[$count]->date->mday == 1;
		$day1 = $count;
		last;
	}

	my($one) = grep { $_->date->mday == 1 } grep $_->ok, @{$weeks[0]};
	my(@one) = $one->agenda;
	$ok = 0 unless @one == 6;
	$ok = 0 unless $one[0]->title eq 'Red';
	$ok = 0 unless $one[1]->title eq 'White';
	$ok = 0 unless $one[2]->title eq 'Blue';
	$ok = 0 unless $one[3]->title eq 'Dekalog';
	$ok = 0 unless $one[4]->title eq 'Hospital';
	$ok = 0 unless $one[5]->title eq 'Heaven';

	ok($ok,'calendar($m,$y)');
}

# mondays
$day1 ||= 7; # re-order if the 1st is a Sunday
{
	my @weeks = My::Film->calendar($om,$oy,1);
	
	my $m1 = 0;
	for(my $count = 0; $count < @{$weeks[0]}; $count++) {
		next unless $weeks[0]->[$count]->ok && $weeks[0]->[$count]->date->mday == 1;
		$m1 = $count + 1;
		last;
	}

	ok($m1 == $day1,'calendar($m,$y,1)');
}


__END__

{
	my $count1976 = My::Film->count_search('date' => '1976');
	is $count1976, 4, "Got 4 1976 films";
}
