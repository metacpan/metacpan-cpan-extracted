# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };

use AI::MegaHAL;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

print("Creating new AI::MegaHAL\n");
my $megahal = AI::MegaHAL->new(AutoSave => 1);
ok(ref($megahal) ne "", 1);

print("#Testing AI::MegaHAL->do_reply method\n");

my $query = "#We are the knights who say NI!";
print("# * Sending: $query\n");
my $reply = $megahal->do_reply($query);
print("# * Replied: $reply\n");
ok($reply ne "", 1);

print("#Destroying MegaHAL - should autosave brain and dictionary files\n");
$megahal = undef;
ok(1);

print("#Checking for brain file: megahal.brn\n");
ok(-f 'megahal.brn', 1);

print("#Checking for dictionary file: megahal.dic\n");
ok(-f 'megahal.dic', 1);
