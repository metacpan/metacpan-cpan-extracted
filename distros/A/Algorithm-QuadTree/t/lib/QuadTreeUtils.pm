package QuadTreeUtils;

use strict;
use warnings;
use Exporter qw(import);

use Test::More;

our @EXPORT = qw(
	zones_per_dimension
	object_name
	loop_zones
	init_zones
	check_array
	zone_bound
	zone_start
	zone_end
	AREA_SIZE
);

our $DEPTH = 3;
use constant AREA_SIZE => 10;

################################################################
# Some utilities helpful when testing the behavior of a quadtree
################################################################

sub zones_per_dimension
{
	return 2 ** ($DEPTH - 1);
}

sub _zone_rand
{
	my ($zone_number, $higher) = @_;
	$higher ||= 0;

	# do not inculde 0 in the randomness since we don't want to "touch" another zone
	my $rand = rand(0.99) + 0.01 + $higher;
	return zone_bound($zone_number) + $rand * AREA_SIZE / zones_per_dimension() / 2;
}

sub zone_bound
{
	my ($zone_number) = @_;
	return $zone_number * AREA_SIZE / zones_per_dimension;
}

sub zone_start
{
	my ($zone_number) = @_;
	return zone_bound($zone_number) + 0.0001;
}

sub zone_end
{
	my ($zone_number) = @_;
	return zone_bound($zone_number + 1) - 0.0001;
}

sub object_name
{
	my ($x_zone, $y_zone, $elnum) = @_;
	$elnum ||= 1;

	return join '_', 'obj', $x_zone, $y_zone, ($elnum == 1 ? () : $elnum);
}

sub loop_zones (&)
{
	my ($sub) = @_;

	my $zones_per_dimension = zones_per_dimension;

	return sub {
		for my $x_zone (0 .. $zones_per_dimension - 1) {
			for my $y_zone (0 .. $zones_per_dimension - 1) {
				$sub->($x_zone, $y_zone);
			}
		}
	};
}

sub init_zones
{
	my ($qt, $elements) = @_;
	$elements ||= 1;

	my $code = loop_zones {
		my ($x_zone, $y_zone) = @_;

		$qt->add(
			object_name($x_zone, $y_zone, $_),
			_zone_rand($x_zone),
			_zone_rand($y_zone),
			_zone_rand($x_zone, 1),
			_zone_rand($y_zone, 1),
		) for (1 .. $elements);
	};

	$code->();
}

sub check_array
{
	my ($list, $wanted_list, $more_info) = @_;
	$more_info ||= '';

	$list = [sort @$list];
	$wanted_list = [sort @$wanted_list];
	is_deeply $list, $wanted_list, "returned array ok$more_info";
}

1;

