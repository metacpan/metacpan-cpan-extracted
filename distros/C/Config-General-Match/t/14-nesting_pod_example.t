
use strict;
use warnings;

use Test::More 'no_plan';

use Config::General::Match;

my $conf_text = <<EOF;
    <Story Three Little Pigs>
        antagonist = Big Bad Wolf
        moral      = obey the protestant work ethic
    </Story>

    <Location /aesop>
        <Story Wolf in Sheep's Clothing>
            antagonist = Big Bad Wolf
            moral      = appearances are deceptive
        </Story>
    </Location>

    <Story Little Red Riding Hood>
        antagonist = Big Bad Wolf

        <Location /perrault>
            moral      = never talk to strangers
        </Location>

        <Location /grimm>
            moral      = talk to strangers and then chop them up
        </Location>
    </Story>
EOF

my $conf = Config::General::Match->new(
    -MatchSections => [
        {
            -Name        => 'Story',
            -MatchType   => 'substring',
            -SectionType => 'story',
        },
        {
            -Name        => 'Location',
            -MatchType   => 'path',
            -SectionType => 'path',
        },
    ],
    -String => $conf_text,
);

my $depth = 2;
my $config = $conf->getall_matching_nested(
        $depth,
        story => 'Wolf in Sheep\'s Clothing',
        path  => '/aesop/wolf-in-sheeps-clothing',
);

my $expected = {
    'antagonist' => 'Big Bad Wolf',
    'moral'      => 'appearances are deceptive'
};

ok(scalar(keys %$config) == 2,                        'keys');
is($config->{'antagonist'}, 'Big Bad Wolf',           'antagonist');
is($config->{'moral'}, 'appearances are deceptive',   'moral');


