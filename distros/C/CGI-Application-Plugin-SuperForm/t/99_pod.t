use Test::More;
 
use File::Spec;
use File::Find;
use strict;
 
eval {
  require Test::Pod;
  Test::Pod->import;
};
 
my @files;
 
if ($@) {
  plan skip_all => "Test::Pod required for testing POD";
}
else {
  my $blib = File::Spec->catfile(qw(blib lib));
  find(\&wanted, $blib);
  plan tests => scalar @files;
  foreach my $file (@files) {
    pod_file_ok($file);
  }
}
 
sub wanted {
  push @files, $File::Find::name if /\.p(l|m|od)$/;
} 
