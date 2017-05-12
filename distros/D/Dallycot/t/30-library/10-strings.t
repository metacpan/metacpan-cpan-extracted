use lib 't/lib';

use strict;
use warnings;

use Test::More;

use LibraryHelper;

BEGIN { require_ok 'Dallycot::Library::Core::Strings' };

uses 'http://www.dallycot.net/ns/strings/1.0#';

isa_ok(Dallycot::Library::Core::Strings->instance, 'Dallycot::Library');


my $result;

$result = run('string-take("The bright red spot.", 5)');

is_deeply $result, String("The b"), "The first five characters of 'The bright...' are 'The b'";

$result = run('string-take("The bright red spot.", <4,9>)');

is_deeply $result, String(" brigh");

$result = run('string-take("The bright red spot.", <10>)');

is_deeply $result, String("t");

$result = run('string-drop("The bright red spot.", 10)');

is_deeply $result, String(" red spot.");

$result = run('number-string(12345)');

is_deeply $result, String("12345");

done_testing();
