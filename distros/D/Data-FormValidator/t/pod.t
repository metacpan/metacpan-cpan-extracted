#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Find;

# Check our Pod
# The test was provided by Andy Lester,
# who stole it from Brian D. Foy
# Thanks to both !

eval {
  require Test::Pod;
  Test::Pod->import;
};

my @files;

if ($@)
{
  plan skip_all => "Test::Pod required for testing POD";
}
elsif ( $Test::Pod::VERSION < 0.95 )
{
  plan skip_all => "Test::Pod 0.95 required for testing POD";
}
else
{
  my $blib = File::Spec->catfile(qw(blib lib));
  find( \&wanted, $blib, 'lib' );
  plan tests => scalar @files;
  foreach my $file (@files)
  {
    pod_file_ok($file);
  }
}

sub wanted
{
  push @files, $File::Find::name if /\.p(l|m|od)$/;
}
