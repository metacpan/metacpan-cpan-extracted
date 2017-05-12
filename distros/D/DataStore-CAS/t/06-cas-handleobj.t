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

my $instance_count= 1;
my $self= bless {}, 'main';
sub _handle_read {
	my ($self, $handle, undef, $count, $offset)= @_;
	$_[2]= '' unless defined $_[2];
	substr($_[2], $offset||0, $count)= $handle->_data->{char} x $count;
	$count;
}
sub _handle_other_method {
	my @arg_synopsis= map { ref($_) || $_ } @_;
	"store->_handle_other_method(@arg_synopsis)";
}
sub _handle_destroy { $instance_count-- }

my $h= new_ok( 'DataStore::CAS::VirtualHandle', [ $self, { char => 'x' } ] );

# Test our GLOBREF abuse, making sure that _cas and _data give us what we expect
is( $h->_cas, $self, '_cas attr works' );
is_deeply( $h->_data, { char => 'x' }, '_data attr works' );

# Test various forms of the read() function

my $buf;
is( $h->read( $buf, 10 ), 10, 'read 10' );
is( $buf, 'x' x 10, 'read correct data' );

is( read($h, $buf, 10, 5), 10, 'read 10 ofs 5' );
is( $buf, 'x' x 15, 'read correct data' );

# Test method autoloading

is( $h->other_method('a', 'b', 'c'), 'store->_handle_other_method(main DataStore::CAS::VirtualHandle a b c)', 'autoload methods' );
dies_like( sub{ $h->nonexistent }, qr/Can't.*method.*nonexistent.*main/, 'nonexistent method fails' );

# Make sure DESTROY gets called (no circular refs), and that the chaining works

$h= undef;
is( $instance_count, 0, 'no circular refs in handle' );

done_testing;
