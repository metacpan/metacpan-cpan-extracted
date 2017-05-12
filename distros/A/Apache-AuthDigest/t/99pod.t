use File::Spec;
use File::Find qw(find);

use strict;

eval {
  require Test::More;
  Test::More->import;
  require Test::Pod;
  Test::Pod->import;
};

if ($@) {
  eval {
    require Test::More;
  };

  if ($@) {
    require Test;
    Test->import;
    plan(tests => 0);
  }
  else {
    plan(skip_all => "Test::Pod required for testing POD");
  }
}
else {
  my @files;

  find(
    sub { push @files, $File::Find::name if m!\.p(m|od|l)$! },
    File::Spec->catfile(qw(.. blib lib))
  );

  plan(tests => scalar @files);

  foreach my $file (@files) {
    pod_ok($file);
  }
}
