use Test::More;

diag( "You'll get some deprecation warnings." );
diag( "These tests will fail when the xisbn service disappears" );
diag( "You can safely ignore these failures" );

# I'm assuming that when the service disappears, this host will be
# unreachable
BEGIN {
	require IO::Socket;

	my $host = 'xisbn.worldcat.org';

	my $socket = IO::Socket::INET->new(
		PeerAddr => "$host:80",
		Timeout  => 5,
		);

	unless( $socket )
		{
		print STDERR <<"HERE";

--------------------------------------------------------
I cannot run these tests unless I can connect to $host.
You may not be connected to the network or the host may
be down.
--------------------------------------------------------
HERE

		plan skip_all => "Could not reach $host: skipping tests";
		}
	}




my $hash = {
	'1565922573' => [qw(0585054061)],
	'0684833395' => [qw(0671502336  044011120X  0679437223  0440204399  0886461251  0684865130  067189854X  070898164X  1560549602  0736690859  0736689621  0671202960  0224613286  0886464935  5237000665  9660301588  1560549238  8401410266  9576773075  0552015008  2246269318  8388087398  5718100012  8306023056  4653014507  5770770910  8385855807  7805676291  8939202376  8939202384  8939202392  9633070597  9735761599  3596125723  5273001285  7531213451  8387974811  8474444896  8501009261  8700199583  8700964344  8845228827  9146133690  9512045583  9635483325)],
	};

use_ok( "Business::ISBN", 2 );
use_ok( "Business::xISBN" );

foreach my $string ( sort keys %$hash ) {
	local $^W=0;
	my $isbn = Business::ISBN->new( $string );
	isa_ok( $isbn, 'Business::ISBN10' );
	ok( $isbn->is_valid, "$isbn is valid" );

	is( $isbn->_xisbn_url,
		"http://xisbn.worldcat.org/xid/isbn/$string",
		"URL is correct for $string" );

	my $expected = $hash->{$isbn};

	#scalar context
	my $isbns = $isbn->xisbn;
	isa_ok( $isbns, ref [] );
	my $count = grep { /$string/ } @$isbns;
	is( $count, 0, "List does not contain $string" );
	eq_array( $isbns, $expected, "List is correct" );

	#list context
	my @isbns = $isbn->xisbn;
	$count = grep { /$string/ } @isbns;
	is( $count, 0, "List does not contain $string" );
	eq_array( \@isbns, $expected, "List is correct" );
	}

done_testing();
