#!/usr/bin/perl -w
use strict;
use lib 't';
use vars qw( $class );

use Test::More tests => 6;
use Data::Phrasebook;

my $file = 't/02dict.ini';

# load up the default dict
my $book = Data::Phrasebook->new(class  => 'Plain',
                                 loader => 'Ini',
                                 file   => 't/05dict.ini');
is($book->fetch('foo'), "I'm original foo.");

# now switch to the second one
$book->dict('ONE');
is($book->fetch('foo'), "I'm new foo.");

my @expected = qw( DEF ONE );
my @dicts = $book->dicts();
is_deeply( \@dicts, \@expected );

my @tkeys = qw( bar baz foo );  # default AND named
my @keywords = $book->keywords();
is_deeply( \@keywords, \@tkeys );

@tkeys = qw( bar foo );
@keywords = $book->keywords('DEF');
is_deeply( \@keywords, \@tkeys );

# check second still loaded
is($book->fetch('foo'), "I'm new foo.");
