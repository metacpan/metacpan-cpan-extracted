
use Test::More;

use IO::File;
use File::Spec;

use strict;

my @filenames;
my @filehandles;

push @filenames, File::Spec->catfile(qw(t lib pragma-good.pl));
push @filenames, File::Spec->catfile(qw(t lib pragma-bad.pl));
push @filenames, File::Spec->catfile(qw(t lib pragma-bad-good.pl));
push @filenames, File::Spec->catfile(qw(t lib pragma-no-good.pl));

foreach my $file (@filenames) {
  push @filehandles, IO::File->new(">$file") or die "cannot open file: $!";
}

my $fh = $filehandles[0];
print $fh <<EOF;
use Acme::No;
use strict;
1;
EOF

$fh = $filehandles[1];
print $fh <<EOF;
use Acme::No;
use blarg;
1;
EOF

$fh = $filehandles[2];
print $fh <<EOF;
use Acme::No;
use strict;
\$foo = 1;   # this should error under strict;
1;
EOF

$fh = $filehandles[3];
print $fh <<EOF;
use Acme::No;
use strict;
my \$foo = 1;

no strict qw(vars);
\$bar = 1;   # this should be ok
1;
EOF

foreach my $filehandle (@filehandles) {
  $filehandle->close;
}

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

1;
