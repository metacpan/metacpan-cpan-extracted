use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::DB::Schema;
use base 'DBIx::VersionedSchema';
use Apache::SWIT::Security qw(Hash);

__PACKAGE__->Name('apache_swit_security');

__PACKAGE__->add_version(sub {
	my $dbh = shift;
	local $ENV{AS_SECURITY_SALT} = 'ajweqwe';
	$dbh->do(q{ create table users (
			id serial primary key, 
			name text unique not null,
			password text not null) without oids });
	$dbh->do(q{ insert into users (name, password) 
			values ('admin', '} . Hash('password') . q{') });

	$dbh->do(q{ create table user_roles (
			user_id integer not null references users(id)
				on delete cascade,
			role_id smallint not null,
			constraint user_roles_pk 
				primary key (user_id, role_id),
			constraint valid_role_id_chk check (
				role_id in (1, 2)))
		without oids });
	$dbh->do(q{ insert into user_roles (user_id, role_id)
			values (1, 1) });
});

1;
