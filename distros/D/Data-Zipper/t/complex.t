use warnings FATAL => 'all';
use strict;
use Test::More;

use Data::Zipper 'zipper';

{
    package Person;
    use Moose;

    has name => ( is => 'ro' );
    has data => ( is => 'ro' );
}

my $john = Person->new(
    name => 'John',
    data => {
        colour => 'red'
    }
);

my $bob = zipper($john)
    ->traverse('name')->set('Bob')->up
    ->traverse('data')
      ->set_via(sub {
        zipper($_)
          ->traverse('colour')->set('blue')->zip;
      })
    ->zip;

is($bob->name => 'Bob');
is_deeply($bob->data => { colour => 'blue' });

done_testing;
