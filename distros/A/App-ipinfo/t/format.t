use utf8;

use strict;
use warnings;
use open qw(:std :utf8);

use Test::More;

use lib qw(t/lib);

my $class = 'Local::ipinfo';
my $method = 'format';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, 'new';

	my $app = $class->new;
	isa_ok $app, $class;
	can_ok $app, 'new', $method;
	};


my $ip = '1.1.1.1';
my @table = (
	[ ASN          => '%a' => '13335' ],
	[ city         => '%c' => 'Brisbane' ],
	[ country      => '%C' => 'AU' ],
	[ abuse        => '%e' => '' ],
	[ flag         => '%f' => '🇦🇺' ],
	[ hostname     => '%h' => 'one.one.one.one' ],
	[ ip           => '%i' => $ip ],
	[ continent    => '%k' => 'Oceania' ],
	[ latitude     => '%L' => '-27.482000' ],
	[ longitude    => '%l' => '153.013600' ],
	[ country_name => '%n' => 'Australia' ],
	[ organization => '%o' => 'AS13335 Cloudflare, Inc.' ],
	[ timezone     => '%t' => 'Australia/Brisbane' ],
	[ newline      => '%N' => "\n" ],
	[ tab          => '%T' => "\t" ],
	[ percent      => '%%' => "%" ],
	);

subtest 'formats' => sub {
	foreach my $row ( @table ) {
		my( $label, $template, $expected ) = $row->@*;

		subtest $label => sub {
			my $app = $class->new( template => $template );
			isa_ok $app, $class;

			my $info = $class->get_info('1.1.1.1');
			isa_ok $info, 'Geo::Details';

			my $s = $app->format($info);
			is $app->format($info), $expected, 'output is correct';
			};
		}
	};

subtest 'empty response' => sub {
	my $info = bless {
		continent    => {},
		country_flag => {},
		meta         => {},
		}, 'Geo::Details';

	foreach my $row ( @table ) {
		my( $label, $template ) = $row->@*;
		next if $template =~ /%[NT%]/;

		subtest $label => sub {
			my $app = $class->new( template => $template );
			isa_ok $app, $class;
			isa_ok $info, 'Geo::Details';
			my $s = $app->format($info);
			is $app->format($info), '', 'output is correct';
			};
		}
	};

done_testing();
