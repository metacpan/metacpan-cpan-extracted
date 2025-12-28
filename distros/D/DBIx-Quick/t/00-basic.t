#!/usr/bin/env perl

use v5.16.3;

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;
use Test::MockObject;
use Data::Dumper;

{
	my $dbh = Test::MockObject->new;
	my %queries;
	$dbh->mock( do => sub {
		shift;
		$queries{shift()} = 1;
	});
	$dbh->mock( selectall_arrayref => sub {
		shift;
		my $query = shift;
		$queries{$query} = 1;
		#						print Data::Dumper::Dumper \%queries;
		my @return;
		if ($query eq users_search_sql()) {
			push @return, {id => 1, username => 'User', surname => 'Luser', id_address => 3};
		}
		if ($query eq users_search_by_id()) {
			push @return, {id => 1, username => 'User', surname => 'Luser', id_address => 3};
		}
		if ($query eq address_search_by_id()) {
			push @return, {id => 3, city => 'Brussels'};
		}
		if ($query eq free_search_addresses_sql()) {
			push @return, {id => 3, city => 'Berlin'};
			push @return, {id => 3, city => 'Berlstedt'};
		}
		return [@return];
	});
	package DBIx::Quick::Test::Users {
		use v5.16.3;

		use strict;
		use warnings;

		use DBIx::Quick;

		sub dbh {
			return $dbh;
		}

		table 'users';

		field id => (is => 'ro', search => 1, pk => 1);
		field user_name => (is => 'rw', required => 1, search => 1, column => 'username');
		field surname => (is => 'rw');
		field id_address => (is => 'rw', required => 1, fk => ['DBIx::Quick::Test::Addresses', 'id', 'addresses'], search => 1);
		instance_has shouting_surname => (is => 'lazy');
		instance_sub _build_shouting_surname => sub {
			my $self = shift;
			return uc($self->surname);
		};

		fix;
	}
	package DBIx::Quick::Test::Addresses {
		use v5.16.3;

		use strict;
		use warnings;

		use DBIx::Quick;

		sub dbh {
			return $dbh;
		}

		table 'addresses';

		field id => (is => 'ro', search => 1, pk => 1);

		field city => (is => 'rw');

		fix;
	}
	ok(DBIx::Quick::Test::Users->can('new'), '->new implemented for the DAO');
	ok(DBIx::Quick::Test::Users::Instance->can('new'), '->new implemented for the instance');
	my $user = DBIx::Quick::Test::Users::Instance->new(user_name => 'User', surname => 'Luser', id_address => 3);
	ok($user->isa('DBIx::Quick::Test::Users::Instance'), 'Users can be instanced successfully');
	my $dao = DBIx::Quick::Test::Users->new;
	ok($dao->isa('DBIx::Quick::Test::Users'), 'Users DAO can be instanced successfully');
	$dao->insert($user);
	ok($queries{'INSERT INTO users ( id_address, surname, username) VALUES ( ?, ?, ? )'}, 'Inserting a user is succesfully');
	($user) = @{$dao->search(user_name => 'User')};
	ok($queries{users_search_sql()}, 'Correct query sent to recover user');
	ok($user->isa('DBIx::Quick::Test::Users::Instance'), 'Users can be recovered');
	is($user->id, 1, 'User id makes sense');
	is($user->user_name, 'User', 'User username makes sense');
	is($user->surname, 'Luser', 'User surname makes sense');
	is($user->shouting_surname, 'LUSER', 'instance_sub and instance_has work fine');
	$user = $user->fetch_again;
	ok($user->isa('DBIx::Quick::Test::Users::Instance'), '(fetch_again) Users can be recovered');
	is($user->id, 1, '(fetch_again) User id makes sense');
	is($user->user_name, 'User', '(fetch_again) User username makes sense');
	is($user->surname, 'Luser', '(fetch_again) User surname makes sense');
	is($user->shouting_surname, 'LUSER', '(fetch_again) instance_sub and instance_has work fine');
	my ($address) = @{$user->addresses};
	ok($queries{address_search_by_id()}, 'The address search by user query matches');
	ok($address->isa('DBIx::Quick::Test::Addresses::Instance'), 'Address can be recovered by foreign key');
	my @addresses = @{DBIx::Quick::Test::Addresses->new->free_search(
		-join => [
			'addresses.id=users.id_address', 'users',
		],
		-where => {
			'addresses.city' => { -like => 'Berl%' },
			'users.surname' => { -like => 'Mar%' },
		}
	)};
	ok ($queries{free_search_addresses_sql()}, 'Correct query generated from free search of addresses');
	is (scalar @addresses, 2, 'Two addresses recovered in free search');
	is ($addresses[0]->city, 'Berlin', 'Can recover an address in free search');
	is ($addresses[1]->city, 'Berlstedt', 'And two too');
	dies_ok {
		DBIx::Quick::Test::Users->search(
			surname => 'García',
		);
	} 'Do not search by no searchable in normal search to prevent unwanted costly searches';
}

{
	my $dbh = Test::MockObject->new;
	my %queries;
	$dbh->mock( do => sub {
		shift;
		$queries{shift()} = 1;
	});
	$dbh->mock( selectall_arrayref => sub {
		shift;
		my $query = shift;
		$queries{$query} = 1;
	#		print Data::Dumper::Dumper \%queries;
		my @return;
		if ($query eq 'SELECT addresses.city, addresses.id FROM addresses WHERE ( city = ? )') {
			push @return, {id => 33, city => 'Pekin'};
		}
		if ($query eq 'SELECT users.id, users.id_address, users.surname, users.username FROM users WHERE ( id_address = ? )') {
			push @return, {id => 100, username => 'juanito', surname => 'not important', id_address => 33};
			push @return, {id => 101, username => 'francisquito', surname => 'not important', id_address => 33};
		}
		return [@return];
	});
	package DBIx::Quick::Test::Users2 {
		use v5.16.3;

		use strict;
		use warnings;

		use DBIx::Quick;

		sub dbh {
			return $dbh;
		}

		table 'users';

		field id => (is => 'ro', search => 1, pk => 1);
		field user_name => (is => 'rw', required => 1, search => 1, column => 'username');
		field surname => (is => 'rw');
		field id_address => (is => 'rw', required => 1, fk => ['DBIx::Quick::Test::Addresses2', 'id', 'addresses', 'users'], search => 1);
		instance_has shouting_surname => (is => 'lazy');
		instance_sub _build_shouting_surname => sub {
			my $self = shift;
			return uc($self->surname);
		};

		fix;
	}
	package DBIx::Quick::Test::Addresses2 {
		use v5.16.3;

		use strict;
		use warnings;

		use DBIx::Quick;

		sub dbh {
			return $dbh;
		}

		table 'addresses';

		field id => (is => 'ro', search => 1, pk => 1);

		field city => (is => 'rw', search => 1);

		fix;
	}
	my ($pekin) = @{DBIx::Quick::Test::Addresses2->search(city => 'Pekin')};
	my ($juan, $paco) = @{$pekin->users};
	is $juan->user_name, 'juanito', 'One user recovered by fk declared in another object';
	is $paco->user_name, 'francisquito', 'Two users recovered by fk declared in another object';

}
sub users_search_sql {
	return 'SELECT users.id, users.id_address, users.surname, users.username FROM users WHERE ( username = ? )';
}

sub users_search_by_id {
	return 'SELECT users.id, users.id_address, users.surname, users.username FROM users WHERE ( id = ? )';
}

sub address_search_by_id {
	return 'SELECT addresses.city, addresses.id FROM addresses WHERE ( id = ? )';
}

sub free_search_addresses_sql {
	return 'SELECT addresses.city, addresses.id FROM addresses INNER JOIN users ON ( addresses.id = users.id_address ) WHERE ( ( addresses.city LIKE ? AND users.surname LIKE ? ) )';
}
