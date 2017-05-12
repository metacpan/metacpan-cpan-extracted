#!perl -T

use Test::More tests => 13;

BEGIN {
	use_ok( 'Algorithm::SixDegrees' );
}

my $movie_actor_hash = {
	'A Few Good Men' => [ 'Kevin Bacon', 'Tom Cruise', 'Jack Nicholson' ],
	'Mystic River' => [ 'Kevin Bacon', 'Laurence Fishburne', 'Tim Robbins' ],
	'Shawshank Redemption, The' => [ 'Tim Robbins', 'Morgan Freeman' ],
	'Se7en' => [ 'Brad Pitt', 'Morgan Freeman', 'Kevin Spacey' ],
	'Fight Club' => [ 'Brad Pitt', 'Edward Norton' ],
};

my $sd = new Algorithm::SixDegrees;
isa_ok($sd,'Algorithm::SixDegrees');

my $hitcount = 0;

$sd->data_source( Movie => \&Simple_Movie, $movie_actor_hash, \$hitcount );
$sd->data_source( Actor => \&Simple_Actor, $movie_actor_hash, \$hitcount );

is_deeply([$sd->make_link('Actor','Kevin Bacon','Pete Krawczyk')],[],'No match OK');
is($Algorithm::SixDegrees::ERROR,undef,'No error during make_link');
is_deeply([$sd->make_link('Actor','Kevin Bacon','Kevin Bacon')],['Kevin Bacon'],'Single element link OK');
is($Algorithm::SixDegrees::ERROR,undef,'No error during make_link');
is_deeply([$sd->make_link('Actor','Kevin Bacon','Tom Cruise')],['Kevin Bacon','A Few Good Men','Tom Cruise'],'Double element link OK');
is($Algorithm::SixDegrees::ERROR,undef,'No error during make_link');
is_deeply([$sd->make_link('Actor','Tom Cruise','Tim Robbins')],
	['Tom Cruise','A Few Good Men','Kevin Bacon','Mystic River','Tim Robbins'],
	'Triple element link OK');
is($Algorithm::SixDegrees::ERROR,undef,'No error during make_link');
is_deeply([$sd->make_link('Actor','Tom Cruise','Edward Norton')],
	['Tom Cruise', 'A Few Good Men', 'Kevin Bacon', 'Mystic River', 'Tim Robbins', 'Shawshank Redemption, The',
		'Morgan Freeman', 'Se7en', 'Brad Pitt', 'Fight Club', 'Edward Norton' ],
	'6 element link OK');
is($Algorithm::SixDegrees::ERROR,undef,'No error during make_link');
cmp_ok($hitcount, '>', 0, 'hitcount was incremented throughout');

exit(0);

sub Simple_Movie {
	my $element = shift;
	my $movie_actor_hash = shift;
	my $hitcount = shift;
	${$hitcount}++;
	return unless exists($movie_actor_hash->{$element});
	return @{$movie_actor_hash->{$element}};
}

sub Simple_Actor {
	my $element = shift;
	my $movie_actor_hash = shift;
	my $hitcount = shift;
	${$hitcount}++;
	my @movies = ();
	MOVIE: foreach my $movie (keys %{$movie_actor_hash}) {
		foreach my $actor (@{$movie_actor_hash->{$movie}}) {
			if ($actor eq $element) {
				push(@movies, $movie);
				next MOVIE;
			}
		}
	}
	return @movies;
}
