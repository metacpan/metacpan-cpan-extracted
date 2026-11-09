use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp ();

use lib 't/lib';
use DBIO::Test::ExtensionSet qw(extension_set_violations);

# ADR 0066 section 2.4: the test is handed the driver as a class name and
# loads it itself; a class that cannot be loaded is a loud exception naming it.

my %fixture = (
  source => { schemas => { public => 1 }, tables => {} },
  target => { schemas => { public => 1 }, tables => {} },
);

ok !TestDBIO::Extension::Deploy->can('new'), 'the driver class is not loaded before the test runs'
  or diag 'something loaded it already';

is_deeply [ extension_set_violations(%fixture, driver => 'TestDBIO::Extension::Deploy', extensions => []) ],
  [], 'a driver given by name is loaded by the test';
ok(TestDBIO::Extension::Deploy->can('new'), 'and is loaded afterwards');

throws_ok {
  extension_set_violations(%fixture, driver => 'TestDBIO::Extension::NoSuchDriver', extensions => []);
} 'DBIO::Exception', 'a driver class that cannot be loaded throws';
like "$@", qr/TestDBIO::Extension::NoSuchDriver/, 'naming the class';
like "$@", qr/driver/, 'and saying it is the driver';

{
  my $dir = File::Temp->newdir;
  mkdir "$dir/TestDBIO" or die $!;
  open my $fh, '>', "$dir/TestDBIO/BrokenDriver.pm" or die $!;
  print $fh "package TestDBIO::BrokenDriver;\nuse strict;\nthis is not perl;\n1;\n";
  close $fh;
  throws_ok {
    local @INC = ("$dir", @INC);
    extension_set_violations(%fixture, driver => 'TestDBIO::BrokenDriver', extensions => []);
  } 'DBIO::Exception', 'a driver class with a compile error throws as well';
  like "$@", qr/TestDBIO::BrokenDriver/, 'naming the class';
}

my $object = TestDBIO::Extension::Deploy->new;
is_deeply [ extension_set_violations(%fixture, driver => $object, extensions => []) ],
  [], 'a driver object is used as it is';

done_testing;
