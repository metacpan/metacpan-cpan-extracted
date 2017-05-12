use Test::More tests => 8;

use strict;
use warnings;
use FindBin;
use File::Spec;
use File::Path qw(remove_tree);
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );

require_ok('FindBin');
use_ok 'FindBin';

require_ok('File::Spec');
use_ok 'File::Spec';

require_ok('File::Path');
use_ok 'File::Path';

require_ok('DBIx::Schema::Changelog::Command::File');
use_ok 'DBIx::Schema::Changelog::Command::File';

my $path = File::Spec->catfile( $FindBin::Bin, '.tmp' );

my $config = {
    author => 'Test Author',
    email  => 'author@cpan.org',
    type   => 'XML',
    dir    => $path
};

DBIx::Schema::Changelog::Command::File->new()->make($config);
# TODO sub test for created file
remove_tree $path or die "Could not unlink $path: $!";
