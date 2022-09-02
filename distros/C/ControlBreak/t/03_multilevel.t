# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 9;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use ControlBreak;

use Data::Table;
use Getopt::Long;

my $verbose = 0;

GetOptions( 'v' => \$verbose ) # uncoverable branch true
    or die "*E* unrecognized command line arguments";


note "Testing multi-level control breaks";

my $dt = load_test_data();

my @colnames = $dt->header();
# first two columns are the control variables, but in major to minor
# order, so we reverse them; we also include a 0th element so that
# the list index corresponds to ControlBreak's one-based level numbers
my @cbnames = ('', reverse @colnames[0,1]);

# uncoverable branch true
if ($verbose > 0) {
    say sprintf '%s %-7s %-9s %-12s %10s', ' ' x 25,
        $colnames[0], $colnames[1], $colnames[2], $colnames[3];
    say sprintf '%s %-7s %-9s %-12s %10s', ' ' x 25,
        '=' x 7, '=' x 9, '=' x 12, '=' x 10;
}

# the first two columns of the table are ordered from major to minor
# but new() requires level names in minor to major order, so reverse
# is used to avoid mental confusion between the two
my $cb = ControlBreak->new( reverse 'Country', 'State' );

# case-insenstive string equality comparison function
my $eq_ci = sub { lc( $_[0] ) eq lc( $_[1] ) };
$cb->comparison( State => $eq_ci );

my @expected = qw( 0 0 0 1 0 1 2 1 0 );

my $next = $dt->iterator();

while (my $row = $next->()) {
    # test() assumes minor to major order
    # reverse allows the order to match the column order
    $cb->test( reverse $row->{Country}, $row->{State} );
    my $level = $cb->levelnum;

    # uncoverable branch true
    if ($verbose > 0) {
        # say "\n----- break $level -------" if $level;
        say sprintf '%s %-7s %-9s %-12s %10s', ' ' x 25,
            $row->{Country}, $row->{State}, $row->{City}, $row->{Population};
    }

    my $expected = shift @expected;
    my $col = $cbnames[$level];
    ok $cb->levelnum == $expected, $expected ? "break on $col" : "no break";

    $cb->continue;
}

sub load_test_data {

    my $header = [ 'Country', 'State', 'City', 'Population' ];
    my $data = [
        [ 'Canada', 'Ontario',  'Toronto',     '5,500,000' ], # 0
        [ 'Canada', 'ONTARIO',  'Ottawa',      '1,236,000' ], # 0
        [ 'Canada', 'Ontario',  'Hamilton',      '721,000' ], # 0
        [ 'Canada', 'Quebec',   'Montreal',    '3,824,000' ], # 2
        [ 'Canada', 'Quebec',   'Quebec City',   '765,000' ], # 0
        [ 'Canada', 'BC',       'Vancouver',   '2,313,000' ], # 2
        [ 'USA',    'New York', 'New York',    '8,405,000' ], # 1
        [ 'USA',    'Texas',    'Houston',     '2,196,000' ], # 2
        [ 'USA',    'Texas',    'Dallas',      '1,258,000' ], # 0
    ];
    my $dt = Data::Table->new($data, $header, 0);

    return $dt;
}
