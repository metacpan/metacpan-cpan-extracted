# -*- perl -*- $Id: 005Config.t,v 1.8 2006/01/27 16:25:50 dan Exp $

use Test::More tests => 6;

BEGIN { use_ok("Config::Record") }

#$| = undef;
use strict;
use warnings;
use Carp qw(confess);
use Test::Harness;
use File::Temp qw(tempfile);
use IO::File;

my ($fh, $file) = tempfile("tmpXXXXXXX", UNLINK => 1);
my ($subfh1, $subfile1) = tempfile("tmpXXXXXXX", UNLINK => 1);
my ($subfh2, $subfile2) = tempfile("tmpXXXXXXX", UNLINK => 1);
my ($subfh3, $subfile3) = tempfile("tmpXXXXXXX", UNLINK => 1);

my $config = <<END;
  wibble = \@include($subfile1)
  staff = (
    \@include($subfile2)
    \@include($subfile3)
  )
END

my $subconfig1 = <<END;
    nice = {
      ooh = (
        weee
        {
          aah = sfd
          oooh = "   Weeee   "
        }
      )
    }
END

my $subconfig2 = <<END;
  firstname = Joe
  lastname = Bloggs
END

my $subconfig3 = <<END;
  firstname = John
  lastname = Doe
END

print $fh $config;
close $fh;

print $subfh1 $subconfig1;
close $subfh1;
print $subfh2 $subconfig2;
close $subfh2;
print $subfh3 $subconfig3;
close $subfh3;

# First test the constructor with a filename
my $cfg = Config::Record->new(file => $file,
			      features => { includes => 1 },
			      debug => ($ENV{TEST_DEBUG} || 0));

# Test nested hash/array lookups
ok(defined $cfg->get("wibble/nice"), "Hash key defined");
ok(defined $cfg->get("wibble/nice/ooh"), "Hash, hash key defined");
ok($cfg->get("wibble/nice/ooh", ["oooh"])->[0] eq "weee", "Hash, hash, array value");

is_deeply($cfg->get("staff/[0]"), { firstname => "Joe", lastname => "Bloggs" }, "First person");
is_deeply($cfg->get("staff/[1]"), { firstname => "John", lastname => "Doe" }, "First person");

exit 0;

# Local Variables:
# mode: cperl
# End:
