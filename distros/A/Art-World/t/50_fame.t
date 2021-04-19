use Test::More;
use Art::World;
use Art::World::Util;

my $rep = 1.7;

my $artist = Art::World->new_artist(
  reputation => $rep,
  name => Art::World::Util->new_person->fake_name,
);

ok $artist->does('Art::World::Fame'), 'Artist does the Fame role';
can_ok $artist, 'bump_fame';

diag 'Error messages displayed during tests are part of the testing process';

my $reputation = $artist->bump_fame;
is $reputation, $rep + 1, 'Artist reputation got bumped without parameter';
$reputation = $artist->bump_fame( 0.4 );
is $reputation, $rep + 1 + 0.4, 'Artist reputation got bumped positively';
$reputation = $artist->bump_fame( -1.4 );
is $reputation, $rep, 'Artist reputation got bumped negatively';
$reputation = $artist->bump_fame( 12.1212 );
is $reputation, $rep + 12.1212, 'Using a weird 4 digits floating point';
$reputation = $artist->bump_fame( -0.1212 );
$reputation = $artist->bump_fame( -12 );
is $reputation, $rep, 'Reputation back to it\'s previous value after calculating with 4 digits floating point';
$reputation = $artist->bump_fame( 0.1212 );
$reputation = $artist->bump_fame( 12 );
my $smoll = -0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001;
$reputation = $artist->bump_fame( $smoll );
is $reputation, $rep + 0.1212 + 12 - $smoll, 'Looks like extreme floating point stability';
$reputation = $artist->bump_fame( -0.1212 - 12 + $smoll );
my $large = 1_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000;
$reputation = $artist->bump_fame( $large );
is $reputation, $rep + $large , 'Even large numbers are fine';
$reputation = $artist->bump_fame( -$large );
$reputation = $artist->bump_fame( -100 );
$reputation = $artist->bump_fame(2);

is $artist->reputation, 2,
  'Fame role is correctly applied to Agents through reputation attribute';

eval { $artist->aura };  #,
diag $@;
like $@, qr/Can't locate object method "aura" via package "Art::World::Artist"/,
  'Artists don\'t have an aura attribute';

my $artist_2 = Art::World->new_artist(
  id => 1,
  name => Art::World::Util->new_person->fake_name,
 );

my $munnies= 100;

my $collector1 = Art::World
        ->new_collector(
            name => Art::World::Util->new_person->fake_name,
            money => $munnies,
            id => 3
          );

my $collector2 = Art::World
        ->new_collector(
            name => Art::World::Util->new_person->fake_name,
            money => $munnies + 1000,
            id => 4
          );

my $homogenic_artist = Art::World->new_artist(
    name => Art::World::Util->new_person->fake_name,
    collectors => [ $collector1, $collector2 ]
  );

my $artwork = Art::World->new_artwork(
    creator => [ $artist_2, $homogenic_artist ]  ,
    title => 'Naked City',
    value => 10_000,
    owner => [ $collector1, $collector2 ],
    aura => 0,
  );

ok $artwork->bump_fame, 'Artwork fame got bumped';

is $artwork->aura, 1,
  'Fame role is correctly applied to Works through aura attribute';

eval { $artwork->reputation }; #,
diag $@;
like $@, qr/Can't locate object method "reputation" via package "Art::World::Artwork"/,
  'Works don\'t have a reputation attribute';


done_testing;
