use warnings FATAL => 'all';
use strict;
use Test::More;

use Data::Zipper 'zipper';

my $input = {
    what => {
        goes => 'in'
    },
    LEAVE => [qw( ME ALONE )],
};

my $output = zipper($input)
    ->traverse('what')
      ->traverse('goes')
        ->set('out')
   ->zip;

is_deeply($output, {
    what => {
        goes => 'out'
    },
    LEAVE => [qw( ME ALONE )],
});

is($output->{LEAVE}, $input->{LEAVE});

done_testing;
