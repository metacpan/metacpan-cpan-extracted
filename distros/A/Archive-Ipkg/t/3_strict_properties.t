# Test 3: Strict properties

use Test::More tests => 50;

use Archive::Ipkg;

# test strictness of properties
my $ipkg = Archive::Ipkg->new();


# name =~ [a-z0-9.+-]+
ok(!defined $ipkg->name("Uppercase_Is_Evil"));
ok(!defined $ipkg->name("underscore_not_allowed"));
ok(!defined $ipkg->name("symbols#also'bad"));
ok(!defined $ipkg->name("ümläut-vérbötèn"));
ok(!defined $ipkg->name("spaces. urgs."));

# version =~ [a-zA-Z0-9.+]* , with at least one digit
# initially, version is '', but if you set an invalid one, it will be
# set to undef to warn you something went wrong
ok(!defined $ipkg->version("nodigits_is_not_nice"));
ok(!defined $ipkg->name("symbols#also'bad"));
ok(!defined $ipkg->name("ümläut-vérbötèn"));
ok(!defined $ipkg->name("spaces. urgs."));

# section; 21 tests
ok(!defined $ipkg->section("weird_weird"));
@cat_familiar = qw(admin base comm editors extras graphics libs misc net text web x11);
@cat_opie = qw(Games Multimedia Communications Settings Utilities Applications Console Misc);
foreach (@cat_familiar, @cat_opie) {
    ok($ipkg->section($_) eq $_);
}

# architecture
ok(!defined $ipkg->architecture("weirdarch"));
foreach (qw(arm all)) {
    ok($ipkg->architecture($_) eq $_);
}

# maintainer should be nonempty and at least contain an at sign indicating an e-mail adress
ok(!defined $ipkg->maintainer(undef));
ok(!defined $ipkg->maintainer(""));
ok(!defined $ipkg->maintainer("  "));
ok(!defined $ipkg->maintainer("Someone"));
ok(defined $ipkg->maintainer("Someone, someone\@somewhere.com"));

# description should be nonempty
ok(!defined $ipkg->description(undef));
ok(!defined $ipkg->description(""));
ok(!defined $ipkg->description(" \n "));

# priority
ok(!defined $ipkg->priority("weirdpriority"));
my @priorities = qw(required standard important optional extra);
foreach (@priorities) {
    ok($ipkg->priority($_) eq $_);
}

# depends: empty or comma-separated package names, ie. [a-z0-9.+-]+(,[a-z0-9.+-]+)*
ok(!defined $ipkg->depends(" "));
ok(!defined $ipkg->depends("packages, with, spaces"));
ok($ipkg->depends("packages,without,spaces"));

