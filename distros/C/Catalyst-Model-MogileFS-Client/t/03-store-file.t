#!perl

use lib qw(inc t/lib);

use Test::More;
use Catalyst::Model::MogileFS::Client;
use File::Slurp qw/slurp/;

use Test::Catalyst::Model::MogileFS::Client::Utils;

plan tests => 3;

SKIP: {
    my $utils;

	eval {
		$utils = Test::Catalyst::Model::MogileFS::Client::Utils->new;
	};
	if ($@) {
		skip( "Maybe not running mogilefsd, " . $@, 3 );
	}

    my $key  = 'test.key';
    my $file = 'Makefile.PL';

    my $mogile = Catalyst::Model::MogileFS::Client->new(
        {   domain => $utils->domain,
            hosts  => $utils->hosts
        }
    );

    my $bytes = $mogile->store_file( $key, $utils->class, $file );
    is( $bytes, -s $file, 'stored file size test' );
    is( ${ $mogile->get_file_data($key) },
        slurp($file), 'compare file content' );
    ok( $mogile->delete($key), 'delete file' );
}
