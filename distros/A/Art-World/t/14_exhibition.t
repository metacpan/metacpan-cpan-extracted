use Test::More;
use Art::World;
use Art::World::Util;

my $person = Art::World::Util->new_person;

my $curator = Art::World->new_curator(
  name => $person->fake_name );

my $string = Art::World::Util->new_string;

my $title = $string->titlify( $person->generate_discourse );

diag "This is a very nice " . $title;

my $exhibition = Art::World->new_exhibition(
  curator => [ $curator ],
  title   => $title,
  creator => [ $curator ]
 );

isa_ok $exhibition, 'Art::World::Work';
ok $exhibition->does( 'Art::World::Event' );

isa_ok $exhibition, 'Art::World::Work';
is $exhibition->title, $title;

done_testing;
