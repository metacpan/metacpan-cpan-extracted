# -*- perl -*-

# t/003_spam.t - Spam detection

use Test::More tests => 6;

#01
BEGIN { use_ok( 'CGI::Wiki::Plugin::SpamMonkey' ); }

my $object = CGI::Wiki::Plugin::SpamMonkey->new ();

#02
isa_ok ($object, 'CGI::Wiki::Plugin::SpamMonkey');

#03
ok(!$object->is_spam(content => ''), "The empty string is not spam");

#04
ok(!$object->is_spam(content => 'Lovely pub in the City of London'), "Negative test");

my $spamedit;

{
#05
    ok(open (my $spamfh,'<','t/spamedit.txt'), "Able to read spamedit file");
    local $/ = undef;
    
    $spamedit = <$spamfh>;
}

TODO: {
    local $TODO = "SpamAssassin rules not currently working";
#06
ok($object->is_spam(content => $spamedit), "Spam content");

}

