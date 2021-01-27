use Test::More tests => 5;
use Art::World;
use Faker;
use DDP;

my $f = Faker->new;

use_ok 'Art::World::Exhibition';

my $curator = Art::World->new_curator(
  name => $f->person_name );

my $m = Art::World->new_meta;
my $title = $m->titlify( $m->generate_discourse );

diag "This is a very nice " . $title;



my $exhibition = Art::World->new_exhibition(
  curator => [ $curator ],
  title   => $title,
 );

isa_ok $exhibition, 'Art::World::Work';
ok $exhibition->does( 'Art::World::Event' );

isa_ok $exhibition, 'Art::World::Work';
is $exhibition->title, $title;

done_testing();
