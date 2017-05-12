package t::Ultra;
use warnings; use strict;

sub test_connection {
    my $class = shift;
    my %opt = @_;

    my $suffix = $opt{suffix} || '';
    my %result;

    my $issuer = $ENV{'BBC_ULTRA_ISSUER'};
    my $secret = $ENV{'BBC_ULTRA_SECRET'};
    my $host   = $ENV{'BBC_ULTRA_HOST'};

    if ($issuer && $secret && $host) {
	my %params = (
	    issuer => $issuer, secret => $secret, host => $host,
	    );
	require Bb::Collaborate::Ultra::Connection;
	my $connection = Bb::Collaborate::Ultra::Connection->new(\%params);
	$connection->debug( 1 )
	    if $ENV{'BBC_ULTRA_DEBUG'};
	$params{connection} = $connection;
	return %params
    }
    else {
	return (
	    skip => 'Please set BBC_ULTRA_{ISSUER|SECRET|URL}',
	)
    }
}


1;
