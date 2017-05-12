use strict;
use warnings;
use lib 't/lib';
use Test::More 0.88;
use Acme::CPANAuthors;

my $authors = Acme::CPANAuthors->new('Test');

my $count = $authors->count;
is($count, 1, 'author count');

my @ids = $authors->id;
is(@ids, 1, 'author ids');

my $ishigaki = $authors->id('ISHIGAKI');
ok($ishigaki, 'ISHIGAKI is a member');

my @names = $authors->name;
is(@names, 1, 'author names');

my $name = $authors->name('ISHIGAKI');
like($name, qr/Ishigaki/i, 'Ishigaki is a member');

my @categories = $authors->categories;
is(@categories, 1, '1 category');
is($categories[0], 'Test', 'category');

done_testing;
