use strict;
use warnings;
use Test::More;

use File::Spec;
use URI;
use Wallflower;

my @tests = (
    [ '/'               => 'index.html' ],
    [ '/kayo/'          => File::Spec->catfile(qw( kayo index.html )) ],
    [ '/kayo'           => 'kayo' ],
    [ '/awk/swoosh.css' => File::Spec->catfile(qw( awk swoosh.css )) ],
    [ '/awk/clash'      => File::Spec->catfile(qw( awk clash )) ],
    [ '/awk/clash/'     => File::Spec->catfile(qw( awk clash index.html )) ],
    [ 'http://example.com/' => 'index.html' ],
);

my @fails = (
    map [ $_ => qr/^$_ has an empty path / ],
    '', 'http://example.com',
);

plan tests => @tests + 2 * @fails;

# pick up a possible destination directory
my $dir = File::Spec->tmpdir;

my $wallflower = Wallflower->new(
    destination => $dir,
    application => sub { },    # dummy
);

# normal tests
for my $t (@tests) {
    my ( $uri, $file ) = @$t;
    $file = is( $wallflower->target( URI->new($uri) ),
        File::Spec->catfile( $dir, $file ), $uri );
}

# failure tests
for my $t (@fails) {
    my ( $uri, $re ) = @$t;
    ok( !eval { $wallflower->target( URI->new($uri) ) },
        "target() dies for $uri" );
    like( $@, $re, "expected error message for $uri" );
}

