use strict;
use warnings;
use Test::Harness;
use File::Spec;
use File::Glob qw( bsd_glob );
use lib map { File::Spec->rel2abs($_) } qw( blib/lib blib/arch lib );

my $test2 = eval {
  require Test2;
  require Test2::Suite;
  require Test::Builder;
  Test::Builder->can('context');
};

my @tests = bsd_glob 't/*.t';
push @tests, bsd_glob 't2/*.t' if $test2;

Test::Harness::runtests(@tests);
