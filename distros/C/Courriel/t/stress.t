use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;
use Test::Warnings;

use Test::Requires (
    'Path::Class' => '0',
);

use File::Slurp::Tiny qw( read_file );
use Path::Class qw( dir );

use Courriel;

my $dir = dir(qw( t data stress-test ));

while ( my $file = $dir->next ) {
    next if $file->is_dir;

    my $text = read_file( $file->stringify );

    is(
        exception { Courriel->parse( text => $text ) },
        undef,
        'no exception from parsing ' . $file->basename
    );
}

done_testing();
