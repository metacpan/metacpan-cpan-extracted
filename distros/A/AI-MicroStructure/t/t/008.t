package AI::MicroStructure::test;
use strict;
use Test::More;
use AI::MicroStructure;

plan tests => 2;

$_ = 'canari';
my $data = AI::MicroStructure->load_data('AI::MicroStructure::test');
is( $_, 'canari', "load_data does not stomp the canari" );
is_deeply(
    $data,
    {   foo   => "bar",
        names => {
            en => "name on 3 lines",
            fr => "et en français",
        },
        long =>
            { chain => { empty => '', not => { empty => 'zlonk powie' } } },
        now => {
            test => {
                the =>
                    { slash => { too => 'zamm crr_aaack whamm clank boff' } }
            }
        },
    },
    "read DATA correctly"
);

__DATA__

# foo
bar
# names en
name
on 3
lines
# long chain empty
# long chain not empty
zlonk powie
# names fr
   et en
français
# now test/the/slash too
zamm crr_aaack whamm clank boff

