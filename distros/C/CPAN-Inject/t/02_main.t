#!/usr/bin/perl

# Main testing for CPAN::Inject

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;
use File::Spec::Functions ':ALL';
use File::Remove          'remove';
use CPAN::Inject;

# Create a testing root directory
my $sources = catdir('t', 'sources');
      if ( -e $sources ) { remove( \1, $sources ) }
END { if ( -e $sources ) { remove( \1, $sources ) } }
ok( ! -e $sources, 'No existing sources directory' );
mkdir $sources;
ok( -e $sources, 'Created sources directory' );





#####################################################################
# Constructor, Accessors, and Basic Methods

SCOPE: {
	my $cpan = CPAN::Inject->new(
		sources => $sources,
		);
	isa_ok( $cpan, 'CPAN::Inject' );
	is( $cpan->sources, $sources, '->sources ok' );
	is( $cpan->author,  'LOCAL',  '->author ok' );
	is(
		$cpan->author_subpath,
		catdir('authors', 'id', 'L', 'LO', 'LOCAL' ),
		'->author_subpath ok',
	);
	is(
		$cpan->author_path,
		catdir($sources, 'authors', 'id', 'L', 'LO', 'LOCAL' ),
		'->author_path ok',
	);
	is(
		$cpan->install_path('Perl-Tarball-1.00.tar.gz'),
		'LOCAL/Perl-Tarball-1.00.tar.gz',
		'->install_path ok',
	);
	is(
		$cpan->install_path(
			catfile('foo', 'bar', 'Perl-Tarball-1.00.tar.gz'),
			),
		'LOCAL/Perl-Tarball-1.00.tar.gz',
		'->install_path ok',
	);
}

SCOPE: {
	my $cpan = CPAN::Inject->new(
		sources => $sources,
		author  => 'ADAMK',
		);
	isa_ok( $cpan, 'CPAN::Inject' );
	is( $cpan->sources, $sources, '->sources ok' );
	is( $cpan->author,  'ADAMK',  '->author ok' );
}

SCOPE: {
	my $cpan = eval {
		CPAN::Inject->from_cpan_config(
			author  => 'ADAMK',
			);
	};
	SKIP: {
		skip( "Current user owns CPAN::Config", 1 ) unless $@;
		like($@,
			qr/(The directory .* does not exist|The sources directory is not owned by the current user)/, 
			'Got expected error',
		);
	}
	SKIP: {
		skip( "Current user does not own CPAN::Config", 2 ) if $@;
		isa_ok( $cpan, 'CPAN::Inject' );
		is( $cpan->author,  'ADAMK',  '->author ok' );
	}
}





#####################################################################
# Add a distribution

SCOPE: {
	my $cpan = CPAN::Inject->new(
		sources => $sources,
		);
	isa_ok( $cpan, 'CPAN::Inject' );

	# Add the distribution
	my $dist = catfile( 't', 'data', 'Config-Tiny-2.09.tar.gz' );
	ok( -f $dist, 'Test distribution exists' );
	is(
		$cpan->add( file => $dist ),
		'LOCAL/Config-Tiny-2.09.tar.gz',
		'->add ok',
	);
	my $author = catdir($sources, 'authors', 'id', 'L', 'LO', 'LOCAL');
	ok( -d $author, 'Created LOCAL base directory' );
	ok(
		-f catfile($author, 'Config-Tiny-2.09.tar.gz'),
		'Copied distribution to the correct destination',
	);
	ok(
		-f catfile($author, 'CHECKSUMS'),
		'Created CHECKSUMS file',
	);	
}

#####################################################################
# Remove a distribution

SCOPE: {
	my $cpan = CPAN::Inject->new(
		sources => $sources,
		);
	isa_ok( $cpan, 'CPAN::Inject' );

	# Remove the distribution
	ok(
		eval { $cpan->remove( dist => 'LOCAL/Config-Tiny-2.09.tar.gz' ); 1 },
		'->remove ok',
	);
	my $author = catdir($sources, 'authors', 'id', 'L', 'LO', 'LOCAL');
	ok(
		! -f catfile($author, 'Config-Tiny-2.09.tar.gz'),
		'Removed distribution file',
	);
}

1;
