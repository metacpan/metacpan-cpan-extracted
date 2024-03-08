#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use File::Spec::Functions 'catfile';
use Log::Any '$log';
use Log::Any::Adapter 'TAP', filter => 'warn';

use_ok( 'Data::TableReader' ) or BAIL_OUT;

sub is_alpha { $_[0] =~ /^[a-z]+$/? undef : 'not alpha' }
sub is_num { $_[0] =~ /^[0-9]+$/? undef : 'not numeric' }

# Find fields in the exact order they are present in the file
subtest validation_die => sub {
	my @log;
	my $tr= new_ok( 'Data::TableReader', [
			input => [ ['X'], ['abc'], ['123'], ['def'] ],
			fields => [{ name => 'X', type => \&is_alpha }],
			log => \@log
		], 'TableReader' );
	my $i= $tr->iterator;
	is_deeply( (try { $i->() }), { X => 'abc' }, 'valid row' );
	like( (try { $i->() } catch { $_ }), qr/not alpha/, 'invalid row' );
	is_deeply( (try { $i->() }), { X => 'def' }, 'valid row' );
	is( $i->(), undef, 'eof' );
};

subtest validation_next => sub {
	open(my $csv, '<', \"X\n1\n2\n\n15\nX\nY\nZ\n16\n") or die;
	my $tr= new_ok( 'Data::TableReader', [
			input => [ ['X'], ['1'], ['2'], [''], ['15'], ['X'], ['Y'], ['Z'], ['16'] ],
			fields => [{ name => 'X', type => \&is_num }],
			on_validation_fail => 'next',
			log => $log
		], 'TableReader' );
	is_deeply( $tr->iterator->all, [ { X => 1 }, { X => 2 }, { X => 15 }, { X => 16 } ], 'only numeric values' );
};

subtest validation_use => sub {
	my @log;
	my $tr= new_ok( 'Data::TableReader', [
			input => [ ['X'], ['1'], ['2'], ['x'], ['15'] ],
			fields => [{ name => 'X', type => \&is_num }],
			on_validation_fail => 'use',
			log => \@log
		], 'TableReader' );
	is_deeply( $tr->iterator->all, [ { X => 1 }, { X => 2 }, { X => 'x' }, { X => 15 } ], 'keep all values' );
	is( scalar(grep { $_->[0] eq 'warn' } @log), 1, 'one warning' );
	like( $log[0][1], qr/not numeric/, 'warn about non-numeric' );
};

subtest validation_custom => sub {
	my @log;
	my $tr= new_ok( 'Data::TableReader', [
			input => [ ['X'], ['1'], ['2'], ['x'], ['15'] ],
			fields => [{ name => 'X', type => \&is_num }],
			on_validation_fail => sub {
				my ($reader, $failures, $values, $context)= @_;
				for (@$failures) {
					my ($field, $value_index, $message)= @$_;
					if ($field->name eq 'X') {
						$values->[$value_index]= 0;
						$_= undef;
					}
				}
				@$failures= grep defined, @$failures;
				return 'use';
			},
			log => \@log
		], 'TableReader' );
	is_deeply( $tr->iterator->all, [ { X => 1 }, { X => 2 }, { X => 0 }, { X => 15 } ], 'keep munged value' );
	is_deeply( \@log, [], 'no warnings' );
};

done_testing;

sub open_data {
	my $name= shift;
	my $t_dir= __FILE__;
	$t_dir =~ s,[^\/]+$,,;
	$name= catfile($t_dir, 'data', $name);
	open(my $fh, "<:raw", $name) or die "open($name): $!";
	return $fh;
}
