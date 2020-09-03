use strict;
use warnings;

use Test2::V0;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;
use File::ShareDir qw( dist_dir );
use Path::Tiny qw( path );

{
    # This is kind of gross since we are assuming that File::ShareDir always
    # constructs a path ending in "auto/share/dist/DateTime-Locale". If
    # File::ShareDir were ever to change how it constructs paths this would
    # break, but that seems very unlikely.
    my $dist_dir  = path( dist_dir('DateTime-Locale') );
    my $share_dir = $dist_dir;

    # This removes the auto/share/dist/DateTime-Locale part of the path.
    for ( 1 .. 4 ) {
        $share_dir = $share_dir->parent;
    }

    # This is the top-level dir that contains "auto/share/...". This will be a
    # temp dir of some sort.
    my $share_dir_name = $share_dir->basename;

    # And this is the directory that contains $share_dir_name. On Linux this
    # will be $ENV{TMPDIR} or /tmp.
    my $containing_dir = $share_dir->parent;

    chdir $containing_dir
        or die "could not chdir to $containing_dir: $!";

    my $l = do {
        local @INC = ($share_dir_name);
        DateTime::Locale->load('de-DE');
    };

    ok( $l, 'was able to load de-DE locale from relative dir' );
    isa_ok( $l, 'DateTime::Locale::FromData' );
}

done_testing();
