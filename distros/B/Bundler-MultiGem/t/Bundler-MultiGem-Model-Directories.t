#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Test::Deep;
use Test::Exception;

BEGIN {
    use_ok( 'Bundler::MultiGem::Model::Directories' ) || print "Bail out!\n";
}

# Context initialization
{
	my $empty = Bundler::MultiGem::Model::Directories->new();
	is_deeply($empty, {}, 'empty initialization');
	dies_ok { $empty->validates } 'empty Directories should fail validation';

	my $config = {
		foo => 'bar',
		cache => [],
		directories => [],
	};
	my $foo = Bundler::MultiGem::Model::Directories->new($config);
	is_deeply($foo, $config, 'config initialization');
	is_deeply($foo->validates, $foo, 'validation passed');
}