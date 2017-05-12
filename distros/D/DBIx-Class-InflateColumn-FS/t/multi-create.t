#!perl
use warnings;
use strict;
use DBICx::TestDatabase;
use Test::More tests => 2;
use Path::Class qw/file/;
use File::Find;
use lib qw(t/lib);

my $schema = DBICx::TestDatabase->new('My::TestSchema');

# we'll use *this* file as our content
# TODO: Copy it or create something else so errant tests don't inadvertently
# delete it!
my $file = file($0);

my $author = $schema->resultset('Author')->create({
    name => 'Joseph Heller',
    books => [
        { name => 'Catch 22',           cover_image => $file },
        { name => 'Something Happened', cover_image => $file },
    ],
});

is ( $author->books->count, 2, 'created 2 books' );

TODO: {
    local $TODO = 'Requires a patch to DBIx::Class::Row 2010-05-28 (semifor)';

    my $storage_dir = $schema->resultset('Book')
        ->result_source
        ->column_info('cover_image')
        ->{fs_column_path};

    my $file_count = 0;
    find(sub { -f && ++$file_count }, $storage_dir);

    is ( $file_count, 2, '2 backing files' );
}
