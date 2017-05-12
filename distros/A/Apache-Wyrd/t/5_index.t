use strict;
use warnings;
no warnings qw(uninitialized);
use Cwd;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY GET_OK);
use Apache::Wyrd::Services::Index;
my $directory = getcwd();
#Note -- This line is to silence some errors using Apache::Test v. 1.19
eval 'use lib $directory';
$directory = "$directory/t" if (-d 't');

unlink ("$directory/data/testindex.db", "$directory/data/testindex2.db", "$directory/data/testindex_big2.db");

my $count = &count;
print "1..$count\n";

my $index = undef;

print "not " unless (GET_OK '/13.html');
print "ok 1 - Index creation\n";

eval {$index = Apache::Wyrd::Services::Index->new({
	file => "$directory/data/testindex.db",
	attributes => [qw(regular map)],
	maps => [qw(map)],
	strict => 1,
	bigfile => 0,
	debug => 1
})};
$index->read_db;

print "not " if ($@);
print "ok 2 - Index tie\n";

print "not " unless (GET_OK '/13.html');
print "ok 3 - Indexable objects\n";

my $text = GET_BODY '/13.html';

my $found = $index->entry_by_name('one');

print "not " if (ref($found) ne 'HASH');
print "ok 4 - Lookup\n";

print "not " if ($found->{description} ne 'first');
print "ok 5 - Find by name\n";

print "not " if ($found->{regular} ne 'regular1');
print "ok 6 - Custom regular attribute\n";

my @found = $index->word_search('one');

print "not " if (@found != 2);
print "ok 7 - Find by word\n";

@found = $index->word_search('four', 'map');

print "not " if (@found != 2);
print "ok 8 - Find by custom map\n";

@found = $index->word_search('+one');

print "not " if (@found != 2);
print "ok 9 - Exclusive word search\n";

@found = $index->word_search('+one +more');

print "not " if (@found != 1);
print "ok 10 - Exclusive word search combined 1\n";

@found = $index->word_search('+one -more');

print "not " if (@found != 1);
print "ok 11 - Exclusive word search combined 2\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 12 - Exclusive word search combined 3\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 13 - Exclusive word search combined 4\n";

@found = $index->parsed_search('one AND more');

print "not " if (@found != 1);
print "ok 14 - Exclusive logical search 1\n";

@found = $index->parsed_search('one NOT more');

print "not " if (@found != 1);
print "ok 15 - Exclusive logical search 2\n";

@found = $index->parsed_search('this AND (another OR more)');

print "not " if (@found != 4);
print "ok 16 - Exclusive logical search 3\n";

@found = $index->parsed_search('NOT one NOT more');

print "not " if (@found != 2);
print "ok 17 - Exclusive logical search 4\n";

$index->delete_index;
$found = $index->get_entry('one');

print "not " if ($found->{description});
print "ok 18 - Zero index\n";

$index = undef;

print "not " unless (GET_OK '/19.html');
print "ok 19 - Index creation\n";

eval {$index = Apache::Wyrd::Services::Index->new({
	file => "$directory/data/testindex2.db",
	attributes => [qw(regular map)],
	maps => [qw(map)],
	strict => 1,
	dirty => 1,
	bigfile => 1,
	debug => 1
})};
$index->read_db;

print "not " if ($@);
print "ok 20 - Index tie\n";

print "not " unless (GET_OK '/19.html');
print "ok 21 - Inherited object\n";

$text = GET_BODY '/19.html';

$found = $index->entry_by_name('one');

print "not " if (ref($found) ne 'HASH');
print "ok 22 - Lookup\n";

print "not " if ($found->{description} ne 'first');
print "ok 23 - Find by name\n";

print "not " if ($found->{regular} ne 'regular1');
print "ok 24 - Custom regular attribute\n";

@found = $index->word_search('one');

print "not " if (@found != 2);
print "ok 25 - Find by word\n";

@found = $index->word_search('four', 'map');

print "not " if (@found != 2);
print "ok 26 - Find by custom map\n";

@found = $index->word_search('+one');

print "not " if (@found != 2);
print "ok 27 - Exclusive word search\n";

@found = $index->word_search('+one +more');

print "not " if (@found != 1);
print "ok 28 - Exclusive word search combined 1\n";

@found = $index->word_search('+one -more');

print "not " if (@found != 1);
print "ok 29 - Exclusive word search combined 2\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 30 - Exclusive word search combined 3\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 31 - Exclusive word search combined 4\n";

@found = $index->parsed_search('one AND more');

print "not " if (@found != 1);
print "ok 32 - Exclusive logical search 1\n";

@found = $index->parsed_search('one NOT more');

print "not " if (@found != 1);
print "ok 33 - Exclusive logical search 2\n";

@found = $index->parsed_search('this AND (another OR more)');

print "not " if (@found != 3);
print "ok 34 - Exclusive logical search 3\n";

@found = $index->parsed_search('NOT one NOT more');

print "not " if (@found != 2);
print "ok 35 - Exclusive logical search 4\n";

print "not " unless (GET_OK '/20.html');
print "ok 36 - Bigfile Text\n";

$text = GET_BODY '/20.html';

@found = $index->word_search('muchness');
$found = shift @found;

print "not " if (scalar(@found) > 1);
print "ok 37 - No duplicates\n";

print "not " if (ref($found) ne 'HASH');
print "ok 38 - Bigfile Lookup\n";

print "not " if ($found->{name} ne 'alice');
print "ok 39 - Bigfile Lookup by wordsearch\n";

@found = $index->word_search('"much of a muchness"');
$found = shift @found;

print "not " if (ref($found) ne 'HASH');
print "ok 40 - Correct type 2\n";

print "not " if ($found->{name} ne 'alice');
print "ok 41 - Lookup by exact phrase\n";

print "not " unless (GET_OK '/21.html');
print "ok 42 - Changed Indexible Item\n";

$text = GET_BODY '/21.html';

@found = $index->word_search('muchness');
$found = shift @found;

print "not " if (scalar(@found) != 0);
print "ok 43 - No duplicates in change\n";

print "not " if (ref($found) ne 'HASH');
print "ok 44 - Correct return type\n";

print "not " if ($found->{name} ne 'alice');
print "ok 45 - Correct identification\n";

@found = $index->word_search('"much of a muchness"');
$found = shift @found;

print "not " if (ref($found) ne 'HASH');
print "ok 46 - Correct Return Type\n";

print "not " if ($found->{name} ne 'alice');
print "ok 47 - Exact Phrase Match on Changed File\n";

@found = $index->word_search('wombat');
$found = shift @found;

print "not " if (ref($found) ne 'HASH');
print "ok 48 - Correct Return Type\n";

print "not " if ($found->{name} ne 'alice');
print "ok 49 - Word Match on Changed File\n";

@found = $index->word_search('dormouse');
$found = shift @found;

print "not " if ($found->{name} eq 'alice');
print "ok 50 - Duplicate removed on Changed File\n";

$index->delete_index;
@found = $index->get_entry('one');
$found = shift @found;

print "not " if ($found->{description});
print "ok 51 - Zero index\n";


eval {$index = Apache::Wyrd::Services::Index->new({
	file => "$directory/data/testindex3.db",
	attributes => [qw(regular map)],
	maps => [qw(map)],
	strict => 1,
	reversemaps => 1,
	debug => 1
})};
$index->read_db;

print "not " if ($@);
print "ok 52 - Index tie\n";

print "not " unless (GET_OK '/22.html');
print "ok 53 - Inherited object\n";

$text = GET_BODY '/22.html';

$found = $index->entry_by_name('one');

print "not " if (ref($found) ne 'HASH');
print "ok 54 - Lookup\n";

print "not " if ($found->{description} ne 'first');
print "ok 55 - Find by name\n";

print "not " if ($found->{regular} ne 'regular1');
print "ok 56 - Custom regular attribute\n";

@found = $index->word_search('one');

print "not " if (@found != 2);
print "ok 57 - Find by word\n";

@found = $index->word_search('four', 'map');

print "not " if (@found != 2);
print "ok 58 - Find by custom map\n";

@found = $index->word_search('+one');

print "not " if (@found != 2);
print "ok 59 - Exclusive word search\n";

@found = $index->word_search('+one +more');

print "not " if (@found != 1);
print "ok 60 - Exclusive word search combined 1\n";

@found = $index->word_search('+one -more');

print "not " if (@found != 1);
print "ok 61 - Exclusive word search combined 2\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 62 - Exclusive word search combined 3\n";

@found = $index->word_search('-one -more');

print "not " if (@found != 2);
print "ok 63 - Exclusive word search combined 4\n";

@found = $index->parsed_search('one AND more');

print "not " if (@found != 1);
print "ok 64 - Exclusive logical search 1\n";

@found = $index->parsed_search('one NOT more');

print "not " if (@found != 1);
print "ok 65 - Exclusive logical search 2\n";

@found = $index->parsed_search('this AND (another OR more)');

print "not " if (@found != 3);
print "ok 66 - Exclusive logical search 3\n";

@found = $index->parsed_search('NOT one NOT more');

print "not " if (@found != 2);
print "ok 67 - Exclusive logical search 4\n";

print "not " unless (GET_OK '/23.html');
print "ok 68 - Bigfile Text\n";

$text = GET_BODY '/23.html';

@found = $index->word_search('muchness');
$found = shift @found;

print "not " if (scalar(@found) > 1);
print "ok 69 - No duplicates\n";

print "not " if (ref($found) ne 'HASH');
print "ok 70 - Bigfile Lookup\n";

print "not " if ($found->{name} ne 'alice');
print "ok 71 - Bigfile Lookup by wordsearch\n";

@found = $index->word_search('"much of a muchness"');
$found = shift @found;

print "not " if (ref($found) ne 'HASH');
print "ok 72 - Correct type 2\n";

print "not " if ($found->{name} ne 'alice');
print "ok 73 - Lookup by exact phrase\n";

print "not " unless (GET_OK '/24.html');
print "ok 74 - Changed Indexible Item\n";

$text = GET_BODY '/24.html';

@found = $index->word_search('muchness');
$found = shift @found;

print "not " if (scalar(@found) != 0);
print "ok 75 - No duplicates in change\n";

print "not " if (ref($found) ne 'HASH');
print "ok 76 - Correct return type\n";

print "not " if ($found->{name} ne 'alice');
print "ok 77 - Correct identification\n";

@found = $index->word_search('"much of a muchness"');
$found = shift @found;

print "not " if (ref($found) ne 'HASH');
print "ok 78 - Correct Return Type\n";

print "not " if ($found->{name} ne 'alice');
print "ok 79 - Exact Phrase Match on Changed File\n";

@found = $index->word_search('wombat');
$found = shift @found;

print "not " if (ref($found) ne 'HASH');
print "ok 80 - Correct Return Type\n";

print "not " if ($found->{name} ne 'alice');
print "ok 81 - Word Match on Changed File\n";

@found = $index->word_search('dormouse');
$found = shift @found;

print "not " if ($found->{name} eq 'alice');
print "ok 82 - Duplicate removed on Changed File\n";

$index->delete_index;
@found = $index->get_entry('one');
$found = shift @found;

print "not " if ($found->{description});
print "ok 83 - Zero index\n";

sub count {83}
