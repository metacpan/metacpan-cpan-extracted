use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('Data::Text') }

my $dt = Data::Text->new('Hello World. Goodbye Moon.');

ok($dt->replace({ 'Hello' => 'Hi', 'Goodbye' => 'Farewell' }), 'replace() method returns self');

is($dt->as_string(), 'Hi World. Farewell Moon.', 'Multiple word replacements applied');

# Test partial word (should not replace "HelloWorld")
$dt->set('HelloWorld GoodbyeMoon');
$dt->replace({ 'Hello' => 'Hi', 'Goodbye' => 'Bye' });
is($dt->as_string(), 'HelloWorld GoodbyeMoon', 'No partial word matches');

# Test case sensitivity
$dt->set('HELLO Hello hello');
$dt->replace({ 'Hello' => 'Hi' });
is($dt->as_string(), 'HELLO Hi hello', 'Only exact case matches replaced');

# Test replacing to a phrase
$dt->set('Greetings Earth');
$dt->replace({ 'Greetings' => 'Hello wonderful' });
is($dt->as_string(), 'Hello wonderful Earth', 'Replaced single word with multiple words');

# Test empty replacement hash
$dt->set('Text stays the same');
$dt->replace({});
is($dt->as_string(), 'Text stays the same', 'No replacements with empty hash');

$dt = Data::Text->new();

# Test replace on undef text
ok($dt->replace({ 'Hello' => 'Hi' }), 'replace() on undef does not die');
is($dt->as_string, undef, 'Text remains undef after replace');

# Test mixed replacements with punctuation and word boundaries
$dt->set('file.txt is not filex.txt');
$dt->replace({ 'file.txt' => 'document.txt' });
is($dt->as_string, 'document.txt is not filex.txt', 'No partial replacements on word boundaries');

done_testing();
