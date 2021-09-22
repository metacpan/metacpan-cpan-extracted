use strict;
use warnings;

use Test::More;
use File::Find ();
use ExtUtils::MakeMaker ();

my @files;
File::Find::find({
  no_chdir => 1,
  wanted => sub {
    return
      unless -f;
    push @files, $_;
  },
}, 'lib');

for my $file (@files) {
  like $file, qr{\.pod\z}, "$file is a pod file";
  my $version = MM->parse_version($file);
  $version = undef
    if defined $version && $version eq 'undef';
  is $version, undef, "$file has no version";
}

done_testing;
