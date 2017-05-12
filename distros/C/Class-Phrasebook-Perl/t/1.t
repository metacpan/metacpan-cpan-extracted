
use Test::More tests => 20;
BEGIN { use_ok('Class::Phrasebook::Perl') };

use Class::Phrasebook::Perl;

#########################

# Load a phrasebook
$pb = new Class::Phrasebook::Perl("phrasebook.1");
ok(ref($pb), "new");

# Load the 'en' dictionary.
$dict = $pb->load("en");
ok ($dict, "load(en)");

# Retrieve some phrases.
$phrase = $pb->get("hello-world");
ok ($phrase eq "Hello, World!");

$phrase = $pb->get("the-hour", hour => "10:00");
ok ($phrase eq "The time now is 10:00.");

# Phrase with placeholders.
$phrase = $pb->get("the-hour", hour => "10:00");
ok ($phrase eq "The time now is 10:00.");

# Load the 'fr' dictionary.
$dict = $pb->load("fr");
ok ($dict, "load(fr)");

# Retrieve some phrases.
$phrase = $pb->get("hello-world");
ok ($phrase eq "Bonjour le Monde!!!");

# Phrase with placeholders.
$phrase = $pb->get("the-hour", hour => "10:00");
ok ($phrase eq "Il est maintenant 10:00.");

# Load a dictionary that doesn't exist.
$dict = $pb->load("nl");
ok (! $dict, "load(nl)");

# Load a new phrasebook.
$pb = new Class::Phrasebook::Perl("phrasebook.2");
ok(ref($pb), "new");

$dict = $pb->load("example");
ok ($dict, "load(example)");

@array = @{$pb->get('array')};
ok($array[0] eq 'biff!', "array");
ok($array[1] eq 'bam!', "array");
ok($array[2] eq 'chicka-pow!', "array");

%hash = %{$pb->get('hash')};
ok($hash{sound} eq 'bork!', "hash");
ok($hash{noise} eq 'bonk!', "hash");

$code = $pb->get('code');
$res = $code->();
ok ($res eq "ka-plooey!\n", "code");

$code = $pb->get('code-with-args');
$res = $code->("ploink");
ok ($res eq "ploink, ploink, ploink!\n", "code");

$code = $pb->get('code-with-args');
$res = $code->("ploink", useless => "args");
ok ($res eq "ploink, ploink, ploink!\n", "code");
