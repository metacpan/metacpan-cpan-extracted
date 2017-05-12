use warnings; use strict;
use Test::More tests => 3;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;
use Bb::Collaborate::Ultra::Context;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 3
	unless $connection;

    #
    # context doesn't have a delete yet, so be frugal with creating them
    $connection->connect;
    my $ext_id = sprintf("test-context-%d", 3287 );
    my $context_name = "context.t: ".$ext_id;

    my $context;
    my @contexts = Bb::Collaborate::Ultra::Context->get( $connection, {
	extId => $ext_id,
    });

    is exception {
	$context = Bb::Collaborate::Ultra::Context->find_or_create(
		$connection, {
		extId => $ext_id,
		name => $context_name,
		label => uc $ext_id,
	    });
	}, undef, "context post - lives";

    isa_ok $context, 'Bb::Collaborate::Ultra::Context';
    ok $context->id, "context id";

}
