use strict; use warnings;

use Test::More tests => 15;

use Async;

my @global = qw( $. $@ $! $^E $? );
my %expect; @expect{ @global } = ( $., $@, $!, $^E, $? );

for ( 1 .. 10 ) {
	my $proc = do { local ( $., $@, $!, $^E, $? ); Async->new( sub { '' } ) };
	isa_ok $proc, 'Async';
}

my %have; @have{ @global } = ( $., $@, $!, $^E, $? );
is $have{ $_ }, $expect{ $_ }, $_ for @global;
