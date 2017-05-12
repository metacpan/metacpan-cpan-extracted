#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}
plan tests => 21;

use_ok('Config::Crontab');

my $comment;

$comment = new Config::Crontab::Comment;
is( $comment->data, '' );
is( $comment->dump, '' );
undef $comment;

$comment = new Config::Crontab::Comment( -data => undef );
is( $comment->data, '' );
is( $comment->dump, '' );
undef $comment;

$comment = new Config::Crontab::Comment( -data => '' );
is( $comment->data, '' );
is( $comment->dump, '' );
undef $comment;

$comment = new Config::Crontab::Comment;
is( $comment->dump, '' );
is( $comment->data, '' );

is( $comment->data('## testing'), '## testing' );
is( $comment->data, '## testing' );
is( $comment->dump, '## testing' );
undef $comment;

## constructor
$comment = new Config::Crontab::Comment( -data => '## testing 2' );
is( $comment->data, '## testing 2' );
is( $comment->dump, '## testing 2' );
undef $comment;

## constructor
$comment = new Config::Crontab::Comment('## testing 3');
is( $comment->data, '## testing 3' );
is( $comment->dump, '## testing 3' );
undef $comment;

## whitespace
$comment = new Config::Crontab::Comment( -data => '	' );
is( $comment->data, '	' );
is( $comment->dump, '	' );
undef $comment;

## newline stripping
$comment = new Config::Crontab::Comment( -data => "## no newline\n" );
is( $comment->data, '## no newline' );
is( $comment->dump, '## no newline' );
undef $comment;

## garbage in constructor should return undef
ok( ! defined($comment = new Config::Crontab::Comment('foo garbage')) );
undef $comment;
