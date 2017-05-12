#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 36;
use lib grep { -d } qw(../lib ./lib ./t/lib);

use DB::Transaction qw(run_in_transaction);

{
	package stub::db;

	sub new {
		return bless {
			AutoCommit => 'subumbonal-palaeographically',
			RaiseError => 'spot-lipped-hyposternum',
		};
	}

	sub reset { $_[0] = stub::db->new }

	sub DESTROY {}
	sub AUTOLOAD {
		my ($self, @args) = @_;
		(my $method = our $AUTOLOAD) =~ s{.*:}{};
		push @{$self->{method_calls}{$method}}, [@args];
		return $self;
	}
}

my $stub_dbh = stub::db->new;

sub my_try(&) {
	my $code = shift;
	my $error = do {
		local $@;
		eval {
			$code->();
		};
		$@;
	};
	return $error;
}

# if the code you're transacting fails, we roll back
{
	# sanity
	ok( (my $prev_autocommit = $stub_dbh->{AutoCommit}) ne 0, '$stub_dbh is in a known state' );
	ok( (my $prev_raiseerror = $stub_dbh->{RaiseError}) ne 1, '$stub_dbh is in a known state' );

	my $error = my_try {
		run_in_transaction {
			# track internal state
			push @{$stub_dbh->{state}}, +{
				AutoCommit => $stub_dbh->{AutoCommit},
				RaiseError => $stub_dbh->{RaiseError},
			};

			# blow up
			die "it's a trap!";
		} db_handle => $stub_dbh;
	};

	like( $error, qr/it's a trap/, '$@ bubbled up' );
	ok( ! exists $stub_dbh->{method_calls}{commit}, "didn't try to commit" );
	is_deeply( $stub_dbh->{method_calls}{rollback}, [[]], 'rolled back' );
	is_deeply( $stub_dbh->{state}, [{
		AutoCommit => 0,
		RaiseError => 1,
	}], 'Set AutoCommit and RaiseError correctly' );

	is( $stub_dbh->{AutoCommit}, $prev_autocommit, 'restored AutoCommit on $stub_dbh' );
	is( $stub_dbh->{RaiseError}, $prev_raiseerror, 'restored RaiseError on $stub_dbh' );

	$stub_dbh->reset;
}

# successful transaction; we'll commit
{
	my $out;
	my $error = my_try {
		$out = run_in_transaction { 1 } db_handle => $stub_dbh;
	};

	is( $error, '', 'no errors' );
	is( $out, 1, 'the transaction completed successfully' );
	is_deeply( $stub_dbh->{method_calls}{commit}, [[]], 'committed outer transaction' );

	$stub_dbh->reset;
}

# your on_error must be a known action
{
	my $action = 'funds-StRaphael';
	my $error = my_try {
		run_in_transaction {
			die;
		} db_handle => $stub_dbh, on_error => $action;
	};
	like( $error, qr/Don't know how to handle error action '$action'/, 'on_error actions are validated' );
}

# If you're nesting transactions, we only commit when the topmost one finishes
{
  my $committed = sub {	exists $stub_dbh->{method_calls}{commit} };
  my $rolled_back = sub {	exists $stub_dbh->{method_calls}{rollback} };

	my $fun = sub {
		my (%args) = @_;

		$stub_dbh->reset;

		run_in_transaction {
			my $ok;
			my_try {
				$ok = run_in_transaction {
					die 'rugby-Chleuh' if $args{is_inner_die};
					1;
				} db_handle => $stub_dbh, on_error => $args{on_error};
			};
			ok( ! $committed->(), "inner transactions don't commit" );

			if ($args{is_inner_die}) {
				ok( ! $ok, 'failures in transactions are messaged back to caller' );

				if ($args{on_error} eq 'continue') {
					ok( ! $rolled_back->(), 'did not roll back nested transaction (on_error => continue)' );
				} else {
					ok( $rolled_back->(), "rolled back on failed inner transaction, $args{on_error}" );
				}
			} else {
				ok( $ok, 'success in transactions is messaged back to caller' );
				is( $@, '', 'no assertions visible' );
				ok( ! $rolled_back->(), 'rolled back nested transaction (on_error => rollback)' );
			}

		} db_handle => $stub_dbh;

		ok( $committed->(), 'committed outer transaction despite a failure' );
		if ($args{on_error} eq 'continue') {
			ok( ! $rolled_back->(), 'did not roll back outer transaction (recovered, presumably)' );
		} else {
			ok( scalar @{$stub_dbh->{method_calls}{rollback} || []} <= 1, 'rolled back inner transaction but not outer transaction' );
		}
	};

	$fun->(
		is_inner_die => 1,
		on_error => 'continue',
	);

	$fun->(
		is_inner_die => 0,
		on_error => 'continue',
	);

	$fun->(
		is_inner_die => 0,
		on_error => 'rollback',
	);

	$fun->(
		is_inner_die => 1,
		on_error => 'rollback',
	);
}

# here's a bad package that does something naughty
{
	package bad::citizen;
	sub new { bless \@_ }
	sub DESTROY { undef $@ }
	sub AUTOLOAD {}
}

# On some versions of perl, destroyers may unset $@; we're immune to it.
{
	my $expected_exceptions = qr/(?:the hills are alive|an error was encountered in your transaction)/;

	{
		local $@;
		eval {
			run_in_transaction {
				my $fake_dbh = bad::citizen->new;
				die 'the hills are alive';
			} db_handle => $stub_dbh, on_error => 'rollback';
		};

		like( $@, $expected_exceptions, 'if $@ is unintentionally unset on object destruction, we set a sensible default error' );
	}

	{
		local $@;
		run_in_transaction {
			my $fake_dbh = bad::citizen->new;
			die 'the hills are alive';
		} db_handle => $stub_dbh, on_error => 'continue';

		like( $@, $expected_exceptions, 'if $@ is unintentionally unset on object destruction, we set a sensible default error' );
	}
}
