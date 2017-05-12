package DBI::Easy;

use Class::Easy::Base;

use DBI 1.611;

#use Hash::Util;

use vars qw($VERSION);
$VERSION = '0.24';

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# interface splitted to various sections:
# sql generation stuff prefixed with sql and located
# at DBI::Class::SQL
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

use DBI::Easy::SQL;

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# real dbh operations contains methods fetch_* and no_fetch
# and placed in DBI::Class::DBH
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

use DBI::Easy::DBH;

use DBI::Easy::DriverPatcher;

use DBI::Easy::Helper;

# bwahahahaha
our %GREP_COLUMN_INFO = qw(TYPE_NAME 1 mysql_values 1);

our $wrapper = 1;

our $H = 'DBI::Easy::Helper';

sub new {
	my $class  = shift;
	
	my $params;
	my $init_params;
	
	$init_params = $class->_init (@_)
		if $class->can ('_init');
	
	$params = $init_params || {(@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH')
		? %{$_[0]}
		: @_
	};
	
	bless $params, $class;
}

sub import {
	my $class = shift;
	
	unless (${"${class}::imported"}) {
		make_accessor ($class, 'dbh', is => 'rw', global => 1);
		make_accessor ($class, 'dbh_modify', is => 'rw', global => 1, default => sub {
			return shift->dbh;
		});
	}

	if (! ${"${class}::wrapper"} and $class ne __PACKAGE__ and ! ${"${class}::imported"} ) {
		
		debug "importing $class";
		
		my $t = timer ('init_class');
		$class->_init_class;
		
		$t->lap ('init_db');
		
		# we call _init_db from package before real db 
		$class->_init_db;
		
		$t->lap ("init_collection $class");
		
		$class->_init_collection
			if $class->is_collection;
		
		$t->lap ("dbh check and accessors $class");
		
		die "can't use database class '$class' without db connection: $DBI::errstr"
				if ! $class->dbh or $class->dbh eq '0E0';

		die "can't retrieve table '".$class->table_name."' columns for '$class'"
			unless $class->_init_make_accessors;
		
		$t->lap ("init_last $class");
		
		$class->_init_last;
		
		$t->end;
		
		# my $driver = $class->dbh->get_info (17);
		# warn "driver name from
		# get_info ($DBI::Const::GetInfoType{SQL_DBMS_NAME}): $driver";
	}
	
	${"${class}::imported"} = 1;
	
	$class::SUPER->import (@_)
		if (defined $class::SUPER);
	
}

sub _init_db {
	my $self = shift;
	$self->dbh (DBI->connect);
}

sub _init_class {
	my $self = shift;

	my $ref  = ref $self || $self;
	
	my @pack_chunks = split /\:\:/, $ref;
	
	my $is_collection = 0;
	
	# fix for collections
	if ($pack_chunks[-1] eq 'Collection') {
		pop @pack_chunks;
		
		make_accessor ($ref, 'record_package', is => 'rw', global => 1);
		
		$is_collection = 1;
		
	} elsif ($pack_chunks[-1] eq 'Record') {
		pop @pack_chunks;
	}
	
	make_accessor ($ref, 'is_collection', default => $is_collection);
	
	my $table_name = DBI::Easy::Helper::table_from_package ($pack_chunks[-1]);
	
	# dies when this method called without object reference;
	# expected behaviour
	
	my $common_table_prefix = '';
	
	$common_table_prefix = $ref->common_table_prefix
		if $ref->can ('common_table_prefix');
	
	make_accessor (
		$ref, 'table_name', is => 'rw', global => 1,
		default => $common_table_prefix . $table_name
	) unless $ref->can ('table_name');
	
	make_accessor ($ref, '_date_format', is => 'rw', global => 1);
	
	make_accessor (
		$ref, 'column_prefix', is => 'rw', global => 1,
		default => $ref->table_name . "_"
	) unless $ref->can ('column_prefix');
	
	make_accessor ($ref, 'fieldset', is => 'rw', default => '*');
	
	make_accessor ($ref, 'prepare_method',  is => 'rw', global => 1,
		default => 'prepare_cached');
	make_accessor ($ref, 'prepare_param', is => 'rw', global => 1,
		default => 3);
	make_accessor ($ref, 'undef_as_null', is => 'rw', global => 1,
		default => 0);
		
}

sub _init_collection {
	my $self = shift;
	
	my $rec_pkg = $self->record_package;
	
	unless ($rec_pkg) {
		my $ref  = ref $self || $self;
	
		my @pack_chunks = split /\:\:/, $ref;
		
		pop @pack_chunks;
		
		$rec_pkg = join '::', @pack_chunks;
		
		# TODO: move to Class::Easy
		unless (try_to_use ($rec_pkg)) {
			die unless try_to_use ($rec_pkg . '::Record');
		}
		
		$self->record_package ($rec_pkg);
	}
	
}

sub _detect_vendor {
	my $class = shift;
	
	my $dbh = $class->dbh;
	
	my $vendor = lc ($dbh->get_info(17));
	
	make_accessor ($class, 'dbh_vendor', default => $vendor);
	
	my $vendor_pack = "DBI::Easy::Vendor::$vendor";
	my $have_vendor_pack = try_to_use_quiet ($vendor_pack);
	
	unless ($have_vendor_pack) {
		$vendor_pack = "DBI::Easy::Vendor::Base";
		die unless try_to_use_quiet ($vendor_pack);
	}
	
	no strict 'refs';
	
	push @{"$class\::ISA"}, $vendor_pack;
	
	use strict 'refs';
	
	$class->_init_vendor;
	
}

# here we retrieve fields and create make_accessors
sub _init_make_accessors {
	my $class = shift;
	
	my $table_name    = $class->table_name;
	my $column_prefix = $class->column_prefix;
	
	# detecting vendor
	$class->_detect_vendor;
	
	my $t = timer ('columns info wrapper');
	
	my $columns = $class->_dbh_columns_info;
	
	$t->end;
	
	make_accessor ($class, 'columns', default => $columns);
	make_accessor ($class, 'column_values', is => 'rw');
	
	my $fields = {};
	
	make_accessor ($class, 'fields', default => $fields);
	make_accessor ($class, 'field_values', is => 'rw');
	
	my $pri_key;
	my $pri_key_column;
	
	foreach my $col_name (keys %$columns) {
		my $col_meta = $columns->{$col_name};
		# here we translate rows
		my $field_name = lc ($col_name); # oracle fix
		
		if (
			defined $column_prefix
			and $column_prefix ne ''
			and $col_name =~ /^$column_prefix(.*)/i
		) {
			$field_name = lc($1);
		}
		
		# field meta referenced to column meta
		# no we can use $field_meta->{col_name} and $col_meta->{field_name}
		$fields->{$field_name} = $col_meta;
		
		$col_meta->{field_name} = $field_name;
		
		if ($col_meta->{type_name} eq 'ENUM' and $#{$col_meta->{mysql_values}} >= 0) {
			make_accessor ($class, "${field_name}_variants",
				default => $col_meta->{mysql_values});
		}
		
		# attach decoder for complex datatypes, as example date, datetime, timestamp
		$class->attach_decoder ($col_meta);
		
		if (exists $col_meta->{X_IS_PK} and $col_meta->{X_IS_PK} == 1) {
			
			if ($pri_key) {
				warn "multiple pri keys: $fields->{$pri_key}->{column_name} and $field_name";
			} else {
				$pri_key = $field_name;
				$pri_key_column = $col_name;
			} 
			
			my $fetch_by_pk_sub = sub {
				my $package = shift;
				my $value   = shift;
				
				return $package->fetch ({$field_name => $value}, @_);
			};
			
			make_accessor ($class, "fetch_by_$field_name", default => $fetch_by_pk_sub);
			make_accessor ($class, "fetch_by_pk",          default => $fetch_by_pk_sub);
		}
		
		# access to the precise field value or column value without cool accessors
		
		make_accessor ($class, $field_name, default => sub {
			my $self = shift;
			
			unless (@_) {
				# bad style?
				return 
					$self->{field_values}->{$field_name} || (
					exists $self->columns->{$col_name}->{decoder}
						? $self->columns->{$col_name}->{decoder}->($self) # ($self->{column_values}->{$col_name});
						: $self->{column_values}->{$col_name});
			}

			die "too many parameters"  if @_ > 1;

			$self->assign_values ($field_name => $_[0]);
			
		});
		
		make_accessor ($class, "_fetched_${field_name}", default => sub {
			my $self = shift;
			
			unless (@_) {
				return $self->{column_values}->{$col_name};
			}

			die "too many parameters";
		});

		make_accessor ($class, "_raw_${field_name}", default => sub {
			my $self = shift;
			
			die "you must supply one parameter" unless @_ == 1;
			
			$self->{field_values}->{$field_name} = $_[0];
		});

	}
	
	make_accessor ($class, '_pk_', default => $pri_key);
	make_accessor ($class, '_pk_column_', default => $pri_key_column);

	return $class;
}

sub assign_values {
	my $self = shift;
	my $to_assign = {@_};
	
	foreach my $k (keys %$to_assign) {
		$self->{field_values}->{$k} = $to_assign->{$k};
	}
}

sub attach_decoder {
	my $class = shift;
	my $col_meta = shift;
	
	my $type = $col_meta->{type_name};
	
	if (defined $type and $H->is_rich_type ($type)) {
		
		$col_meta->{decoder} = sub {
			my $self = shift;
			my $value = $self->column_values->{$col_meta->{column_name}};
			return $H->value_from_type ($type, $value, $self);
		}
	}
}


sub _init_last {

}

sub _dbh_columns_info {
	my $class = shift;
	
	my $ts = timer ('inside columns info');

	my $dbh = $class->dbh;

	my $table_name = $class->table_name;
	
	$ts->lap ('make accessor');
	
	# preparations
	make_accessor (
		$class, 'table_quoted',
		default => $class->quote_identifier ($table_name)
	);
	
	my $real_row_count = 0;
	
	my $column_info = {};
	
	$ts->lap ('eval column info');
	
	eval {
	
		my $t = timer ('column info call');
		
		my $sth = $dbh->column_info(
			undef, undef, $table_name, '%'
		);
		
		$t->lap ('execute');
		
		$sth->execute
			unless $sth->{Executed};
		
		$t->lap ('fetchrow hashref');
		
		while (my $row = $sth->fetchrow_hashref) {
			$real_row_count ++;
			
			my $column_name = $row->{COLUMN_NAME};
			
			$column_info->{$column_name} = {
				(map {
					lc($_) => $row->{$_}
				} grep {
					exists $GREP_COLUMN_INFO{$_}
				} keys %$row),
				
				column_name        => $column_name,
				quoted_column_name => $dbh->quote_identifier ($column_name),
				nullable           => $row->{NULLABLE},
			};
			
			my $default_val = $row->{COLUMN_DEF};
			if (defined $default_val) {
				$default_val =~ s/^"(.*)"$/$1/;
				$column_info->{$column_name}->{default} = $default_val;
			}
			
		}
		
		$t->end;
		
		$t->total;
		
		if ($real_row_count == 0) {
			die "no rows for table '$table_name' fetched";
		}
	};
	
	$ts->lap ('_dbh_error');
	
	return
		if $class->_dbh_error ($@);
	
	$real_row_count = 0;
	
	$ts->lap ('primary_key_info');
	
	eval {
	
		my $t = timer ('primary key');
		
		# fuckin oracle
		my $schema = $class->vendor_schema;
		
		my $sth = $dbh->primary_key_info(
			undef, $schema, $table_name
		);
		
		$t->lap ('execute');
		
		if ($sth) {
			$sth->execute
				unless $sth->{Executed};
		
			$t->lap ('fetchrow');

			while (my $row = $sth->fetchrow_hashref) {
				$real_row_count ++;
				# here we translate rows
				my $pri_key_name = $row->{COLUMN_NAME};
			
				$column_info->{$row->{COLUMN_NAME}}->{X_IS_PK}  = 1;
				$column_info->{$row->{COLUMN_NAME}}->{nullable} = 0;
			
			}
		}
		
		$t->end;
		
		$t->total;
		
		if ($real_row_count == 0) {
			warn "no primary keys for table '$table_name'";
		}
	};
	
	return
		if $class->_dbh_error ($@);

	$ts->end;
	
	#Hash::Util::lock_hash_recurse (%$column_info);
	
	return $column_info;
}

sub _dbh_error {
	my $self  = shift;
	my $error = shift;
	my $statement = shift;
	
	return unless $error;
	
	my @caller = caller (1);
	my @caller2 = caller (2);
	
	if ($DBI::Easy::ERRHANDLER and ref $DBI::Easy::ERRHANDLER eq 'CODE') {
		&$DBI::Easy::ERRHANDLER ($self, $error, $statement);
	} else {
		warn ("[db error at $caller[3] ($caller[2]) called at $caller2[3] ($caller2[2])] ",
			$error
		);
	}
	
	if ($self->{in_transaction}) {
		eval {$self->rollback};
		die $error;
	}
	
	return 1;
}


# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# we always work with one table or view.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub _prefix_manipulations {
	my $self   = shift;
	my $dir    = shift;
	my $values = shift;
	my $in_place = shift || 0;
	
	my $entities;
	my $ent_key;
	my $convert;
	if ($dir eq 'fields2cols') {
		$entities = $self->fields;
		$ent_key = 'column_name';
		$convert = 'value_to_type';
		$values = $self->field_values
			unless $values;
	} elsif ($dir eq 'cols2fields') {
		$entities = $self->cols;
		$ent_key = 'field_name';
		$convert = 'value_from_type';
		$values = $self->column_values
			unless $values;
	} else {
		die "you can't call _prefix_manipulations without direction";
	}

	return $values if ! ref $values;
	
	my $place = $values;
	unless ($in_place) {
		$place = {};
	}
	
	foreach (keys %$values) {
		
		next unless exists $entities->{$_} or /^[_:-]\w+$/;
			#&& ($self->undef_as_null || defined $entities->{$_})

		if (/^:\w+$/) { # copy placeholders
			unless ($in_place) {
				$place->{$_} = $values->{$_};
			}
			next;
		}
		# next if $ent->{$ent_key} eq $_ and $in_place; # 
		my ($column_prefix, $k) = (/^(_?)(\w+)$/);
		$column_prefix = ''
			unless defined $column_prefix;
		
		# debug $k, $_;
		
		my $ent = $entities->{$k};
		my $value = $values->{$_};
		
		if ($in_place) {
			delete $values->{$_};
		}
		
		my $v = $value;
		
		# we must convert only convertible values
		# field => 'value'
		# _field => {'>', 'value'}
		if ($column_prefix eq '') {
			$v = $H->$convert (
				$ent->{type_name}, $value, $self
			);
		} elsif (
			$column_prefix eq '_' and ref $value and ref $value eq 'HASH'
			and keys %$value == 1
		) {
			my $condition = (keys %$value)[0];
			$v = $condition . $self->quote ($H->$convert (
				$ent->{type_name}, $value->{$condition}, $self
			));
		}
		
		next unless exists $ent->{$ent_key};
		
		# warn "$prefix/$ent_key => $ent->{$ent_key}";
		$place->{$column_prefix . $ent->{$ent_key}} = $v;
	}
	
	return $place
		unless $in_place;
	
}

sub fields_to_columns {
	my $self = shift;
	
	$self->_prefix_manipulations ('fields2cols', shift, 0);
}

sub columns_to_fields {
	my $self = shift;
	
	$self->_prefix_manipulations ('cols2fields', shift, 0);
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# we always work with one table or view.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# simplified sql execute
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-



1;

=head1 NAME

DBI::Easy - yet another perl ORM for SQL databases

=head1 DESCRIPTION

DBI::Easy is another ORM, aimed at making the life of the developer 
using it a lot easier.

=head1 INTRODUCTION 

The key notions of DBI::Easy are data records, collection of data records
and relations between them. A data record is a presentation of SQL result:
row or blessed hash, depending on how you look at it. Data records collection 
is a set of records limited by certain criteria or without any limitations.
the differentiation between collections and records has to do with
different relations between them: one-to-one, one-to-many, many-to-many.

For Example: Within a domain auction based on DBI::Easy, every user may 
have a few bids, but each bid belongs to just one concrete user.

It's also worth mentioning the relations between DBI::Easy and SQL. DBI::Easy
is currently using a small set of sql, limited to tables and views, 
including four operations to work with data: insert, update, select, delete. 
The relations between SQL objects are not formed automatically with the help 
of constraints.

Also it's important that DBI::Easy is not trying to hide SQL from you. 
If you need it you can use it fully. However, it allows carrying out the vast 
majority of simple operations with data without the participation of SQL.

=head1 SYNOPSIS

Let's start from the most simple things. To start the work you will need two 
modules that will return database handler ($dbh) upon request.

To avoid unpleasant consequences it's recommended to cache the returned 
connection only after the fork, if there is a fork in your code.
for the case when CL environment variables for DBI_DSN and DBI_* are defined,
and they can be used to establish a connection that doesn't need to be cached,
you can do without these modules at all. The main task for 'Entity' is to 
acquire DBI::Easy::Record[::Collection] or one of the child classes.

	package DBEntity;
	use strict;
	use DBI;
	use DBI::Easy::Record;
	use base qw(DBI::Easy::Record);
	sub dbh {		# optional. You don't have to write a procedure similar
					# to this one since DBI->connect is requested
					# when a ready $dbh hasn't been provided
		return DBI->connect;
	};
	1;

#-----------------------------------------

	package DBEntity::Collection;
	use strict;
	use DBI::Easy::Record::Collection;
	use base qw(DBI::Easy::Record::Collection);
	1;

Now let's get down to something concrete. Let's assume we have a user and his 
passport data (one-to-one relation) and some contact data (one-to-many) 
NOTE: the many-to-many relations hasn't been realized yet.


	package Entity::Passport;
	use strict;
	use DBEntity;
	use base qw(DBEntity);
	1;

#-----------------------------------------

	package Entity::Contact;
	use strict;
	use DBEntity;
	use base qw(DBEntity);
1;

#-----------------------------------------

	package Entity::Contact::Collection;
	use strict;
	use DBEntity::Collection;
	use base qw(DBEntity::Collection);
	1;

#-----------------------------------------

	package Entity::Account;
	use strict;
	use DBEntity;
	use base qw(DBEntity);
	use Entity::Passport;
	use Entity::Contact::Collection;

	sub _init_last {
		my $self = shift;
		$self->is_related_to (
			passport => 'Entity::Passport'
		);
		$self->is_related_to (
			contacts => 'Entity::Contact::Collection'
		);
	}
	1;

#-----------------------------------------

	package Entity::Account::Collection;
	use strict;
	use DBEntity::Collection;
	use base qw(DBEntity::Collection);
	1;

#-----------------------------------------

Now let's create some SQL tables for our test application (using SQLite):

	create table account (
		account_id serial not null primary key,
		account_login varchar (50) not null
	);
	create table pasport (
		passport_id serial not null primary key,
		passport_serial varchar (50) not null,
		account_id integer
	);
	create table contact (
		contact_id serial not null primary key,
		contact_proto varchar (10) not null,
		contact_address varchar (200) not null,
		account_id integer
	);

And now the funniest part: the script itself:

#-----------------------------------------

	#!/usr/bin/perl

	use strict;
	use Entity::Account;

	# here it doesn`t matter whether there is a user with such a login in
	# the database, if needed we can create it.

	my $account = Entity::Account->fetch_or_create ({login => 'apla'});

	# here fetch_or_create is implicitly activated with the parameters
	# {id => $account->id, serial => 'aabbcc'}

	$account->passport ({serial => 'aabbcc'});

	my $acc_contacts = $account->contacts;

	my $contact = $acc_contacts->new_record ({
		proto => 'email', address => 'apla@localhost'
	});
	$contact->save;
	$acc_contacts->count; 

	1;



=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBI-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

