use 5.006;
use strict;
use warnings;
use Capture::Tiny qw/capture/;
use File::pushd qw/pushd/;
use File::Spec::Functions qw/catdir/;
use Test::Deep;
use Test::More 0.92;

use App::mymeta_requires;

# Everything listed in corpus/metaonly/META.json file
# We should usually never have X::Configure::Requires because those would
# have to be satisfied before MYMETA is created, but we force it with
# a bogus module
my %all_reqs = map { $_ => 1 } qw(
  X::Configure::Requires
  X::Runtime::Requires
  X::Runtime::Recommends
  X::Runtime::Suggests
  X::Build::Requires
  X::Test::Requires
  X::Develop::Requires
);

my @cases = (
  {
    options =>  [],
    remove =>   [ qw/X::Develop::Requires/ ],
  },
  {
    options =>  [ qw/--develop/ ],
    remove =>   [  ],
  },
  {
    options =>  [ qw/--no-suggests/ ],
    remove =>   [ qw/X::Runtime::Suggests X::Develop::Requires/ ],
  },
  {
    options =>  [ qw/--no-recommends/ ],
    remove =>   [ qw/X::Runtime::Recommends X::Develop::Requires/ ],
  },
  {
    options =>  [ qw/--no-build --develop/ ],
    remove =>   [ qw/X::Build::Requires/ ],
  },
  {
    options =>  [ qw/--no-configure --develop/ ],
    remove =>   [ qw/X::Configure::Requires/ ],
  },
);

for my $c ( @cases ) {
  my $wd = pushd( catdir( qw/corpus metaonly/ ) );
  my @options = @{$c->{options}};
  my $label = @options ? join(" ", @options) : "(default)";
  local @ARGV = (@options);
  my $app = App::mymeta_requires->new;
  my %expected = %all_reqs;
  delete $expected{$_} for @{ $c->{remove} };
  my $output = capture { $app->run };
  cmp_deeply( [split "\n", $output], bag(sort keys %expected), $label );
}

done_testing;
#
# This file is part of App-mymeta_requires
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
