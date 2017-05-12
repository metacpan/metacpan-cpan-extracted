use Test::More;
use Bot::BasicBot::Pluggable::Module::Assemble;

my $nick;

# create a mock bot
{
    no warnings;

    package Bot::BasicBot::Pluggable::Module;
    sub bot { bless {}, 'Bot::BasicBot' }

    package Bot::BasicBot;
    sub ignore_nick { $_[1] eq 'ignore_me' }
    sub nick {$nick}
}

# test the told() method
my @tests = (
    [   {   'body'     => 'hello bam',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'channel'  => '#zlonkbam',
            'raw_body' => 'hello bam',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'welcome here',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: welcome here',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'hi bam',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'hi bam',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'assemble bam blonk zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'channel'  => '#zlonkbam',
            'raw_body' => 'assemble bam blonk zlonk ',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'assemble bam blonk zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'assemble bam blonk zlonk ',
            '_nick'    => 'bam',
        } => '(?:b(?:lonk|am)|zlonk)'
    ],
    [   {   'body'     => 'assemble:bam:blonk:zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'assemble:bam:blonk:zlonk',
            '_nick'    => 'bam',
        } => '(?:b(?:lonk|am)|zlonk)'
    ],
    [   {   'body'     => 'assemble:bam:blonk:zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'ignore_me',                  # will be ignored
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'assemble:bam:blonk:zlonk',
            '_nick'    => 'bam',
        } => undef,
    ],
    [   {   'body'     => 'bam blonk zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'assemble',
            'channel'  => '#zlonkbam',
            'raw_body' => 'assemble bam blonk zlonk',
            '_nick'    => 'assemble',
        } => '(?:b(?:lonk|am)|zlonk)'
    ],
    [   {   'body'     => 'zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'assemble',
            'channel'  => '#zlonkbam',
            'raw_body' => 'assemble zlonk',
            '_nick'    => 'assemble',
        } => undef,
    ],
    [   {   'body'     => 'assemble zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: assemble zlonk',
            '_nick'    => 'bam',
        } => undef,
    ],
    [   {   'body'     => '++',
            'raw_nick' => 'BooK!~book@zlonk.bruhat.net',
            'who'      => 'BooK',
            'address'  => 'assemble',
            'channel'  => '#perlfr',
            'raw_body' => 'assemble++',
            '_nick'    => 'assemble',
        } => undef,
    ],
    [   {   'body'     => '*a*b',
            'raw_nick' => 'BooK!~book@zlonk.bruhat.net',
            'who'      => 'BooK',
            'address'  => 'assemble',
            'channel'  => '#perlfr',
            'raw_body' => 'assemble*a*b',
            '_nick'    => 'assemble',
        } => '[ab]',
    ],
);

plan tests => @tests + 1;

my $pkg = 'Bot::BasicBot::Pluggable::Module::Assemble';

# quick test of the help string
like( $pkg->help(), qr/assemble regex.*regex/, 'Basic usage line' );

for my $t (@tests) {
    $nick = delete $t->[0]{_nick};    # setup our nick
    is( $pkg->told( $t->[0] ),
        $t->[1],
        qq{Answer to "$t->[0]{raw_body}" on channel $t->[0]{channel}} );
}

