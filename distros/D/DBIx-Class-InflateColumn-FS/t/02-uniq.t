#!perl
use strict;
use warnings;
use Test::More tests => 5;
use Path::Class::File;
use Path::Class::Dir;


use lib qw(t/lib);
use DBICx::TestDatabase;
use IO::File;


my $schema = DBICx::TestDatabase->new('My::TestSchema');
my $rs = $schema->resultset('Book');

# we'll use *this* file as our content
# TODO: Copy it or create something else so errant tests don't inadvertently
# delete it!

my $book = $rs->create({
    name => 'Alice in Wonderland',
});

my $base = $book->column_info('cover_image_2')->{fs_column_path};


my $fh = new IO::File "t/var/testfile.txt";

$book->cover_image_2($fh);

$book->update;

my $name;

like($name = $book->cover_image_2, qr{^\Q$base\E});

$fh = new IO::File "t/var/testfile.txt";

$book->cover_image_2($fh);

$book->update;

ok(!-e $name, "old file does not exist anymore");

like($name = $book->cover_image_2, qr{^\Q$base\E});

ok(-e $name);

$book = $schema->resultset("Book")->first;

is($book->cover_image_2, $name, "name did not change on retrieve");


