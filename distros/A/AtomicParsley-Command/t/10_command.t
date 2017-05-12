#!perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;
use FindBin qw($Bin);
use File::Copy;
use IPC::Cmd '0.76', ();

use AtomicParsley::Command::Tags;

if( IPC::Cmd::can_run('AtomicParsley') ){
    plan tests => 22;
} else {
    plan skip_all => 'AtomicParsley not present';
}

require_ok('AtomicParsley::Command');

my $ap;
my $tags;
my $testfile = "$Bin/resources/Family.mp4";

$ap = new_ok('AtomicParsley::Command');
like( $ap->{ap}, qr/AtomicParsley$/ );
is( $ap->{verbose}, 0 );

# _parse_tags
my $output = 'Atom "©nam" contains: Family (Mock the Week)
Atom "©ART" contains: Milton Jones
Atom "aART" contains: Milton Jones
Atom "gnre" contains: Comedy
Atom "tvsh" contains: Milton Jones
Atom "desc" contains: foo bar

baz
';
$tags = $ap->_parse_tags($output);
is( $tags->{title}, 'Family (Mock the Week)', 'title' );
is( $tags->{genre}, 'Comedy', 'genre' );
my $desc = 'foo bar

baz';
is( $tags->{description}, $desc, 'description' );

# write_tags
my $write_tags = AtomicParsley::Command::Tags->new(
    artist    => 'test_artist',
    title     => 'test_title',
    album     => 'test_album',
    genre     => 'test_genre',
    tracknum  => '1/10',
    disk      => '1/2',
    comment   => 'test_comment',
    year      => '2011',
    lyrics    => 'test_lytics',
    composer  => 'test_composer',
    copyright => 'test_copyright',
    grouping  => 'test_grouping',

    #artwork => 'test_
    bpm         => '12',
    albumArtist => 'test_albumArtist',

    #compilation => 'true',
    advisory     => 'clean',
    stik         => 'Movie',
    description  => 'test_description',
    longdesc     => 'test_longdesc',
    TVNetwork    => 'test_TVNetwork',
    TVShowName   => 'test_TVShowName',
    TVEpisode    => 'test_TVEpisode',
    TVSeasonNum  => '1',
    TVEpisodeNum => '2',

    #podcastFlag => 'false',
    category => 'test_category',
    keyword  => 'test_keyword',

    #podcastURL => 'http://andrew-jones.com',
    #podcastGUID
    #purchaseDate
    encodingTool => 'test_encodingTool',

    #gapless => 'true',
);
my $tempfile = $ap->write_tags( $testfile, $write_tags );
ok( -e $tempfile );

# read_tags
my $read_tags = $ap->read_tags($tempfile);
is_deeply( $read_tags, $write_tags, 'read/write tags' );

#-- test with spaces for file glob
mkdir "$Bin/space in resources";
my $testfile3 = "$Bin/space in resources/Family with spaces.mp4";
copy( $testfile, $testfile3 );

my $return_file = $ap->write_tags( $testfile3, $write_tags, 1 );
ok( -e $return_file );
ok ( $return_file eq $testfile3);
$read_tags = $ap->read_tags($return_file);
is ($read_tags->title, $write_tags->title, "returned file has tags" );


# remove tags, and test replace
my $testfile2 = "$Bin/resources/Family-replace.mp4";
copy( $testfile, $testfile2 );
$write_tags = AtomicParsley::Command::Tags->new(
    title => '',
    genre => undef,
);
my $tempfile2 = $ap->write_tags( $testfile2, $write_tags, 1 );
is( $tempfile2, $testfile2 );
$read_tags = $ap->read_tags($tempfile2);
is( $read_tags->title, undef,    'removed' );
is( $read_tags->genre, 'Comedy', 'kept' );


$ap->read_tags('/does/not/exist');
ok( !$ap->{success} );
like( $ap->{stdout_buf}[0], qr/No such file or directory/ );

isnt(
    exception {
        $ap = AtomicParsley::Command->new( { ap => 'foo', } );
    },
    undef
);

unlink $tempfile;
ok( !-e $tempfile );
unlink $tempfile2;
ok( !-e $tempfile2 );
unlink $testfile3;
ok( !-e $tempfile2 );
rmdir "$Bin/space in resources";
ok( !-d "$Bin/space in resources");