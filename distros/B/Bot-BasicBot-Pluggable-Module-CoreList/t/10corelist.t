use Test::More;
use Bot::BasicBot::Pluggable::Module::CoreList;
use strict;

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

my $datadumper = 'Data::Dumper was first released with perl 5.005 (released on 1998-07-22)';
my $large_search = join ', ',
    ( Module::CoreList->find_modules(qr/e/) )[ 0 .. 8 ], '...';
my $large_search_56 = join ', ',
    ( Module::CoreList->find_modules( qr/e/, '5.006' ) )[ 0 .. 8 ], '...';

diag "Testing with Module::CoreList version $Module::CoreList::VERSION";

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
    [   {   'body'     => 'corelist bam blonk zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'channel'  => '#zlonkbam',
            'raw_body' => 'corelist bam blonk zlonk ',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'corelist Data::Dumper',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'corelist Data::Dumper ',
            '_nick'    => 'bam',
        } => $datadumper,
    ],
    [   {   'body'     => 'corelist: release Data::Dumper',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'corelist: release Data::Dumper',
            '_nick'    => 'bam',
        } => $datadumper,
    ],
    [   {   'body'     => 'corelist:Data::Dumper',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'corelist:Data::Dumper',
            '_nick'    => 'bam',
        } => $datadumper,
    ],
    [   {   'body'     => 'corelist:Bam::Blonk::Zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'ignore_me',                  # will be ignored
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'corelist:Bam::Blonk::Zlonk',
            '_nick'    => 'bam',
        } => undef,
    ],
    [   {   'body'     => 'Bam::Blonk::Zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'corelist',
            'channel'  => '#zlonkbam',
            'raw_body' => 'corelist Bam::Blonk::Zlonk',
            '_nick'    => 'corelist',
        } => 'Bam::Blonk::Zlonk is not in the core',
    ],
    [   {   'body'     => 'date Bam::Blonk::Zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'corelist',
            'channel'  => '#zlonkbam',
            'raw_body' => 'corelist date Bam::Blonk::Zlonk',
            '_nick'    => 'corelist',
        } => 'Bam::Blonk::Zlonk is not in the core',
    ],
    [   {   'body'     => 'zlonk',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'corelist',
            'channel'  => '#zlonkbam',
            'raw_body' => 'corelist zlonk',
            '_nick'    => 'corelist',
        } => 'zlonk is not in the core',
    ],
    [   {   'body'     => 'corelist search Bench',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: corelist search Bench',
            '_nick'    => 'bam',
        } => 'Found Benchmark',
    ],
    [   {   'body'     => 'corelist find Data 5.006',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: corelist find Data 5.006',
            '_nick'    => 'bam',
        } => 'Found Data::Dumper in perl 5.006',
    ],
    [   {   'body'     => 'corelist search e',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: corelist search e',
            '_nick'    => 'bam',
        } => "Found $large_search",
    ],
    [   {   'body'     => 'corelist search e 5.006',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: corelist search e 5.006',
            '_nick'    => 'bam',
        } => "Found $large_search_56 in perl 5.006",
    ],
    [   {   'body'     => 'corelist search xyzzy',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: corelist search xyzzy',
            '_nick'    => 'bam',
        } => 'Found no module matching /xyzzy/',
    ],
    [   {   'body'     => 'corelist search xyzzy 5.006',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam: corelist search xyzzy 5.006',
            '_nick'    => 'bam',
        } => 'Found no module matching /xyzzy/ in perl 5.006',
    ],
    [   {   'body'     => 'corelist date vars',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam corelist date vars ',
            '_nick'    => 'bam',
        } => 'vars was first released with perl 5.002 (released on 1996-02-29)',
    ],
    [   {   'body'     => 'corelist CPANPLUS::inc',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam corelist CPANPLUS::inc',
            '_nick'    => 'bam',
        } => $Module::CoreList::VERSION >= 2.32 ? 'CPANPLUS::inc was first released with perl 5.009005 (released on 2007-07-07) and removed from perl 5.010001 (released on 2009-08-22)'
           : 'CPANPLUS::inc was first released with perl 5.009005 (released on 2007-07-07)'
    ],
    [   {   'body'     => 'corelist Switch',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'bam',
            'channel'  => '#zlonkbam',
            'raw_body' => 'bam corelist Switch',
            '_nick'    => 'bam',
        } => $Module::CoreList::VERSION >= 2.77 ? 'Switch was first released with perl 5.007003 (released on 2002-03-05), deprecated in perl 5.011 (released on 2009-10-02) and removed from perl 5.013001 (released on 2010-05-20)'
           : $Module::CoreList::VERSION >= 2.32 ? 'Switch was first released with perl 5.007003 (released on 2002-03-05) and removed from perl 5.013001 (released on 2010-05-20)'
           : 'Switch was first released with perl 5.007003 (released on 2002-03-05)',
    ],
);

plan tests => @tests + 1;

my $pkg = 'Bot::BasicBot::Pluggable::Module::CoreList';

# quick test of the help string
like( $pkg->help(), qr/corelist \[release\] module/, 'Basic usage line' );

for my $t (@tests) {
    $nick = delete $t->[0]{_nick};    # setup our nick
    is( $pkg->told( $t->[0] ),
        $t->[1],
        qq{Answer to "$t->[0]{raw_body}" on channel $t->[0]{channel}} );
}

