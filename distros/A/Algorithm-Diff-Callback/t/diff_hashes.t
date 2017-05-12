#!perl

use strict;
use warnings;

use Test::More tests => 11;
use Algorithm::Diff::Callback 'diff_hashes';

my %old = (
    tvshow => 'Psych',
    book   => 'Damnation Game',
    band   => 'Catharsis',
    movie  => undef,
);

my %new = (
    tvshow => 'CSI (Las Vegas)', # new favorite tv show
    book   => 'Damnation Game',  # <3 Cliver Barker
    artist => 'Michael Jackson', # ah, the classics
    movie  => undef,             # decisions, decisions
);

diff_hashes(
    \%old, \%new,
    deleted => sub {
        my ( $name, $val ) = @_;
        is( $name, 'band',      'Band was removed' );
        is( $val,  'Catharsis', 'Correct band'     );
    },
    added => sub {
        my ( $name, $val ) = @_;
        is( $name, 'artist',          'Artist added'   );
        is( $val,  'Michael Jackson', 'Correct artist' );
    },
    changed => sub {
        my ( $name, $before, $after ) = @_;
        is( $name,   'tvshow',          'Changing tv show'         );
        is( $before, 'Psych',           'Was Psych'                );
        is( $after,  'CSI (Las Vegas)', 'It is now CSI Las Vegas!' );
    },
);

my $empty_hash = 0;
my $cb = sub { $empty_hash++ };
diff_hashes( {}, {}, deleted => $cb, added => $cb, changed => $cb );
cmp_ok( $empty_hash, '==', 0, 'Empty hash does not get called' );

my $no_change = 0;
$cb = sub { $no_change++ };
diff_hashes( \%old, \%old, deleted => $cb, added => $cb, changed => $cb );
cmp_ok( $no_change, '==', 0, 'No change does not get called' );

my $new_count    = 0;
my $change_count = 0;
diff_hashes(
    {}, \%new,
    deleted => sub { $new_count--    },
    added   => sub { $new_count++    },
    changed => sub { $change_count++ },
);

cmp_ok( $new_count,    '==', scalar keys (%new), 'New from scratch' );
cmp_ok( $change_count, '==', 0,                  'Nothing changed'  );
