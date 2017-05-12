use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('Config::Any::Merge') }

my @files = qw{t/conf/test.ini t/conf/test2.ini};
my @stems = qw{t/conf/test t/conf/test2};

my $check_nooverride = { foo => 'bar' };
my $check_override = { foo => 'baz' };

my $result_override   = Config::Any::Merge->load_files( { files => \@files,  use_ext => 1 } );
my $result_nooverride = Config::Any::Merge->load_files( { files => \@files, use_ext => 1, override => 0 } );


is_deeply($result_override, $check_override,     'Overriding values with override => 1');
is_deeply($result_nooverride, $check_nooverride, 'Forcing default values with override => 0');

0;
