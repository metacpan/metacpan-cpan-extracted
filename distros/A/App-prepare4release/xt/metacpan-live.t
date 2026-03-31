#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all ok diag plan);
use Test2::Tools::Compare qw(like);
use version ();

BEGIN {
	skip_all 'set RELEASE_TESTING=1 to run live MetaCPAN checks'
		unless $ENV{RELEASE_TESTING};
}

use App::prepare4release;
use HTTP::Tiny ();
use JSON::PP ();

plan tests => 6;

my $metacpan_url = 'https://fastapi.metacpan.org/v1/release/perl';

my $http = HTTP::Tiny->new( timeout => 30 );
my $res  = $http->get($metacpan_url);

ok( $res->{success}, 'MetaCPAN GET /release/perl succeeds' )
	or diag "status=$res->{status} reason=$res->{reason}";

my $data = eval { JSON::PP->new->decode( $res->{content} // '' ) };
ok( $data && ref $data eq 'HASH', 'MetaCPAN response is JSON object' )
	or diag $@;

ok( $data->{version}, 'MetaCPAN release has version field' );

{
	local $ENV{PREPARE4RELEASE_PERL_MAX};
	delete $ENV{PREPARE4RELEASE_PERL_MAX};

	my $v = App::prepare4release->fetch_latest_perl_release_version;

	like( $v, qr/\A5\.\d+\z/, 'fetch_latest_perl_release_version looks like 5.xx' );

	my $got = eval { version->parse($v) };
	ok( $got, 'ceiling parses as a Perl version' )
		or diag $@;

	ok(
		$got && $got >= version->parse('v5.10.0'),
		'ceiling is at least 5.10'
	);
}
