
use Test::More;

use IO::File;
use CGI qw(-no_debug);
use File::Spec;

use strict;

my @filenames;
my @filehandles;

push @filenames, File::Spec->catfile(qw(t lib lib-good.pl));
push @filenames, File::Spec->catfile(qw(t lib lib-bad.pl));
push @filenames, File::Spec->catfile(qw(t lib lib-no-good.pl));
push @filenames, File::Spec->catfile(qw(t lib lib-no-bad.pl));

foreach my $file (@filenames) {
  push @filehandles, IO::File->new(">$file") or die "cannot open file: $!";
}

my $good_test = $CGI::VERSION; 
my $bad_test = $good_test + 1;
my $good_no_test = $CGI::VERSION + 1; 
my $bad_no_test = $CGI::VERSION;

my $fh = $filehandles[0];
print $fh <<EOF;
use CGI $good_test;
1;
EOF

$fh = $filehandles[1];
print $fh <<EOF;
use Acme::No;
use CGI $bad_test;
1;
EOF

$fh = $filehandles[2];
print $fh <<EOF;
use Acme::No;
no CGI $good_no_test;
use CGI $good_test qw(-no_debug);
my \$q = CGI->new or die;
die unless UNIVERSAL::isa(\$q, 'CGI');
1;
EOF

$fh = $filehandles[3];
print $fh <<EOF;
use Acme::No;
no CGI $bad_no_test;
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
