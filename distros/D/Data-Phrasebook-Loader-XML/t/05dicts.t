#!/usr/bin/perl -w
use strict;
use lib 't';
use vars qw( $class );

use Test::More tests => 4;
use Data::Phrasebook;

my $file = 't/05phrases.xml';

# load up the default dict
my $book = Data::Phrasebook->new(class  => 'Plain',
                                 loader => 'XML',
                                 file   => $file);
is($book->fetch('foo'), "I'm original foo.");

# now switch to the second one
$book->dict('ONE');
is($book->fetch('foo'), "I'm new foo.");

my @expected = qw( DEF ONE );
my @dicts = $book->dicts();
is_deeply( \@dicts, \@expected );

my @tkeys = qw( bar baz foo );
my @keywords = $book->keywords();
is_deeply( \@keywords, \@tkeys );
