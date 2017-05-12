use Test::More;
use List::Util;
use Bot::BasicBot::Pluggable::Module::MetaSyntactic;

my $nick;

# "alter" the shuffle method
BEGIN {
    no warnings;
    my ( $i, $j ) = ( 0, 0 );
    *List::Util::shuffle = sub { sort @_ };    # item selection
    *Acme::MetaSyntactic::any::shuffle =       # theme selection
        sub (@) { my @t = sort @_; push @t, shift @t for 1 .. $j; $j++; @t };
}

# create a mock bot
{
    no warnings;

    package Bot::BasicBot::Pluggable::Module;
    sub bot { bless {}, 'Bot::BasicBot' }

    package Bot::BasicBot;
    sub ignore_nick { $_[1] eq 'ignore_me' }
    sub nick {$nick}
}

# add a theme with a category having a dash in its name
package Acme::MetaSyntactic::bbpmm_category;
use Acme::MetaSyntactic::MultiList;
our @ISA = ('Acme::MetaSyntactic::MultiList');
__PACKAGE__->init(
    {   default => 'basic',
        names   => {
            'x-dashed' => "Saturn Earth Neptune",
            basic      => "ununoctium manganese thallium",
        }
    }
);

# this is so ugly...
$Acme::MetaSyntactic::META{bbpmm_category} = 1;

package main;

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
    [   {   'body'     => 'meta batman',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'channel'  => '#zlonkbam',
            'raw_body' => 'meta batman',
            '_nick'    => 'bam',
        } => undef
    ],
    [   {   'body'     => 'meta foo',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo',
            '_nick'    => 'bam',
        } => 'bar'
    ],
    [   {   'body'     => 'meta: foo 2',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo 2',
            '_nick'    => 'bam',
        } => 'baz corge'
    ],
    [   {   'body'     => 'meta: foo 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo 0',
            '_nick'    => 'bam',
        } => 'bar baz corge foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy'
    ],
    [   {   'body'     => '++',
            'raw_nick' => 'BooK!~book@zlonk.bruhat.net',
            'who'      => 'BooK',
            'address'  => 'meta',
            'channel'  => '#perlfr',
            'raw_body' => 'meta++',
            '_nick'    => 'meta',
        } => undef,
    ],
    [   {   'body'     => 'meta foo/fr',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo/fr',
            '_nick'    => 'bam',
        } => 'bidon'
    ],
    [   {   'body'     => 'meta foo/fr 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo/fr 0',
            '_nick'    => 'bam',
        } => 'bidon bidule chose chouette machin pipo tata test1 test2 test3 titi toto truc tutu'
    ],
    [   {   'body'     => 'meta foo/fr 3',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo/fr 3',
            '_nick'    => 'bam',
        } => 'bidule chose chouette'
    ],
    [   {   'body'     => 'meta themes?',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta themes?',
            '_nick'    => 'bam',
        } => join( ' ', 1 + Acme::MetaSyntactic->themes, 'themes available:', sort bbpmm_theme => Acme::MetaSyntactic->themes )
    ],
    [   {   'body'     => 'meta this_theme_does_not_exist',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta this_theme_does_not_exist',
            '_nick'    => 'bam',
        } => 'No such theme: this_theme_does_not_exist'
    ],
    [   {   'body'     => 'meta foo 102',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo 102',
            '_nick'    => 'bam',
        } => 'foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy bar baz corge foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy bar baz corge foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy bar baz corge foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy bar baz corge foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy bar baz corge foo foobar fred fubar garply grault plugh quux qux thud waldo xyzzy bar baz corge foo foobar fred fubar garply grault plugh quux qux thud'
    ],
    [   {   'body'     => 'meta categories? foo',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta categories? foo',
            '_nick'    => 'bam',
        } => 'Categories for foo: en fr nl'
    ],
    [   {   'body'     => 'meta categories? contributors',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta categories? contributors',
            '_nick'    => 'bam',
        } => 'Theme contributors does not have any categories'
    ],
    [   {   'body'     => 'meta categories? this_theme_does_not_exist',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta categories? this_theme_does_not_exist',
            '_nick'    => 'bam',
        } => 'No such theme: this_theme_does_not_exist'
    ],
    [   {   'body'     => 'meta foo/de 3',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta foo/de 3',
            '_nick'    => 'bam',
        } => 'No such theme/category: foo/de'
    ],
    [   {   'body'     => 'meta bbpmm_theme 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta bbpmm_theme 0',
            '_nick'    => 'bam',
        } => join ' ', (sort 'a'..'dx')[0..99]
    ],
    [   {   'body'     => 'meta: foo /bar/',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /bar/',
            '_nick'    => 'bam',
        } => 'bar'
    ],
    [   {   'body'     => 'meta: foo /bar/ 2',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /bar/ 2',
            '_nick'    => 'bam',
        } => 'bar foobar'
    ],
    [   {   'body'     => 'meta: foo /bar/ 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /bar/ 0',
            '_nick'    => 'bam',
        } => 'bar foobar fubar'
    ],
    [   {   'body'     => 'meta: foo /^ba/ 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /^ba/ 0',
            '_nick'    => 'bam',
        } => 'bar baz'
    ],
    [   {   'body'     => 'meta: foo /^ba/ 4',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /^ba/ 4',
            '_nick'    => 'bam',
        } => 'bar baz bar baz'
    ],
    [   {   'body'     => 'meta: foo /v/ 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /v/ 0',
            '_nick'    => 'bam',
        } => ''
    ],
    [   {   'body'     => 'meta: foo /v/',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /v/',
            '_nick'    => 'bam',
        } => ''
    ],
    [   {   'body'     => 'meta: foo /v/ 4',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /v/ 4',
            '_nick'    => 'bam',
        } => ''
    ],
    [   {   'body'     => 'meta: foo /*bar/ 0',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo /*bar/ 0',
            '_nick'    => 'bam',
        } => 'Quantifier follows nothing in regex; marked by <-- HERE in m/* <-- HERE bar/'
    ],
    [   {   'body'     => 'meta: foo bar baz',
            'raw_nick' => 'BooK!~book@d83-179-185-40.cust.tele2.fr',
            'who'      => 'BooK',
            'address'  => 'msg',
            'channel'  => 'msg',
            'raw_body' => 'meta: foo bar baz',
            '_nick'    => 'bam',
        } => undef
    ],
);

plan tests => @tests + 1;

my $bot = Bot::BasicBot::Pluggable::Module::MetaSyntactic->new;
$ENV{LANGUAGE} = 'en';

# a special test theme
Acme::MetaSyntactic->add_theme( 'bbpmm_theme' => [ 'a' .. 'dx' ] );

# quick test of the help string
like( $bot->help(), qr/meta theme/, 'Basic usage line' );

for my $t (@tests) {
    $nick = delete $t->[0]{_nick};    # setup our nick
    is( $bot->told( $t->[0] ),
        $t->[1],
        qq{Answer to "$t->[0]{raw_body}" on channel $t->[0]{channel}} );
}

