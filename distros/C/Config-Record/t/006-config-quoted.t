# -*- perl -*- $Id: 005Config.t,v 1.8 2006/01/27 16:25:50 dan Exp $

use Test::More tests => 68;

BEGIN { use_ok("Config::Record") }

#$| = undef;
use strict;
use warnings;
use Carp qw(confess);
use Test::Harness;
use File::Temp qw(tempfile);
use IO::File;

my $config = <<END;
  name = Foo
  title = "Wizz bang wallop"

  label = "First string " \\
          "split across"
  description = <<EOF
This is a multi-line paragraph.
This is the second line.
And the third
EOF
# Some delibrate blank lines to test parsing...


  eek = ( # Testing an array
    OOhh
    " Aahhh "
    Wizz \\
    Bang
    <<EOF
A long paragraph in
here
EOF
  )
  people = ( # Testing an array of hashes
    {
      forename = John
      surnamne = Doe
    }
    {
      forename = Some
      surname = One
    }
  )
  array = (
    (
      sub1
    )
    (
      sub2
    )
  )
  wizz = { # Testing a hash
    foo = "Elk"
    ooh = "fds"
    eek.wibble = Hurrah
  }
  wibble = { # Testing a hash of hashes
    nice = {
      ooh = (
        weee
        {
          aah = sfd
          oooh = "   Weeee   "
        }
      )
    }
  }
  # Testing spaces in keys
  "  quoted one  " = wizz
  "  quoted \\\\ two  " = "  wizz  "
  "quoted \\" three" = (
     yeah
  )
  "quoted \\\\\\" four" = {
    ooh = ahh
  }
  "quoted \\" five" = {
     "[0]" = notarray
     data = (
        {
          "sub1/key" = hello
          "sub2\\\\/key" = world
        }
        wizz
        {
           "here [2] key" = (
              one
              two
              three
           )
        }
     )
     "other \\\\/" = {
        sub = one
     }
  }
END

my ($fh, $file) = tempfile("tmpXXXXXXX", UNLINK => 1);
print $fh $config;
close $fh;

# First test the constructor with a filename
my $cfg = Config::Record->new(file => $file,
			      debug => $ENV{TEST_DEBUG},
			      features => {quotedkeys => 1 });

# Test plain string
is($cfg->get("name"), "Foo", "Plain string");

# Test quoted string
is($cfg->get("title"), "Wizz bang wallop", "Quoted string");

# Test continuation
is($cfg->get("label"), "First string split across", "Continuation");

# Test here doc
is($cfg->get("description"), <<EOF
This is a multi-line paragraph.
This is the second line.
And the third
EOF
, "Here doc");

# Test array element continuation
is($cfg->get("eek")->[2], "Wizz Bang", "Continuation");

# Test array here doc
is($cfg->get("eek")->[3], "A long paragraph in\nhere\n", "Here doc");

# Test defaults
is($cfg->get("nada", "eek"), "eek", "Defaults");

# Test nested hash/array lookups
ok(defined $cfg->get("wibble/nice"), "Hash key defined");
ok(defined $cfg->get("wibble/nice/ooh"), "Hash, hash key defined");
ok($cfg->get("wibble/nice/ooh", ["oooh"])->[0] eq "weee", "Hash, hash, array value");

# Now test the constructor with a file handle
$fh = IO::File->new($file);
$cfg = Config::Record->new(file => $fh,
			   debug => $ENV{TEST_DEBUG},
			   features => {quotedkeys => 1});

# Test plain string
is($cfg->get("name"), "Foo", "Plain string");

# Test quoted string
is($cfg->get("title"), "Wizz bang wallop", "Quoted string");

# Test continuation
is($cfg->get("label"), "First string split across", "Continuation");

# Test here doc
is($cfg->get("description"), <<EOF
This is a multi-line paragraph.
This is the second line.
And the third
EOF
, "Here doc");

# Test array element continuation
is($cfg->get("eek")->[2], "Wizz Bang", "Continuation");

# Test array here doc
is($cfg->get("eek")->[3], "A long paragraph in\nhere\n", "Here doc");

# Test defaults
is($cfg->get("nada", "eek"), "eek", "Defaults");

# Test nested hash/array lookups
ok(defined $cfg->get("wibble/nice"), "Hash key defined");
ok(defined $cfg->get("wibble/nice/ooh"), "Hash, hash key defined");
ok($cfg->get("wibble/nice/ooh", ["oooh"])->[0] eq "weee", "Hash, hash, array value");

ok(ref($cfg->get("people/[0]")) eq "HASH", "people/[0] is a hash");
is($cfg->get("people/[0]/forename"), "John", "First person forename is John");
is($cfg->get("people/[1]/forename"), "Some", "Second person forename is Some");
eval {
  $cfg->get("people/[2]/forename");
};
ok($@, "too many people");

$cfg->set("people/[2]", { "forename" => "Bob", "surname" => "Man" });
ok(ref($cfg->get("people/[2]")) eq "HASH", "people/[2] is a hash");
is($cfg->get("people/[2]/forename"), "Bob", "Third person forename is Bob");

eval {
  # Root element should be a hash!
  $cfg->get("[0]");
};
ok($@, "root should be a hash");

# Test keys with spaces in them

is($cfg->get('  quoted one  '), "wizz", "Quoted key + value");
is($cfg->get('  quoted \ two  '), "  wizz  ", "Quoted key + value");
is_deeply($cfg->get('quoted " three'), ["yeah"], "Quoted key + array");
is_deeply($cfg->get('quoted \" four'), {"ooh" => "ahh" }, "Quoted key + hash with spaces");

# Testing keys with / and [] in them
is($cfg->get('quoted " five/\\[0\\]/'), "notarray", "Special path chars one");
is($cfg->get('quoted " five/data/[0]/sub1\\/key'), "hello", "Special path chars two");
is($cfg->get('quoted " five/data/[0]/sub2\\\\/key'), "world", "Special path chars three");
is($cfg->get('quoted " five/data/[1]'), "wizz", "Special path chars four");
is($cfg->get('quoted " five/data/[2]/here [2] key/[0]'), "one", "Special path chars five");
is($cfg->get('quoted " five/data/[2]/here [2] key/[1]'), "two", "Special path chars six");
is_deeply($cfg->get('quoted " five/other \\\\/'), {"sub" => "one"}, "Special path chars seven");

# Now lets get a view

my $subcfg = $cfg->view("people/[2]");

is($subcfg->get("forename"), "Bob", "Got forename from view");
is($subcfg->get("surname"), "Man", "Got surname from view");

$subcfg->set("address", [{ "street" => "Long road",
			  "phone" => [
				      "123",
				      "456",
				      ],
			  "city" => "London" },
			 { "street" => "Other road",
			   "phone" => [
				       "513",
				      ],
			   "city" => "London" }]);

is($subcfg->get("address/[0]/street"), "Long road", "Street is long road");
is($subcfg->get("address/[0]/phone/[0]"), "123", "First phone number is 123");

is($subcfg->get("address/[1]/street"), "Other road", "Street is other road");

# Check the original config was altered too

is($cfg->get("people/[2]/address/[0]/street"), "Long road", "Street is long road");
is($cfg->get("people/[2]/address/[0]/phone/[0]"), "123", "First phone number is 123");

is($cfg->get("people/[2]/address/[1]/street"), "Other road", "Street is other road");


# Now test a view or two that fail
eval {
  $cfg->view("people");
};
ok($@, "getting view of people failed");
eval {
  $cfg->view("people/[1]/forename");
};
ok($@, "getting view of people/[1]/forename failed");

# Test with empty constructor & load method

$cfg = Config::Record->new(debug => $ENV{TEST_DEBUG},
			   features => {quotedkeys => 1});

# Shouldn't be anything there yet
eval "$cfg->get('name')";
ok($@ ? 1 : 0, "No defaults");

# Lets set an option
$cfg->set("name" => "Blah");
is($cfg->get("name"), "Blah", "Set option");

# Now load the config record
$fh = IO::File->new($file);
$cfg->load($fh);

# Test plain string - should have overwritten 'Blah'
is($cfg->get("name"), "Foo", "Reload plain string");

# Test quoted string
is($cfg->get("title"), "Wizz bang wallop", "Reloaded quoted string");

# Test defaults
is($cfg->get("nada", "eek"), "eek", "Reloaded defaults");

# Test compound paths
is($cfg->get("wizz/foo"), "Elk", "Compound paths");

# Test '.' in key names
is($cfg->get("wizz/eek.wibble"), "Hurrah", "Compound paths with .");


# Now write it out to another file....
my ($fh2, $file2) = tempfile("tmpXXXXXXX", UNLINK => 1);
$fh2->close;
$cfg->save($file2);

# ...and then read it back in
my $cfg2 = Config::Record->new(debug => $ENV{TEST_DEBUG},
			       file => $file2, features => {quotedkeys => 1});

# Test plain string
is($cfg2->get("name"), "Foo", "Saved plain string");

# Test quoted string
is($cfg2->get("title"), "Wizz bang wallop", "Saved quoted string");

# Test continuation
is($cfg->get("label"), "First string split across", "Continuation");

# Test here doc
is($cfg->get("description"), <<EOF
This is a multi-line paragraph.
This is the second line.
And the third
EOF
, "Here doc");

# Test array element continuation
is($cfg->get("eek")->[2], "Wizz Bang", "Continuation");

# Test array here doc
is($cfg->get("eek")->[3], "A long paragraph in\nhere\n", "Here doc");

# Test defaults
is($cfg2->get("nada", "eek"), "eek", "Saved defaults");

# Test nested hash/array lookups
ok(defined $cfg2->get("wibble/nice"), "Hash key defined");
ok(defined $cfg2->get("wibble/nice/ooh"), "Hash, hash key defined");
ok($cfg2->get("wibble/nice/ooh", ["oooh"])->[0] eq "weee", "Hash, hash, array value");

# Now recursively compare entire hash
use Data::Dumper;
#warn Dumper($cfg->record);
#warn Dumper($cfg2->record);
is_deeply($cfg->record, $cfg2->record, "Entire hash");


# Finally test the constructor with bogus ref

my $bogus = {};
bless $bogus, "Bogus";
eval "Config::Record->new(file => $bogus)";
ok($@ ? 1 : 0, "Bogus constructor");


exit 0;


# Local Variables:
# mode: cperl
# End:
