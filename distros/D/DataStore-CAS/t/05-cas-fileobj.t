#! /usr/bin/env perl -T
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Path::Class;
use Data::Dumper;
use File::stat;

sub dies_like {
	my ($code, $pattern, $comment)= @_;
	try {
		&$code;
		fail "Failed to die during '$comment'";
	}
	catch {
		like($_, $pattern, $comment);
	};
}

use_ok('DataStore::CAS') || BAIL_OUT;

my $self= bless {}, 'main';
sub open_file {
	my @arg_synopsis= map { ref($_) || $_ } @_;
	"store->open_file(@arg_synopsis) was called";
}
sub _file_somefield {
	my @arg_synopsis= map { ref($_) || $_ } @_;
	"store->_file_somefield(@arg_synopsis) was called";
}
sub _file_destroy {}

my $f= bless { hash => '0' x 20, size => 42, a => 1, b => 2, store => $self }, 'DataStore::CAS::File';

is( $f->store, $self, 'store attr' );
is( $f->hash, '0' x 20, 'hash attr' );
is( $f->size, 42, 'size attr' );
is( $f->open('foo'), 'store->open_file(main DataStore::CAS::File HASH) was called', 'open method' );
is( $f->a, 1, 'auto-loaded field' );
is( $f->b, 2, 'auto-loaded field' );
is( $f->somefield('x'), 'store->_file_somefield(main DataStore::CAS::File x) was called', 'auto-loaded method' );
dies_like( sub{ $f->nonexistent }, qr/Can't.*method.*nonexistent.*main/, 'nonexistent method fails' );

done_testing;
