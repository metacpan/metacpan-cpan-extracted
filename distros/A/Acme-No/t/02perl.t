use Test::More;

use IO::File;
use File::Spec;
use Config;

use strict;

my @filenames;
my @filehandles;

push @filenames, File::Spec->catfile(qw(t lib perl-good.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-bad.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-no-good.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-no-bad.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-no-bad2.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-no-bad3.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-no-bad4.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-no-bad5.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-string-bad.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-string-good.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-comment1.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-comment2.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-multi-good.pl));
push @filenames, File::Spec->catfile(qw(t lib perl-multi-bad.pl));

foreach my $file (@filenames) {
  push @filehandles, IO::File->new(">$file") or die "cannot open file: $!";
}

my $good_perl = $];
my $bad_perl = $] + 1;
my $good_no_perl = $] + 1;
my $bad_no_perl = $];

# these are only defined in perl >= 5.006
# so supress warnings with 5.00503 (where the 
# tests aren't run anyway)
my $rev = $Config{PERL_REVISION} || 0;
my $ver = $Config{PERL_VERSION} || 0;
my $subver = $Config{PERL_SUBVERSION} || 0;

my $fh = $filehandles[0];
print $fh <<EOF;
use Acme::No;
use $good_perl;
1;
EOF

$fh = $filehandles[1];
print $fh <<EOF;
use Acme::No;
use $bad_perl;
1;
EOF

$fh = $filehandles[2];
print $fh <<EOF;
use Acme::No;
no $good_no_perl;
1;
EOF

$fh = $filehandles[3];
print $fh <<EOF;
use Acme::No;
no $bad_no_perl;
1;
EOF

$fh = $filehandles[4];
print $fh <<EOF;
use Acme::No;
no $rev.$ver.$subver;
1;
EOF

$fh = $filehandles[5];
print $fh <<EOF;
use Acme::No;
no $rev.$ver;
1;
EOF

$fh = $filehandles[6];
print $fh <<EOF;
use Acme::No;
no 5.00503;
1;
EOF

$fh = $filehandles[7];
print $fh <<EOF;
use Acme::No;
no 5.005_03;
1;
EOF

$fh = $filehandles[8];
print $fh <<EOF;
use Acme::No;
no v$bad_no_perl;
1;
EOF

$fh = $filehandles[9];
print $fh <<EOF;
use Acme::No;
no v$good_no_perl;
1;
EOF

$fh = $filehandles[10];
print $fh <<EOF;
use Acme::No;
# no v$good_no_perl;
1;
EOF

$fh = $filehandles[11];
print $fh <<EOF;
use Acme::No;
# no v$bad_no_perl;
1;
EOF

$fh = $filehandles[12];
print $fh <<EOF;
use Acme::No;
use IO::File; no v$good_no_perl;
1;
EOF

$fh = $filehandles[13];
print $fh <<EOF;
use Acme::No;
use IO::File; no v$bad_no_perl;
1;
EOF

foreach my $filehandle (@filehandles) {
  $filehandle->close;
}

if ($] < 5.008) {
  plan skip_all => "perl $]: see the INSTALL document for why";
}
else {
  plan tests => scalar @filenames;
}

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
