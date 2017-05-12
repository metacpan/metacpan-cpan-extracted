use Test::Most 0.25;


my @proglets;

push @proglets, <<'---';
	# no calls to date()
	use Date::Easy;

	# at this point, very little should be loaded:
	# Time::Piece, Time::Local, perhaps a few others
	# but definitely not any of our load-on-demand modules

	foreach (qw< Date::Parse Time::ParseDate >)
	{
		(my $path = $_) =~ s|::|/|g;
		die("loaded $_") if exists $INC{"$path.pm"};
	}
---

push @proglets, <<'---';
	# call to date() with epoch seconds
	use Date::Easy;

	# this shouldn't load anything either
	date(-99601200);

	foreach (qw< Date::Parse Time::ParseDate >)
	{
		(my $path = $_) =~ s|::|/|g;
		die("loaded $_") if exists $INC{"$path.pm"};
	}
---

push @proglets, <<'---';
	# call to date() with datestring
	use Date::Easy;

	# this should load Date::Parse, but not Time::ParseDate
	date("20010101");

	foreach (qw< Time::ParseDate >)
	{
		(my $path = $_) =~ s|::|/|g;
		die("loaded $_") if exists $INC{"$path.pm"};
	}
---

push @proglets, <<'---';
	# call to date() with digitless string
	use Date::Easy;

	# this should load Time::ParseDate, but not Date::Parse
	date("today");

	foreach (qw< Date::Parse >)
	{
		(my $path = $_) =~ s|::|/|g;
		die("loaded $_") if exists $INC{"$path.pm"};
	}
---


# now for the actual tests
my $perl = $^X;
foreach (@proglets)
{
	my ($tname) = /^\s*#\s*(.*?)$/m;
	ok !system($perl, '-Ilib', '-e', $_), "proper modules loaded: $tname";
}


done_testing;
