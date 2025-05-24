package Crop::Object::Warehouse::Agent::DBI;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Warehouse::Agent::DBI
	DBI interface to a database.
=cut

use v5.14;
use warnings;

use DBI;

use Crop::Debug;
use Crop::Error;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	dbh   - connection handler
	host  - db hostname
	login - user login
	name  - database name
	pass  - password
	port  - port to connect
	sth   - query handler
=cut
our %Attributes = (
	dbh   => undef,
	host  => undef,
	login => undef,
	name  => undef,
	pass  => undef,
	port  => undef,
	sth   => undef,
);

=begin nd
Constructor: new ($conn)
	Make connection to the database.
	
Returns:
	$self - if ok
	undef - if connection fails
=cut
sub new {
	my ($class, @conn) = @_;
	my $self = $class->SUPER::new(@conn);

	my $dsn = "dbi:Pg:database=$self->{name};host=$self->{host};port=$self->{port}";
	$self->{dbh} = DBI->connect($dsn, $self->{login}, $self->{pass}, {RaiseError => 0})
		or return warn 'SYSTEM|ALERT:', DBI->errstr;
	
	$self;
}

=begin nd
Method: exec ($q, @param)
	Execute a query.
	
	After DBI->prepare() and bind params, the query will executed as many times as required.

Params:
	$q     - query as string, or <Crop::Object::Warehouse::Lang::SQL::Query>

	@param - array provides values for placeholders
		Array contains pseudo-hashes (i.e. pairs) field_1=>value_1, field_2=>value_2, field_name=>[value_1, value_2, ..., value_n], ...
		Arrayref in value position causes multiple execution - on for every value.

		Field names are redudant for now.

Returns:
	$sth  - if ok
	false - otherwise
=cut
sub exec {
	my ($self, $q) = @_;
	
	unless (ref $q and $q->isa('Crop::Object::Warehouse::Lang::SQL::Query')) {
# 		debug 'DBI_EXEC_QUERY=', $q;
		return warn "WAREHOUSE|CRIT: QUERY REQUIRED";
	}

	return warn "WAREHOUSE|ALERT: No query specified for execute" unless $q;

	my ($sql, $param) = $q->print_sql;
	debug DL_SQL, 'DB::exec Query=', $sql, ";\nDB::exec QParam=", $param;

	unless (defined $param) {
		debug 'DBI_EXEC_UNDEFPARAM_QUERY=', $sql;
	}
	if (@$param % 2) {
		debug 'DBI_EXEC_ODDPARAM_QUERY=', $sql;
		debug 'DBI_EXEC_ODDPARAM_PARAM=', $param;
	}
	return warn "WAREHOUSE|ALERT: Odd number in param hash" if @$param % 2;
	my $paramN = @$param / 2;
	
	$self->{sth} = my $sth = $self->{dbh}->prepare($sql);

	return warn "WAREHOUSE|ALERT: Can't prepare query: $sql: ", $sth->errstr unless $sth;

	return warn "WAREHOUSE|ALERT: Placeholders number don't match values number expected $sth->{NUM_OF_PARAMS} but received $paramN=@$param;" unless $sth->{NUM_OF_PARAMS} == $paramN;

	# calculate execution count
	my $execN;
	my ($k, $v);
	for (my $i = 0; $i < @$param; ++$i) {
		if ($i % 2) {
			$v = $param->[$i];
		} else {
			$k = $param->[$i];
			next;
		}
		next unless ref $v eq 'ARRAY';

		return warn "WAREHOUSE|ALERT: Empty param's array" unless @$v;

		if ($execN) {
			return warn "WAREHOUSE|ALERT: Distinct param's array numer" unless $execN == @$v;
		} else {
			$execN = @$v;
		}
	}
	$execN ||= 1;

	for (1 .. $execN) {
		my $ix = $_ - 1;

		# bind params
		for (1 .. $paramN) {
			my $iv = $_ * 2 - 1;       # index of value
			my $current = $param->[$iv]; # value or value arrayref

			# value to bind
			my $value = ref $current eq 'ARRAY' ? $current->[$ix] : $current;

			$sth->bind_param($_, $value) or return warn "DBASE: Can't bind value $value in query $sql: ", $sth->errstr;
		}

		$self->{affected} = $sth->execute or return warn "DBASE: Can't execute statement $sql: ", $sth->errstr;
		$self->{affected} += 0;
	}

	$self->{sth} = $sth;
}

=begin nd
Method: fetch ($q, @param)
	Execute query to get result.

	Result will be the first item in scalar context, and all items in list context.

Parameters:
	$q     - query string, or Query object
	@param - see <fetch_all ($Q, @param)>.

Returns:
	arrayref of hashes - in list context
	hashref            - in scalar context
=cut
sub fetch {
	my $self = shift;
	
	my $rc = $self->fetch_all(@_);

	if (wantarray) {
		$rc
	} else {
		$self->{sth}->finish;
		$rc->[0];
	}
}

=begin nd
Method: fetch_all ($q)
	Execute and get result.

Parameters:
	$q     - Query exemplar

Returns:
	arrayref of hashes - if ok
	undef              - otherwise
=cut
sub fetch_all {
	my ($self, $q) = @_;

	return warn 'DBASE: fetch_all() requires the Query exemplar' unless $q;
	
	$self->{sth} = $self->exec($q) or return warn 'OBJECT|CRIT: Can not fetch result from database';

	$self->{sth}->fetchall_arrayref({});
}

1;
