use warnings;
use strict;

use Params::Classify qw(is_ref);
use Test::More tests => 33;

BEGIN { use_ok "App::olson"; }

sub pa($) {
	my($txt) = @_;
	pos($txt) = undef;
	my $attr = App::olson::_parse_attribute_from_gmatch(\$txt);
	$txt =~ /\G\z/gc or die "extraneous matter after attribute\n";
	return $attr;
}

sub san($) {
	return $_[0] unless is_ref($_[0], "HASH");
	my %attr = %{$_[0]};
	foreach(keys %attr) {
		$attr{$_} = "CODE" if is_ref($attr{$_}, "CODE");
	}
	return \%attr;
}

eval { pa("") };
is $@, "missing attribute name\n";

eval { pa("\@now") };
is $@, "missing attribute name\n";

eval { pa("foo") };
is $@, "no such attribute class `foo'\n";

eval { pa("foo\@now") };
is $@, "no such attribute class `foo'\n";

my $a = pa("z");
is_deeply san($a), {
	type => $App::olson::type{zone_name},
	check_value => "CODE",
	cost => 0,
	get_needs => { z=>undef },
	xget => "CODE",
};
is $a->{xget}->({ z=>"Europe/London" }), "Europe/London";
is_deeply san(pa("zone_name")), san($a);

$a = pa("a");
is_deeply san($a), {
	type => $App::olson::type{area_name},
	check_value => "CODE",
	cost => 1,
	get_needs => { z=>undef },
	xget => "CODE",
};
is $a->{xget}->({ z=>"Europe/London" }), "Europe";
is_deeply san(pa("area_name")), san($a);

$a = pa("c");
is_deeply san($a), {
	type => $App::olson::type{country_code},
	check_value => "CODE",
	cost => 0,
	get_needs => { c=>undef },
	xget => "CODE",
};
is $a->{xget}->({ c=>"GB" }), "GB";
is_deeply san(pa("country_code")), san($a);

$a = pa("cn");
is_deeply san($a), {
	type => $App::olson::type{string},
	check_value => "CODE",
	cost => 1,
	get_needs => { c=>undef },
	xget => "CODE",
};
is_deeply san(pa("country_name")), san($a);

$a = pa("rd");
is_deeply san($a), {
	type => $App::olson::type{string},
	check_value => "CODE",
	cost => 1,
	get_needs => { region=>undef },
	xget => "CODE",
};
is_deeply $a->{xget}->({ region=>{
	location_coords => "+513030-0000731",
	olson_description => "Frobnitzshire",
	timezone_name => "Europe/Frobnitz",
} }), \"Frobnitzshire";
is_deeply san(pa("region_description")), san($a);

$a = pa("k");
is_deeply san($a), {
	type => $App::olson::type{zone_name},
	check_value => "CODE",
	cost => 1,
	get_needs => { z=>undef },
	xget => "CODE",
};
is_deeply san(pa("canonical_zone_name")), san($a);

eval { pa("z\@now") };
is $@, "unwanted `\@' parameter for timezone name attribute\n";

eval { pa("o") };
is $@, "offset attribute needs a `\@' parameter\n";

eval { pa("o\@now\@now") };
is $@, "clashing `\@' parameters for offset attribute\n";

$a = pa("o\@now");
is_deeply san($a), {
	type => $App::olson::type{offset},
	check_value => "CODE",
	cost => 10,
	get_needs => { z=>undef },
	xget => "CODE",
};
is_deeply san(pa("o  \@  now")), san($a);
is_deeply san(pa("offset\@now")), san($a);

$a = pa("i\@now");
is_deeply san($a), {
	type => $App::olson::type{initialism},
	check_value => "CODE",
	cost => 10,
	get_needs => { z=>undef },
	xget => "CODE",
};
is_deeply san(pa("initialism\@now")), san($a);

$a = pa("d\@now");
is_deeply san($a), {
	type => $App::olson::type{truth},
	check_value => "CODE",
	cost => 10,
	get_needs => { z=>undef },
	xget => "CODE",
};
is_deeply san(pa("dst_status\@now")), san($a);

$a = pa("t\@now");
is_deeply san($a), {
	type => $App::olson::type{calendar_time},
	check_value => "CODE",
	cost => 11,
	get_needs => { z=>undef },
	xget => "CODE",
};
is_deeply san(pa("local_time\@now")), san($a);

1;
