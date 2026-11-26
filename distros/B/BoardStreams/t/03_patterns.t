use v5.44;
use Test::More;
use BoardStreams::Hub;
use Mojo::Pg;

my $hub = BoardStreams::Hub->new(pg => Mojo::Pg->new);    # never connects here
$hub->channel($_, join => sub { 1 })
    for 'lobby', 'chat:*', 'chat:eu:*', 'chat:*:*', 'chat:eu:lobby', 'game:*:chat', '*:admin', 'a.b', 'file*',
    'room:**', 'room:*', 'room:vip:**', '**:log', 'x:**:y', 'first:*:a', 'first:a:*';

sub pattern_for ($name) { ($hub->_spec($name) // {})->{pattern} }

my @cases = (
    ['lobby'          => 'lobby',         'a name without "*" covers only itself'],
    ['lobbyx'         => undef,           '...and nothing longer'],
    ['chat:lobby'     => 'chat:*',        '"*" covers a run of characters'],
    ['chat:'          => 'chat:*',        '"*" may cover nothing'],
    ['chat'           => undef,           'the literal parts are required'],
    ['chat:us:lobby'  => 'chat:*:*',      '"*" stops at a colon, so two are needed for two parts'],
    ['chat:eu:berlin' => 'chat:eu:*',     'the longest pattern that covers a name wins'],
    ['chat:eu:lobby'  => 'chat:eu:lobby', 'an exact name wins over any pattern'],
    ['chat:a:b:c'     => undef,           'no pattern covers three parts'],
    ['game:42:chat'   => 'game:*:chat',   '"*" in the middle'],
    ['game:4:2:chat'  => undef,           '...still stops at a colon'],
    ['users:admin'    => '*:admin',       '"*" at the start'],
    ['a:b:admin'      => undef,           '...still stops at a colon'],
    ['axb'            => undef,           'other characters have no special meaning'],
    ['file-1.txt'     => 'file*',         '"*" covers anything but a colon'],
    ["file\n1"        => 'file*',         '...including a newline'],
    ['file:1'         => undef,           '...but not a colon'],
    ['room:a:b:c'     => 'room:**',       '"**" covers colons too'],
    ['room:'          => 'room:*',        '"**" may cover nothing, but "*" is preferred when both cover a name'],
    ['room:a'         => 'room:*',        '...so "*" wins over "**" for a single part'],
    ['room:vip:a:b'   => 'room:vip:**',   'more literal characters win'],
    ['room'           => undef,           'the literal parts are required with "**" as well'],
    ['a:b:log'        => '**:log',        '"**" at the start'],
    ['x:1:2:y'        => 'x:**:y',        '"**" in the middle'],
    ['x:y'            => undef,           '...needs both of its colons'],
    ['first:a:a'      => 'first:*:a',     'a full tie goes to the pattern registered first'],
);
is pattern_for($_->[0]), $_->[1], $_->[2] for @cases;

done_testing;
