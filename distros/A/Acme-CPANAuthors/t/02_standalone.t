use strict;
use warnings;
use lib 't/lib';
use Test::More 0.88;
use Acme::CPANAuthors::Test;

my %authors = Acme::CPANAuthors::Test->authors;

is(keys(%authors), 1, 'one author');

is(Acme::CPANAuthors::Test->authors->{ISHIGAKI}, 'Kenichi Ishigaki', 'id -> name mapping');

foreach my $name ( keys %{ Acme::CPANAuthors::Test->authors } ) {
  is($authors{$name}, Acme::CPANAuthors::Test->authors->{$name}, 'all mappings');
}

is(Acme::CPANAuthors::Test->category, 'Test', 'category');

done_testing;
