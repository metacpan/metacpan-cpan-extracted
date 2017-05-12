use strict;
use warnings;
use Test::More tests => 3;
use Config::Any::Merge;

BEGIN { use_ok('Config::Any::Merge') }

my @files = qw{t/conf/test-deep1.ini t/conf/test-deep2.ini};

my $check_override   = { foo => { bar => 'baz', qux => 'corge' } };
my $check_nooverride = { foo => { bar => 'baz', qux => 'quux'  } };

my $result_override   = Config::Any::Merge->load_files( { files => \@files, use_ext => 1, override => 1 } );
my $result_nooverride = Config::Any::Merge->load_files( { files => \@files, use_ext => 1, override => 0 } );


is_deeply($result_override,   $check_override,   'Overriding values with override => 1');
is_deeply($result_nooverride, $check_nooverride, 'Forcing default values with override => 0');

0;
