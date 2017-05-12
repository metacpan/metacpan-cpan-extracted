#!perl
use warnings;
use strict;
use DBICx::TestDatabase;
use Test::More tests => 26;
use Path::Class qw/file/;
use File::Compare;
use lib qw(t/lib);

my $schema = DBICx::TestDatabase->new('My::TestSchema');
my $rs = $schema->resultset('Book');

# we'll use *this* file as our content
# TODO: Copy it or create something else so errant tests don't inadvertently
# delete it!
my $file = file($0);

my $book = $rs->create({
    name => 'Alice in Wonderland',
    cover_image => $file,
});

isa_ok( $book->cover_image, 'Path::Class::File' );
isnt( $book->cover_image, $file, 'storage is a different file' );
ok( compare($book->cover_image, $file) == 0, 'file contents equivalent');

# setting a file to itself should be a no-op
my $storage = Path::Class::File->new($book->cover_image);
$book->update({ cover_image => $storage });

is( $storage, $book->cover_image, 'setting storage to self' );

# deleting the row should delete the associated file
$book->delete;
ok( ! -e $storage, 'file successfully deleted' );

# multiple rows
my ($book1, $book2) = map {
    $rs->create({ name => $_, cover_image => $file })
} qw/Book1 Book2/;

isnt( $book1->cover_image, $book2->cover_image, 'rows have different storage' );

$rs->delete;
ok ( ! -e $book1->cover_image, "storage deleted for row 1" );
ok ( ! -e $book2->cover_image, "storage deleted for row 2" );


# null fs_column
$book = $rs->create({ name => 'No cover image', cover_image => undef });

ok ( !defined $book->cover_image, 'null fs_column' );


# file handle
open my $fh, '<', $0 or die "failed to open $0 for read: $!\n";

$book->cover_image($fh);
$book->update;
close $fh or die;

ok( compare($book->cover_image, $0) == 0, 'store from filehandle' );

# missing fs_column
{
    my $book = $rs->create({ name => 'No cover image' });

    ok ( !defined $book->cover_image, 'missing fs_column' );

    open my $fh, '<', $0 or die "failed to open $0 for read: $!\n";

    $book->cover_image($fh);
    $book->update;
    close $fh or die;

    $book->discard_changes;   # reload from db

    ok( defined $book->cover_image && compare($book->cover_image, $0) == 0,
        'store from filehandle (missing fs column)' );
}

# setting fs_column to null should delete storage
$book = $rs->create({ name => 'Here today, gone tomorrow',
        cover_image => $file });
$storage = $book->cover_image;
ok( -e $storage, 'storage exists before nulling' );
$book->update({ cover_image => undef });
ok( ! -e $storage, 'does not exist after nulling' );

$book->update({ cover_image => $file });
$book->update({ id => 999 });
$book->discard_changes;
ok( -e $book->cover_image, 'storage renamed on PK change' );

#--------------------------------- test copy ---------------------------------
my $orig_column_data = { %{$book->{_column_data}} };
my $copy = $book->copy;
isnt( $copy->cover_image, $book->cover_image, 'copy has its own file backing' );
ok( compare($copy->cover_image, $book->cover_image) == 0, 'copy contents correct' );

# an update of book shouldn't change the source's _column_data
is_deeply ( $book->{_column_data}, $orig_column_data, 'copy source unchanged' );

# Regression test (failed on a prior implementation of copy)
$book = $rs->find({ id => 1, });
ok( eval{ $copy = $book->copy }, 'copy works with selected elements' );

#----------------------------- infinite recursion ----------------------------
$book = $rs->create({
    name          => 'The Never Ending Story',
    cover_image   => $file,
    cover_image_2 => $file,
});

my $cover_image = $book->cover_image->stringify;
my $cover_image_2 = $book->cover_image->stringify;
$book->update({ cover_image => $file, cover_image_2 => $file });
is( $book->cover_image, $cover_image, 'backing filename did not change' );
isnt( $book->cover_image_2, $cover_image_2, 'backing filename did change for fs_new_on_update column' );

SKIP: {
# ensure FS works with the proposed change for DBIC: make_column_dirty to delete {_column_data}{$column}

    skip 'requires make_column_dirty', 1 unless $book->can('make_column_dirty');

    $storage = $book->cover_image;

    $book->make_column_dirty('cover_image');
    delete $book->{_column_data}{cover_image};
    $book->update;
    is( $book->cover_image, $storage, 'file backikng filename unchanged')
};


ok($schema->resultset('Book')->search(undef, { select => [qw(id)], as => [qw(foo)] })->all);

{
    # Objects that are never written to storage should have
    # backing files removed.

    $book = $rs->new({
        name        => 'The Unpublished Chronicles of MST',
        cover_image => $file,
    });

    # force object deflation
    $book->get_columns;

    $storage = $book->cover_image;
    isnt ( $storage, $file, 'object deflated' );
    ok   ( -e $storage, 'file backing exists' );

    undef $book;
    ok ( !-e $storage, 'storage deleted for un-inserted row' );
}
