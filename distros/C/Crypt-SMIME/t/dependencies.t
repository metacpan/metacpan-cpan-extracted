#!perl
use strict;
use warnings;
use Test::More;

# Test::Dependencies is a bit idiotic when it comes to locating
# metadata files.
my @CLEANUP;
if (!-f 'META.yml') {
    if (-f 'MYMETA.yml') {
        link 'MYMETA.yml', 'META.yml';
        push @CLEANUP, sub { unlink 'META.yml' };
    }
    else {
        plan skip_all =>
          'Either META.yml or MYMETA.yml is required for this test';
    }
}

eval {
    require Test::Dependencies;
    import Test::Dependencies
      style   => 'light',
      exclude => [];
};
if ($@) {
    plan skip_all =>
      'Test::Dependencies required for this test';
}

ok_dependencies();

END {
    $_->() foreach @CLEANUP;
}
