
use Test::More;

use IO::File;
use File::Spec;
use Config;
use File::Spec;

use strict;

my @filenames;
my @filehandles;

push @filenames, File::Spec->catfile(qw(t lib AcmeTestGood.pm));
push @filenames, File::Spec->catfile(qw(t lib acmetest-good.pl));
push @filenames, File::Spec->catfile(qw(t lib AcmeTestBad.pm));
push @filenames, File::Spec->catfile(qw(t lib acmetest-bad.pl));

foreach my $file (@filenames) {
  push @filehandles, IO::File->new(">$file") or die "cannot open file: $!";
}

my $good_no_perl = $] + 1;
my $bad_no_perl = $];

my $lib = File::Spec->catfile(qw(t lib));

my $fh = $filehandles[0];
print $fh <<EOF;
use Acme::No;
no $good_no_perl;
1;
EOF

$fh = $filehandles[1];
print $fh <<EOF;
use lib qw($lib);
use AcmeTestGood;
1;
EOF

$fh = $filehandles[2];
print $fh <<EOF;
use Acme::No;
no $bad_no_perl;
1;
EOF

$fh = $filehandles[3];
print $fh <<EOF;
use lib qw($lib);
use AcmeTestBad;
1;
EOF

foreach my $filehandle (@filehandles) {
  $filehandle->close;
}

# don't execute the *.pm files
@filenames = grep m/\.pl/, @filenames;

plan tests => scalar @filenames;

foreach my $file (@filenames) {
  my $rc = do $file;

  if ($file =~ m/bad/) {
    ok(!$rc, "$file");
  }
  else {
    ok($rc, "$file");
  }
}

