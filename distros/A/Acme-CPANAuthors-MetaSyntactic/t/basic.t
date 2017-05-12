use strict;
use warnings;
use Test::More;

use Acme::CPANAuthors;
use Acme::CPANAuthors::MetaSyntactic;

ok( defined $Acme::CPANAuthors::MetaSyntactic::VERSION, "VERSION is set" );

my $authors = Acme::CPANAuthors->new('MetaSyntactic');
ok( $authors,        'Got $authors' );
ok( $authors->count, "There are authors" );

my @ids = $authors->id;
ok( scalar @ids,            "There are ids" );
ok( $authors->name("BOOK"), "Find a name" );

done_testing;
