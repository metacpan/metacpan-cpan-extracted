use utf8;

use strict;
use warnings;
use open qw(:std :utf8);

use Encode qw(encode);
use Test::More;

plan skip_all => 'need the JSON module to run this test' unless require JSON;

use lib qw(t/lib);
my $class  = 'Local::ipinfo';
my $method = 'format';

my $ip = '1.1.1.1';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, $method;
	};

subtest 'format JSON' => sub {
	my $template = '%j';
	my $app = $class->new( template => $template );
	isa_ok $app, $class;

	my $info = $class->get_info('1.1.1.1');
	isa_ok $info, 'Geo::Details';

	my $perl_string = $app->format($info);
	my $raw_string = encode 'UTF-8', $perl_string;

	my $perl = eval { JSON::decode_json($raw_string) };
	cmp_ok length $@, '==', 0, 'no eval error' or diag "ERROR: $@\nOCTETS: $raw_string";
	};


done_testing();
