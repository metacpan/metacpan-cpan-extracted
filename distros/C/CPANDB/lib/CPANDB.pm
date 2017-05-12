package CPANDB;

use 5.008005;
use strict;
use warnings;
use IO::File             ();
use DateTime        0.55 ();
use Params::Util    1.00 ();
use ORLite          1.51 ();
use ORLite::Mirror  1.20 ();

our $VERSION = '0.18';
our @LOCATION = (
	locale    => 'C',
	time_zone => 'UTC',
);

sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://svn.ali.as/db/cpandb.bz2';
	$params->{maxage} ||= 24 * 60 * 60; # One day

	# Always turn on string eval debugging if Perl is new enough
	if ( $^V > 5.008008 ) {
		$^P = $^P | 0x800;
	}

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

sub latest {
	my $class = shift;

	# Find the distribution most recently uploaded
	my @latest = CPANDB::Distribution->select(
		'ORDER BY uploaded DESC LIMIT 1',
	);
	unless ( @latest == 1 ) {
		die "Unexpected number of uploads";
	}

	# When was it?
	return $latest[0]->uploaded;
}

sub latest_datetime {
	my $class  = shift;
	my @latest = split /\D+/, $class->latest;
	return DateTime->new(
		year  => $latest[0],
		month => $latest[1],
		day   => $latest[2],
		@LOCATION,
	);
}

sub age {
	my $class    = shift;
	my $latest   = $class->latest_datetime;
	my $today    = DateTime->today( @LOCATION );
	my $duration = $today - $latest;
	return $duration->in_units('days');
}

sub distribution {
	my $self = shift;
	my @dist = CPANDB::Distribution->select(
		'where distribution = ?', $_[0],
	);
	unless ( @dist ) {
		die("Distribution '$_[0]' does not exist");
	}
	return $dist[0];
}

sub graph {
	require Graph;
	require Graph::Directed;
	my $class = shift;
	my $graph = Graph::Directed->new;
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	return $graph;
}

sub easy {
	require Graph::Easy;
	my $class = shift;
	my $graph = Graph::Easy->new;
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	return $graph;	
}

sub xgmml {
	require Graph::XGMML;
	my $class = shift;
	my @param = ( @_ == 1 ) ? ( OUTPUT => IO::File->new( shift, 'w' ) ) : ( @_ );
	my $graph = Graph::XGMML->new( directed => 1, @param );
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	$graph->end;
	return 1;
}

sub csv {
	my $class = shift;
	my $file  = shift;
	my $csv   = IO::File->new($file, 'w');
	foreach my $edge ( CPANDB::Dependency->select ) {
		$csv->print( $edge->distribution . "\t" . $edge->dependency . "\n" );
	}
	$csv->close;
}

1;
