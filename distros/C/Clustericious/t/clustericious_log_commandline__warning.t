use strict;
use warnings;
use Test::More;
use Capture::Tiny qw( capture );

BEGIN {
   plan skip_all => 'test requires Capture::Tiny' unless eval q{ use Capture::Tiny qw( capture ); 1 };
}

plan tests => 1;

my($out,$err) = capture { require Clustericious::Log::CommandLine };
is $err, '', 'no warnings';


