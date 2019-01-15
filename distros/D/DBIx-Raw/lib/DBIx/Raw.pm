package DBIx::Raw;

use 5.008_005;
our $VERSION = '0.22';

use strictures 2;
use Moo;
use Types::Standard qw/Bool HashRef InstanceOf Str/;
use DBI;
use Config::Any;
use DBIx::Raw::Crypt;
use Carp;
use List::Util qw/first/;
use Crypt::Mode::CBC::Easy;

#have an errors file to write to
has 'dsn' => is => 'rw';
has 'user' => is => 'rw';
has 'password' => is => 'rw';
has 'conf' => is => 'rw';
has 'prev_conf' => (
    is => 'rw', 
    isa => Str, 
    default => '',
);

has 'crypt' => ( 
	is => 'ro', 
	isa => InstanceOf['Crypt::Mode::CBC::Easy'],
	lazy => 1,
	builder => sub { 
		my ($self) = @_;
		return Crypt::Mode::CBC::Easy->new(key => $self->crypt_key);
	},
);

has 'crypt_key' => (
    is => 'rw', 
    isa => Str, 
    lazy => 1,
    builder => sub {
        my $crypt_key_hex = 'aea77496999d37bf47aedff9c0d44fdf2d2bbfa848ee6652abe9891b43e0f331';
        return pack "H*", $crypt_key_hex;
    }, 
);

has 'use_old_crypt' => (
    is => 'rw',
    isa => Bool,
);

has 'old_crypt_key' => (
    is => 'rw', 
    isa => Str, 
    lazy => 1,
    default => '6883868834006296591264051568595813693328016796531185824375212916576042669669556288781800326542091901603033335703884439231366552922364658270813734165084102xfasdfa8823423sfasdfalkj!@#$$CCCFFF!09xxxxlai3847lol13234408!!@#$_+-083dxje380-=0'
);

has 'old_crypt' => ( 
	is => 'ro', 
	isa => InstanceOf['DBIx::Raw::Crypt'], 
	lazy => 1,
	builder => sub { 
		my ($self) = @_;
		return DBIx::Raw::Crypt->new( { secret => $self->old_crypt_key });
	},
);

# LAST STH USED
has 'sth' => is => 'rw';

#find out what DBH is specifically
has 'dbh' => ( 
	is => 'rw', 
	lazy => 1, 
	default => sub { shift->connect }
);

has 'keys' => (
	is => 'ro', 
	isa => HashRef[Str],
	default => sub { {
		query => 1,
		vals => 1,
		encrypt => 1,
		decrypt => 1,
		key => 1,
		href => 1,
		table => 1,
		where => 1,
		pk => 1,
		rows => 1,
        id => 1,
	} },
);

sub BUILD {
	my ($self) = @_;
	$self->_parse_conf;
	$self->_validate_connect_info;
}

=head1 NAME

DBIx::Raw - Maintain control of SQL queries while still having a layer of abstraction above DBI

=head1 SYNOPSIS

DBIx::Raw allows you to have complete control over your SQL, while still providing useful functionality so you don't have to deal directly with L<DBI>.

    use DBIx::Raw;
    my $db = DBIx::Raw->new(dsn => $dsn, user => $user, password => $password);

    #alternatively, use a conf file
    my $db = DBIx::Raw->new(conf => '/path/to/conf.pl');

    #get single values in scalar context
    my $name = $db->raw("SELECT name FROM people WHERE id=1");

    #get multiple values in list context
    my ($name, $age) = $db->raw("SELECT name, age FROM people WHERE id=1");
	
    #or
    my @person = $db->raw("SELECT name, age FROM people WHERE id=1");

    #get hash when using scalar context but requesting multiple values
    my $person = $db->raw("SELECT name, age FROM people where id=1");
    my $name = $person->{name};
    my $age = $person->{age};

    #also get hash in scalar context when selecting multiple values using '*'
    my $person = $db->raw("SELECT * FROM people where id=1");
    my $name = $person->{name};
    my $age = $person->{age};

    #insert a record
    $db->raw("INSERT INTO people (name, age) VALUES ('Sally', 26)");

    #insert a record with bind values to help prevent SQL injection
    $db->raw("INSERT INTO people (name, age) VALUES (?, ?)", 'Sally', 26);

    #update records
    my $num_rows_updated = $db->raw("UPDATE people SET name='Joe',age=34 WHERE id=1");

    #use bind values to help prevent SQL injection
    my $num_rows_updated = $db->raw("UPDATE people SET name=?,age=? WHERE id=?", 'Joe', 34, 1);

    #also use bind values when selecting
    my $name = $db->raw("SELECT name FROM people WHERE id=?", 1);

    #get multiple records as an array of hashes
    my $people = $db->aoh("SELECT name, age FROM people");
    
    for my $person (@$people) { 
        print "$person->{name} is $person->{age} years old\n";
    }

    #update a record easily with a hash
    my %update = ( 
        name => 'Joe',
        age => 34,
    );

    #record with id=1 now has name=Joe an age=34
    $db->update(href=>\%update, table => 'people', id=>1);

    #use alternate syntax to encrypt and decrypt data
    my $num_rows_updated = $db->raw(query => "UPDATE people SET name=? WHERE id=1", vals => ['Joe'], encrypt => [0]);

    my $decrypted_name = $db->raw(query => "SELECT name FROM people WHERE id=1", decrypt => [0]);

    #when being returned a hash, use names of field for decryption
    my $decrypted_person = $db->raw(query => "SELECT name, age FROM people WHERE id=1", decrypt => ['name']);
    my $decrypted_name = $decrypted_person->{name};


=head1 INITIALIZATION

There are three ways to intialize a L<DBIx::Raw> object:

=head2 dsn, user, password

You can initialize a L<DBIx::Raw> object by passing in the dsn, user, and password connection information.

    my $db = DBIx::Raw->new(dsn => 'dbi:mysql:test:localhost:3306', user => 'user', password => 'password');

=head2 dbh

You can also initialize a L<DBIx::Raw> object by passing in an existing database handle.

    my $db = DBIx::Raw->new(dbh => $dbh);

=head2 conf

If you're going to using the same connection information a lot, it's useful to store it in a configuration file and then
use that when creating a L<DBIx::Raw> object.

    my $db = DBIx::Raw->new(conf => '/path/to/conf.pl');

See L<CONFIGURATION FILE|DBIx::Raw/"CONFIGURATION FILE"> for more information on how to set up a configuration file.

=head1 CONFIGURATION FILE

You can use a configuration file to store settings for L<DBIx::Raw> instead of passing them into new or setting them.
L<DBIx::Raw> uses L<Config::Any>, so you can use any configuration format that is acceptable for L<Config::Any>. Variables
that you might want to store in your configuration file are C<dsn>, C<user>, C<password>, and L</crypt_key>.

Below is an example configuration file in perl format:

=head2 conf.pl

    { 
        dsn => 'dbi:mysql:test:localhost:3306',
        user => 'root', 
        password => 'password',
        crypt_key => 'lxsafadsfadskl23239210453453802xxx02-487900-=+1!:)',
    }

=head2 conf.yaml

    ---
    dsn: 'dbi:mysql:test:localhost:3306'
    user: 'root'
    password: 'password'
    crypt_key: 'lxsafadsfadskl23239210453453802xxx02-487900-=+1!:)'

Note that you do not need to include L</crypt_key> if you just if you just want to use the file for configuration settings.

=head1 SYNTAXES

DBIx::Raw provides two different possible syntaxes when making queries.

=head2 SIMPLE SYNTAX

Simple syntax is an easy way to write queries. It is always in the format:

    ("QUERY");

or

    ("QUERY", "VAL1", "VAL2", ...);

Below are some examples:

    my $num_rows_updated = $db->raw("UPDATE people SET name='Fred'");

    my $name = $db->raw("SELECT name FROM people WHERE id=1");
	
DBIx::Raw also supports L<DBI/"Placeholders and Bind Values"> for L<DBI>. These can be useful to help prevent SQL injection. Below are
some examples of how to use placeholders and bind values with L</"SIMPLE SYNTAX">.

    my $num_rows_updated = $db->raw("UPDATE people SET name=?", 'Fred');

    my $name = $db->raw("SELECT name FROM people WHERE id=?", 1);

    $db->raw("INSERT INTO people (name, age) VALUES (?, ?)", 'Frank', 44);
    
Note that L</"SIMPLE SYNTAX"> cannot be used for L</hoh>, L</hoaoh>, L</hash>, or L</update> because of the extra parameters that they require.

=head2 ADVANCED SYNTAX

Advanced syntax is used whenever a subroutine requires extra parameters besides just the query and bind values, or whenever you need to use L</encrypt>
or L</decrypt>. A simple example of the advanced syntax is:

    my $num_rows_updated = $db->raw(query => "UPDATE people SET name='Fred'");

This is equivalent to:

    my $num_rows_updated = $db->raw("UPDATE people SET name='Fred'");

A slightly more complex example adds in bind values:

    my $num_rows_updated = $db->raw(query => "UPDATE people SET name=?", vals => ['Fred']);

This is equivalent to the simple syntax:

    my $num_rows_updated = $db->raw("UPDATE people SET name=?", 'Fred');

Also, advanced syntax is required whenevery you want to L</encrypt> or L</decrypt> values.

    my $num_rows_updated = $db->raw(query => "UPDATE people SET name=?", vals => ['Fred'], encrypt => [0]);

    my $decrypted_name = $db->raw(query => "SELECT name FROM people WHERE id=1", decrypt => [0]);

Note that L</"ADVANCED SYNTAX"> is required for L</hoh>, L</hoaoh>, L</hash>, or L</update> because of the extra parameters that they require.

=head1 ENCRYPT AND DECRYPT

You can use L<DBIx::Raw> to encrypt values when putting them into the database and decrypt values when removing them from the database.
Note that in order to store an encrypted value in the database, you should have the field be of type C<VARCHAR(255)> or some type of character
or text field where the encryption will fit. In order to encrypt and decrypt your values, L<DBIx::Raw> requires a L</crypt_key>. It contains a default
key, but it is recommended that you change it either by having a different one in your L</conf> file, or passing it in on creation with C<new> or setting it using the
L</crypt_key> method. It is recommended that you use a module like L<Crypt::Random> to generate a secure key. 
One thing to note is that both L</encrypt> and L</decrypt> require L</"ADVANCED SYNTAX">.

=head2 encrypt

In order to encrypt values, the values that you want to encrypt must be in the bind values array reference that you pass into C<vals>. Note that for the values that you want to
encrypt, you should put their index into the encrypt array that you pass in. For example:

    my $num_rows_updated = $db->raw(query => "UPDATE people SET name=?,age=?,height=? WHERE id=1", vals => ['Zoe', 24, "5'11"], encrypt => [0, 2]);

In the above example, only C<name> and C<height> will be encrypted. You can easily encrypt all values by using '*', like so:

    my $num_rows_updated = $db->raw(query => "UPDATE people SET name=?,height=? WHERE id=1", vals => ['Zoe', "5'11"], encrypt => '*');

And this will encrypt both C<name> and C<height>.

The only exception to the L</encrypt> syntax that is a little different is for L</update>. See L</"update encrypt"> for how to encrypt when using L</update>.

=head2 decrypt

When decrypting values, there are two possible different syntaxes.

=head3 DECRYPT LIST CONTEXT 

If your query is returning a single value or values in a list context, then the array reference that you pass in for decrypt will contain the indices for the
order that the columns were listed in. For instance:

    my $name = $db->raw(query => "SELECT name FROM people WHERE id=1", decrypt => [0]);

    my ($name, $age) = $db->raw(query => "SELECT name, age FROM people WHERE id=1", decrypt => [0,1]);

=head3 DECRYPT HASH CONTEXT 

When your query has L<DBIx::Raw> return your values in a hash context, then the columns that you want decrypted must be listed by name in the array reference:

    my $person = $db->raw(query => "SELECT name, age FROM people WHERE id=1", decrypt => ['name', 'age'])

    my $aoh = $db->aoh(query => "SELECT name, age FROM people", decrypt => ['name', 'age']);

Note that for either L</"LIST CONTEXT"> or L</"HASH CONTEXT">, it is possible to use '*' to decrypt all columns:

    my ($name, $height) = $db->raw(query => "SELECT name, height FROM people WHERE id=1", decrypt => '*');

=head2 crypt_key

L<DBIx::Raw> uses L</"crypt_key"> to encrypt and decrypt all values. You can set the crypt key when you create your
L<DBIx::Raw> object by passing it into L</new>, providing it to L<CONFIGURATION FILE|DBIx::Raw/"CONFIGURATION FILE">,
or by setting it with its setter method:

    $db->crypt_key("1234");

It is strongly recommended that you do not use the default L</"crypt_key">. The L</crypt_key> should be the appropriate length
for the L</crypt> that is set. The default L</crypt> uses L<Crypt::Mode::CBC::Easy>, which uses L<Crypt::Cipher::Twofish>, which
allows key sizes of 128/192/256 bits.

=head2 crypt

The L<Crypt::Mode::CBC::Easy> object to use for encryption. Default is the default L<Crypt::Mode::CBC::Easy> object
created with the key L</crypt_key>.

=head2 use_old_crypt

In version 0.16 L<DBIx::Raw> started using L<Crypt::Mode::CBC::Easy> instead of L<DBIx::Raw::Crypt>. Setting this to 1 uses the old encryption instead.
Make sure to set L</old_crypt_key> if you previously used L</crypt_key> for encryption.

=head2 old_crypt_key

This sets the crypt key to use if L</use_old_crypt> is set to true. Default is the previous crypt key.

=head1 SUBROUTINES/METHODS

=head2 raw

L</raw> is a very versitile subroutine, and it can be called in three contexts. L</raw> should only be used to make a query that
returns values for one record, or a query that returns no results (such as an INSERT query). If you need to have multiple
results returned, see one of the subroutines below.

=head3 SCALAR CONTEXT

L</raw> can be called in a scalar context to only return one value, or in a undef context to return no value. Below are some examples.

    #select
    my $name = $db->raw("SELECT name FROM people WHERE id=1");

    #update with number of rows updated returned
    my $num_rows_updated = $db->raw("UPDATE people SET name=? WHERE id=1", 'Frank');
 
    #update in undef context, nothing returned.
    $db->raw("UPDATE people SET name=? WHERE id=1", 'Frank');

    #insert
    $db->raw("INSERT INTO people (name, age) VALUES ('Jenny', 34)");

Note that to L</decrypt> for L</"SCALAR CONTEXT"> for L</raw>, you would use L</"DECRYPT LIST CONTEXT">.

=head3 LIST CONTEXT

L</raw> can also be called in a list context to return multiple columns for one row.

    my ($name, $age) = $db->raw("SELECT name, age FROM people WHERE id=1");

    #or
    my @person = $db->raw("SELECT name, age FROM people WHERE id=1");

Note that to L</decrypt> for L</"LIST CONTEXT"> for L</raw>, you would use L</"DECRYPT LIST CONTEXT">.

=head3 HASH CONTEXT

L</raw> will return a hash if you are selecting more than one column for a single record.

    my $person = $db->raw("SELECT name, age FROM people WHERE id=1");
    my $name = $person->{name};
    my $age = $person->{age};

Note that L</raw>'s L</"HASH CONTEXT"> works when using * in your query.

    my $person = $db->raw("SELECT * FROM people WHERE id=1");
    my $name = $person->{name};
    my $age = $person->{age};

Note that to L</decrypt> for L</"HASH CONTEXT"> for L</raw>, you would use L</"DECRYPT HASH CONTEXT">.
=cut

sub raw {
	my $self = shift;

	my $params = $self->_params(@_);

	my (@return_values, $return_type);
	$self->sth($self->dbh->prepare($params->{query})) or $self->_perish($params);

	#if user asked for values to be encrypted
	if($params->{encrypt}) {
		$self->_crypt_encrypt($params);
	}

	$self->_query($params);

	if(not defined wantarray) { 
		$self->sth->finish or $self->_perish($params);
		return;
	}
	elsif(wantarray) { 
		$return_type = 'array';	
	}
	else { 
		$return_type = 'scalar';	

		if($params->{query} =~ /SELECT\s+(.*?)\s+FROM/i) { 
			my $match = $1;
			my $num_commas=()= $match =~ /,/g;
			my $num_stars=()= $match =~ /\*/g;

			if($num_commas > 0 or $num_stars > 0) { $return_type = 'hash' }
		}
	}

	if($params->{query} =~ /^(\n*?| *?|\r*?)UPDATE /si) {
  		my $return_value = $self->sth->rows();
		push @return_values, $return_value;
	}
    elsif(($params->{query} =~ /SELECT /sig) || ($params->{query} =~ /SHOW /sig)) {
  		unless($params->{query} =~ /INSERT INTO (.*?)SELECT /sig) {
  			if($return_type eq 'hash') {
				return unless $params->{href} = $self->sth->fetchrow_hashref; #handles undef case

				if($params->{decrypt}) {
					$self->_crypt_decrypt($params);
				}

  				push @return_values, $params->{href};
			}
			else {
				return unless @return_values = $self->sth->fetchrow_array(); #handles undef cases

				if($params->{decrypt}) {
					$params->{return_values} = \@return_values;
					$self->_crypt_decrypt($params);
				}
			}
		} 
	}

	$self->sth->finish or $self->_perish($params);

	unless($return_type eq 'array') {
  		return $return_values[0];
	}
	else {
  		return @return_values;
	}
}

=head2 aoh (array_of_hashes)

L</aoh> can be used to select multiple rows from the database. It returns an array reference of hashes, where each row is a hash in the array.

    my $people = $db->aoh("SELECT * FROM people");

    for my $person (@$people) { 
        print "$person->{name} is $person->{age} years old\n";
    }

Note that to L</decrypt> for L</aoh>, you would use L</"DECRYPT HASH CONTEXT">.
=cut

sub aoh {
	my $self = shift;
	my $params = $self->_params(@_);
	my ($href,@a);

	$self->_query($params);

	if($params->{decrypt}) {
		while($href=$self->sth->fetchrow_hashref){
			$params->{href} = $href;
			$self->_crypt_decrypt($params);
  			push @a, $href;
		}
	}
	else { 
		while($href=$self->sth->fetchrow_hashref){
  			push @a, $href;
		}
	}

	return \@a;
}

=head2 aoa (array_of_arrays)

L</aoa> can be used to select multiple rows from the database. It returns an array reference of array references, where each row is an array within the array.

    my $people = $db->aoa("SELECT name,age FROM people");

    for my $person (@$people) { 
        my $name = $person->[0];
        my $age = $person->[1];
        print "$name is $age years old\n";
    }

Note that to L</decrypt> for L</aoa>, you would use L</"DECRYPT LIST CONTEXT">.
=cut

sub aoa {
	my $self = shift;
	my $params = $self->_params(@_);
	my (@return_values);

	$self->_query($params);

	if($params->{decrypt}) {
		while(my @a=$self->sth->fetchrow_array){
			$params->{return_values} = \@a;
			$self->_crypt_decrypt($params);
  			push @return_values, \@a;
		}
	}
	else { 
		while(my @a=$self->sth->fetchrow_array){
  			push @return_values, \@a;
		}
	}

	return \@return_values;
}



=head2 hoh (hash_of_hashes)

=over

=item 

B<query (required)> - the query

=item 

B<key (required)> - the name of the column that will serve as the key to access each row

=item 

B<href (optional)> - the hash reference that you would like to have the results added to

=back

L</hoh> can be used when you want to be able to access an individual row behind a unique key, where each row is represented as a hash. For instance,
this subroutine can be useful if you would like to be able to access rows by their id in the database. L</hoh> returns a hash reference of hash references.

    my $people = $db->hoh(query => "SELECT id, name, age FROM people", key => "id");

    for my $key(keys %$people) { 
        my $person = $people->{$key};
        print "$person->{name} is $person->{age} years old\n";
    }

    #or
    while(my ($key, $person) = each %$people) { 
        print "$person->{name} is $person->{age} years old\n";
    }

So if you wanted to access the person with an id of 1, you could do so like this:

    my $person1 = $people->{1};
    my $person1_name = $person1->{name};
    my $person1_age = $person1->{age};

Also, with L</hoh> it is possible to add to a previous hash of hashes that you alread have by passing it in with the C<href> key:

    #$people was previously retrieved, and results will now be added to $people
    $db->hoh(query => "SELECT id, name, age FROM people", key => "id", href => $people);

Note that you must select whatever column you want to be the key. So if you want to use "id" as the key, then you must select id in your query.
Also, keys must be unique or the records will overwrite one another. To retrieve multiple records and access them by the same key, see L<"hoaoh (hash_of_array_of_hashes)"/hoaoh>.
To L</decrypt> for L</hoh>, you would use L</"DECRYPT HASH CONTEXT">.

=cut

sub hoh {
	my $self = shift;
	my $params = $self->_params(@_);
	my ($href);

	my $hoh = $params->{href}; #if hashref is passed in, it will just add to it

	$self->_query($params);

	if($params->{decrypt}) {
		while($href=$self->sth->fetchrow_hashref){
			$params->{href} = $href;
			$self->_crypt_decrypt($params);
			$hoh->{$href->{$params->{key}}} = $href;
		}
	}
	else { 
		while($href=$self->sth->fetchrow_hashref){
			$hoh->{$href->{$params->{key}}} = $href;
		}
	}

	return $hoh;
} 

=head2 hoa (hash_of_arrays)

=over

=item 

B<query (required)> - the query

=item 

B<key (required)> - the name of the column that will serve as the key to store the values behind

=item 

B<val (required)> - the name of the column whose values you want to be stored behind key

=item 

B<href (optional)> - the hash reference that you would like to have the results added to

=back

L</hoa> is useful when you want to store a list of values for one column behind a key. For instance,
say that you wanted the id's of all people who have the same name grouped together. You could perform that query like so:

    my $hoa = $db->hoa(query => "SELECT id, name FROM people", key => "name", val => "id");

    for my $name (%$hoa) { 
        my $ids = $hoa->{$name};

        print "$name has ids ";
        for my $id (@$ids) { 
            print " $id,";
        }

        print "\n";
    }

Note that you must select whatever column you want to be the key. So if you want to use "name" as the key, then you must select name in your query.
To L</decrypt> for L</hoa>, you would use L</"DECRYPT LIST CONTEXT">.

=cut

sub hoa {
	my $self = shift;
	my $params = $self->_params(@_);
	my ($href);

	croak "query, key, and val are required for hoa" unless $params->{query} and $params->{key} and $params->{val};

	my $hash = $params->{href}; #if hash is passed in, it will just add to it

	$self->_query($params);

	if($params->{decrypt}) {
		while($href=$self->sth->fetchrow_hashref){
			$params->{href} = $href;
			$self->_crypt_decrypt($params);
			push @{$hash->{$href->{$params->{key}}}}, $href->{$params->{val}};
		}
	}
	else { 
		while($href=$self->sth->fetchrow_hashref){
			push @{$hash->{$href->{$params->{key}}}}, $href->{$params->{val}};
		}
	}

	return $hash;
}

=head2 hoaoh (hash_of_array_of_hashes)

=over

=item 

B<query (required)> - the query

=item 

B<key (required)> - the name of the column that will serve as the key to store the array of hashes behind

=item 

B<href (optional)> - the hash reference that you would like to have the results added to

=back

L</hoaoh> can be used when you want to store multiple rows behind a key that they all have in common. For
example, say that we wanted to have access to all rows for people that have the same name. That could be
done like so:

    my $hoaoh = $db->hoaoh(query => "SELECT id, name, age FROM people", key => "name");

    for my $name (keys %$hoaoh) { 
        my $people = $hoaoh->{$name};

        print "People named $name: ";
        for my $person (@$people) { 
            print "  $person->{name} is $person->{age} years old\n";
        }

        print "\n";
    }

So to get the array of rows for all people named Fred, we could simply do:

    my @freds = $hoaoh->{Fred};

    for my $fred (@freds) { ... }

Note that you must select whatever column you want to be the key. So if you want to use "name" as the key, then you must select name in your query.
To L</decrypt> for L</hoaoh>, you would use L</"DECRYPT HASH CONTEXT">.

=cut

sub hoaoh {
	my $self = shift;
	my $params = $self->_params(@_);
	my ($href);

	croak "query and key are required for hoaoh" unless $params->{query} and $params->{key};

	my $hoa = $params->{href}; #if hashref is passed it, it will just add to it

	$self->_query($params);

	if($params->{decrypt}) {
		while($href=$self->sth->fetchrow_hashref){
			$params->{href} = $href;
			$self->_crypt_decrypt($params);
			push @{$hoa->{$href->{$params->{key}}}},$href;
		}
	}
	else { 
		while($href=$self->sth->fetchrow_hashref){
			push @{$hoa->{$href->{$params->{key}}}},$href;
		}
	}

	return $hoa;
}

=head2 array

L</array> can be used for selecting one value from multiple rows. Say for instance that we wanted all the ids for anyone named Susie.
We could do that like so:

    my $ids = $db->array("SELECT id FROM people WHERE name='Susie'");

    print "Susie ids: \n";
    for my $id (@$ids) { 
        print "$id\n";
    }

To L</decrypt> for L</array>, you would use L</"DECRYPT LIST CONTEXT">.

=cut

sub array {
	my $self = shift;
	my $params = $self->_params(@_);
	my ($r,@a);

	# Get the Array of results:
	$self->_query($params);
	if($params->{decrypt}) { 
		while(($r) = $self->sth->fetchrow_array()){
	  		$r = $self->_decrypt($r);
			push @a, $r;
		}
	} 	
	else {
		while(($r) = $self->sth->fetchrow_array()){
			push @a, $r;
		}
	}

	return \@a;
}

=head2 hash

=over

=item 

B<query (required)> - the query

=item 

B<key (required)> - the name of the column that will serve as the key 

=item 

B<val (required)> - the name of the column that will be stored behind the key

=item 

B<href (optional)> - the hash reference that you would like to have the results added to

=back

L</hash> can be used if you want to map one key to one value for multiple rows. For instance, let's say
we wanted to map each person's id to their name:

    my $ids_to_names = $db->hash(query => "SELECT id, name FROM people", key => "id", val => "name");

    my $name_1 = $ids_to_names->{1};

    print "$name_1\n"; #prints 'Fred'


To have L</hash> add to an existing hash, just pass in the existing hash with C<href>:


    $db->hash(query => "SELECT id, name FROM people", key => "id", val => "name", href => $ids_to_names);

To L</decrypt> for L</hash>, you would use L</"DECRYPT HASH CONTEXT">.

=cut

sub hash {
	my $self = shift;
	my $params = $self->_params(@_);
	my ($href);

	croak "query, key, and val are required for hash" unless $params->{query} and $params->{key} and $params->{val};

	my $hash = $params->{href}; #if hash is passed in, it will just add to it

	$self->_query($params);

	if($params->{decrypt}) {
		while($href=$self->sth->fetchrow_hashref){
			$params->{href} = $href;
			$self->_crypt_decrypt($params);
			$hash->{$href->{$params->{key}}} = $href->{$params->{val}};
		}
	}
	else { 
		while($href=$self->sth->fetchrow_hashref){
			$hash->{$href->{$params->{key}}} = $href->{$params->{val}};
		}
	}

	return $hash;
}

=head2 insert

=over

=item 

B<href (required)> - the hash reference that will be used to insert the row, with the columns as the keys and the new values as the values

=item 

B<table (required)> - the name of the table that the row will be inserted into

=back

L</insert> can be used to insert a single row with a hash. This can be useful if you already have the values you need
to insert the row with in a hash, where the keys are the column names and the values are the new values. This function
might be useful for submitting forms easily.

    my %person_to_insert = ( 
        name => 'Billy',
        age => '32',
        favorite_color => 'blue',
    );

    $db->insert(href => \%person_to_insert, table => 'people');

If you need to have literal SQL into your insert query, then you just need to pass in a scalar reference. For example:

    "INSERT INTO people (name, update_time) VALUES('Billy', NOW())"

If we had this:

    my %person_to_insert = (
        name => 'Billy',
        update_time => 'NOW()',
    );

    $db->insert(href => \%person_to_insert, table => 'people');

This would effectively evaluate to:

    $db->raw(query => "INSERT INTO people (name, update_time) VALUES(?, ?)", vals => ['Billy', 'NOW()']);

However, this will not work. Instead, we need to do:

    my %person_to_insert = (
        name => 'Billy',
        update_time => \'NOW()',
    );

    $db->insert(href => \%person_to_insert, table => 'people');

Which evaluates to:

    $db->raw(query => "INSERT INTO people (name, update_time) VALUES(?, NOW())", vals => ['Billy']);

And this is what we want.

=head3 insert encrypt

When encrypting for insert, because a hash is passed in you need to have the encrypt array reference contain the names of the columns that you want to encrypt 
instead of the indices for the order in which the columns are listed:

    my %person_to_insert = ( 
        name => 'Billy',
        age => '32',
        favorite_color => 'blue',
    );

    $db->insert(href => \%person_to_insert, table => 'people', encrypt => ['name', 'favorite_color']);

Note we do not ecnrypt age because it is most likely stored as an integer in the database.

=cut

# TODO: write insert tests
sub insert {
	my $self = shift;
	my $params = $self->_params(@_);

	croak "href and table are required for insert" unless $params->{href} and $params->{table};

	my @vals;
	my $column_names = '';
	my $values_string = '';
    my @encrypt;
	while(my ($key,$val) = each %{$params->{href}}) { 
		my $append = '?';
		if (ref $val eq 'SCALAR') {
			$append = $$val;
		}
		else { 
            if ($params->{encrypt} and first { $_ eq $key } @{$params->{encrypt}}) {
                push @encrypt, scalar(@vals);
            }

			push @vals, $val;
		}

        $column_names .= "$key,";
        $values_string .= "$append,";
	}
	
	$column_names = substr $column_names, 0, -1;
	$values_string = substr $values_string, 0, -1;

	$params->{query} = "INSERT INTO $params->{table} ($column_names) VALUES($values_string)";
	$params->{vals} = \@vals;

    if ($params->{encrypt} and @encrypt) {
        $params->{encrypt} = \@encrypt;
	    $self->_crypt_encrypt($params);
    }

	$self->_query($params);
} 

=head2 update

=over

=item 

B<href (required)> - the hash reference that will be used to update the row, with the columns as the keys and the new values as the values

=item 

B<table (required)> - the name of the table that the updated row is in

=item 

B<id (optional)> - specifies the id of the item that we are updating (note, column must be called "id"). Should not be used if C<pk> is used

=item 

B<pk (optional)> - A hash reference of the form C<{name =E<gt> 'column_name', val =E<gt> 'unique_val'}>. Can be used instead of C<id>. Should not be used if C<id> is used

=item 

B<where (optional)> - A where clause to help decide what row to update. Any bind values can be passed in with C<vals>

=back

L</update> can be used to update a single row with a hash, and returns the number of rows updated. This can be useful if you already have the values you need
to update the row with in a hash, where the keys are the column names and the values are the new values. This function
might be useful for submitting forms easily.

    my %updated_person = ( 
        name => 'Billy',
        age => '32',
        favorite_color => 'blue',
    );

    my $num_rows_updated = $db->update(href => \%updated_person, table => 'people', id => 1);

    # or in list context
    my ($num_rows_updated) = $db->update(href => \%updated_person, table => 'people', id => 1);

Note that above for "id", the column must actually be named id for it to work. If you have a primary key or unique
identifying column that is named something different than id, then you can use the C<pk> parameter:

    my $num_rows_updated = $db->update(href => \%updated_person, table => 'people', pk => {name => 'person_id', val => 1});

If you need to specify more constraints for the row that you are updating instead of just the id, you can pass in a where clause:

    my $num_rows_updated = $db->update(href => \%updated_person, table => 'people', where => 'name=? AND favorite_color=? AND age=?', vals => ['Joe', 'green', 61]);
    
Note that any bind values used in a where clause can just be passed into the C<vals> as usual. It is possible to use a where clause and an id or pk together:

    my $num_rows_updated = $db->update(href => \%updated_person, table => 'people', where => 'name=? AND favorite_color=? AND age=?', vals => ['Joe', 'green', 61], id => 1);

Alternatively, you could just put the C<id> or C<pk> in your where clause.

If you need to have literal SQL into your update query, then you just need to pass in a scalar reference. For example:

    "UPDATE people SET name='Billy', update_time=NOW() WHERE id=1"

If we had this:

    my %updated_person = (
        name => 'Billy',
        update_time => 'NOW()',
    );

    my $num_rows_updated = $db->update(href => \%updated_person, table => 'people', id => 1);

This would effectively evaluate to:

    my $num_rows_updated = $db->raw(query => "UPDATE people SET name=?, update_time=? WHERE id=?", vals => ['Billy', 'NOW()', 1]);

However, this will not work. Instead, we need to do:

    my %updated_person = (
        name => 'Billy',
        update_time => \'NOW()',
    );

    my $num_rows_updated = $db->update(href => \%updated_person, table => 'people', id => 1);

Which evaluates to:

    my $num_rows_updated = $db->raw(query => "UPDATE people SET name=?, update_time=NOW() WHERE id=?", vals => ['Billy', 1]);

And this is what we want.

=head3 update encrypt

When encrypting for update, because a hash is passed in you need to have the encrypt array reference contain the names of the columns that you want to encrypt 
instead of the indices for the order in which the columns are listed:

    my %updated_person = ( 
        name => 'Billy',
        age => '32',
        favorite_color => 'blue',
    );

    my $num_rows_updated = $db->update(href => \%updated_person, table => 'people', id => 1, encrypt => ['name', 'favorite_color']);

Note we do not ecnrypt age because it is most likely stored as an integer in the database.

=cut

sub update {
	my $self = shift;
	my $params = $self->_params(@_);

	croak "href and table are required for update" unless $params->{href} and $params->{table};

	my @vals;
	my $string = '';
    my @encrypt;
	while(my ($key,$val) = each %{$params->{href}}) { 
		my $append = '?';
		if (ref $val eq 'SCALAR') {
			$append = $$val;
		}
		else { 
            # TODO: write update encrypt tests
            if ((defined $params->{encrypt} and $params->{encrypt} eq '*') 
                    or ($params->{encrypt} and first { $_ eq $key } @{$params->{encrypt}})) {
                push @encrypt, scalar(@vals);
            }

			push @vals, $val;
		}

		$string .= "$key=$append,";
	}
	
	$string = substr $string, 0, -1;

	$params->{vals} = [] unless $params->{vals};
	my $where = '';
	if($params->{where}) { 
		$where = " WHERE $params->{where}";	
		push @vals, @{$params->{vals}};
	}

	if($params->{id}) { 
		if($where eq '') { 
			$where = " WHERE id=? ";	
		}	
		else { 
			$where .= " AND id=? ";
		}

		push @vals, $params->{id};
	}
	elsif($params->{pk}) { 
		my $name = $params->{pk}->{name};
		my $val = $params->{pk}->{val};
		if($where eq '') { 
			$where = " WHERE $name=? ";	
		}	
		else { 
			$where .= " AND $name=? ";
		}

		push @vals, $val;
	}

	$params->{query} = "UPDATE $params->{table} SET $string $where";
	$params->{vals} = \@vals;

    if ($params->{encrypt} and @encrypt) {
        $params->{encrypt} = \@encrypt;
	    $self->_crypt_encrypt($params);
    }

	$self->_query($params);

    return unless defined wantarray;
    return wantarray ? ($self->sth->rows()) : $self->sth->rows();
} 

=head2 insert_multiple

=over

=item 

B<rows (required)> - the array reference of array references, where each inner array reference holds the values to be inserted for one row

=item 

B<table (required)> - the name of the table that the rows are to be inserted into

=item 

B<columns (required)> - The names of the columns that values are being inserted for

=back

L</insert_multiple> can be used to insert multiple rows with one query. For instance:

    my $rows = [
        [
            1,
            'Joe',
            23,
        ],
        [
            2,
            'Ralph,
            50,
        ],
    ];

    $db->insert_multiple(table => 'people', columns => [qw/id name age/], rows => $rows);

This can be translated into the SQL query:

    INSERT INTO people (id, name, age) VALUES (1, 'Joe', 23), (2, 'Ralph', 50);

Note that L</insert_multiple> does not yet support encrypt. I'm planning to add this feature later. If you need it now, please shoot me an email and I will
try to speed things up!

=cut

sub insert_multiple {
	my $self = shift;
	my $params = $self->_params(@_);

	while(my ($key, $val) = each %$params) { 
		print "$key=$val\n";
	}

	croak "columns, table, and rows are required for insert_multiple" unless $params->{columns} and $params->{table} and $params->{rows};

	my $values_string = '';
	my @vals;

	my $columns = join ',', @{$params->{columns}};
	my $row_string = '?,' x @{$params->{columns}};
	$row_string = substr $row_string, 0, -1;

	for my $row (@{$params->{rows}}) { 
		push @vals, @$row;
		$values_string .= "($row_string),";		
	}

	$values_string = substr $values_string, 0, -1;

	$params->{query} = "INSERT INTO $params->{table} ($columns) VALUES $values_string";
	print $params->{query} . "\n";
	$params->{vals} = \@vals;

	$self->_query($params);
} 

=head2 sth

L</sth> returns the statement handle from the previous query.

    my $sth = $db->sth;

This can be useful if you need a statement handle to perform a function, like to get
the id of the last inserted row.

=cut

=head2 dbh

L</dbh> returns the database handle that L<DBIx::Raw> is using.

    my $dbh = $db->dbh;

L</dbh> can also be used to set a new database handle for L<DBIx::Raw> to use.

    $db->dbh($new_dbh);

=cut

=head2 dsn

L</dsn> returns the dsn that was provided.

    my $dsn = $db->dsn;

L</dsn> can also be used to set a new C<dsn>.

    $db->dsn($new_dsn);

When setting a new C<dsn>, it's likely you'll want to use L</connect>.

=cut

=head2 user

L</user> returns the user that was provided.

    my $user = $db->user;

L</user> can also be used to set a new C<user>.

    $db->user($new_user);

When setting a new C<user>, it's likely you'll want to use L</connect>.

=cut

=head2 password

L</password> returns the password that was provided.

    my $password = $db->password;

L</password> can also be used to set a new C<password>.

    $db->password($new_password);

When setting a new C<password>, it's likely you'll want to use L</connect>.

=cut

=head2 conf

L</conf> returns the conf file that was provided.

    my $conf = $db->conf;

L</conf> can also be used to set a new C<conf> file.

    $db->conf($new_conf);

When setting a new C<conf>, it's likely you'll want to use L</connect>.

=cut

=head2 connect

L</connect> can be used to keep the same L<DBIx::Raw> object, but get a new L</dbh>. You can call connect to get a new dbh with the same settings that you have provided:

    #now there is a new dbh with the same DBIx::Raw object using the same settings
    $db->connect;

Or you can change the connect info. 
For example, if you update C<dsn>, C<user>, C<password>:

    $db->dsn('new_dsn');
    $db->user('user');
    $db->password('password');

    #get new dbh but keep same DBIx::Raw object
    $db->connect;

Or if you update the conf file:

    $db->conf('/path/to/new_conf.pl');
    
    #get new dbh but keep same DBIx::Raw object
    $db->connect;

=cut

sub connect { 
	my ($self) = @_;

	$self->_parse_conf;
	$self->_validate_connect_info;
	return $self->dbh(DBI->connect($self->dsn, $self->user, $self->password) or croak($DBI::errstr));
}

sub _params { 
	my $self = shift;

	my %params;
	unless($self->keys->{$_[0]}) {
		$params{query} = shift;
		$params{vals} = [@_];
	}
	else { 
		%params = @_;
	}

	return \%params;
}

sub _query {
	my ($self, $params) = (@_);

	$self->sth($self->dbh->prepare($params->{query})) or $self->_perish($params);

	if($params->{'vals'}){
  		$self->sth->execute(@{$params->{'vals'}}) or $self->_perish($params);
	}
	else {
  		$self->sth->execute() or $self->_perish($params);
	}
}

sub _perish { 
	my ($self, $params) = @_;
	croak "ERROR: Can't prepare query.\n\n$DBI::errstr\n\nquery='" . $params->{query} . "'\n";
}

sub _crypt_decrypt { 
	my ($self, $params) = @_;
	my @keys;
	if($params->{decrypt} eq '*') { 
		if($params->{href}) { 
			@keys = keys %{$params->{href}};
		}
		else { 
			@keys = 0..$#{$params->{return_values}};
		}
	}
	else { 
		@keys = @{$params->{decrypt}};
	}

	if($params->{href}) {
		for my $key (@keys) {
			$params->{href}->{$key} = $self->_decrypt($params->{href}->{$key}) if $params->{href}->{$key};
		} 	
	}
	else { 
		for my $index (@keys) {
			$params->{return_values}->[$index] = $self->_decrypt( $params->{return_values}->[$index] ) if $params->{return_values}->[$index];
		}
	}
}

sub _crypt_encrypt { 
	my ($self, $params) = @_;
	my @indices; 

	if($params->{encrypt} eq '*') { 
		my $num_question_marks = 0;
		#don't want to encrypt where conditions! Might be buggy...should look into this more
		if($params->{query} =~ /WHERE\s+(.*)/i) { 
			$num_question_marks =()= $1 =~ /=\s*?\?/g;
		}

		@indices = 0..($#{$params->{vals}} - $num_question_marks);
	}
	else { 
		@indices = @{$params->{encrypt}};
	}

	for my $index (@indices) {
   		@{$params->{vals}}[$index] = $self->_encrypt( @{$params->{vals}}[$index] );
	}
}

sub _encrypt { 
	my ($self, $text) = @_;

    if ($self->use_old_crypt) {
        return $self->old_crypt->encrypt($text);
    }

    return $self->crypt->encrypt($text); 
}

sub _decrypt { 
	my ($self, $text) = @_;
    
    if ($self->use_old_crypt) {
        return $self->old_crypt->decrypt($text);
    }

	return $self->crypt->decrypt($text); 
}

sub _parse_conf { 
	my ($self) = @_;

	#load in configuration if it exists
	if($self->conf) { 

		#no need to read in settings again if conf hasn't changed, unless dsn, user, or password is unset
		return if $self->conf eq $self->prev_conf and $self->dsn and $self->user and $self->password;

		my $config = Config::Any->load_files({files =>[$self->conf],use_ext => 1  }); 

		for my $c (@$config){
  			for my $file (keys %$c){
     			for my $attribute (keys %{$c->{$file}}){
					if($self->can($attribute)) { 
						$self->$attribute($c->{$file}->{$attribute});
					}
   				}
  			}
		}

		$self->prev_conf($self->conf);
	}
}

sub _validate_connect_info { 
	my ($self) = @_;
	croak "Need to specify 'dsn', 'user', and 'password' either when you create the object or by passing in a configuration file in 'conf'! Or, pass in an existing dbh" 
		unless (defined $self->dsn and defined $self->user and defined $self->password) or defined $self->dbh;
}

=head1 AUTHOR

Adam Hopkins, C<< <srchulo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-raw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Raw>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Raw


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Raw>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Raw>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Raw>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Raw/>

=back


=head1 ACKNOWLEDGEMENTS

Special thanks to Jay Davis who wrote a lot of the original code that this module is based on.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
