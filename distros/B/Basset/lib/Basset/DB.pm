package Basset::DB;

#Basset::DB 2002, 2003, 2004, 2005, 2006 James A Thomason III
#Basset::DB is distributed under the terms of the Perl Artistic License.

$VERSION = '1.03';

=pod

=head1 NAME

Basset::DB - talks to your database and gives you a few helper database methods.

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 SYNOPSIS

 #buried in the bowels of a module somewhere
 my $driver = Basset::DB->new();
 my $stmt = $driver->prepare('select * from some_table');

=head1 DESCRIPTION

You have a database. You're using Basset::Object::Persistent. You need to store objects. You need
to talk to your database. You're using Basset::DB::Table for all of your table related stuff. But,
some things are just simply database related (like connecting, transactions, etc.) for that, you
need something higher. Basset::DB does just that.

=cut

use Basset::Object;
use DBI 1.32 qw(:sql_types);

our @ISA = Basset::Object->pkg_for_type('object');

use strict;
use warnings;

=pod

=head1 ATTRIBUTES

=cut

#read only attribute. Hands you back the internal DBI handle.

__PACKAGE__->add_attr('handle');

=pod

=begin btest(handle)

my $o = __PACKAGE__->new();
$test->ok($o, "Got object");
$test->is(scalar(__PACKAGE__->handle), undef, "could not call object method as class method");
$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
$test->is($o->handle('abc'), 'abc', 'set handle to abc');
$test->is($o->handle(), 'abc', 'read value of handle - abc');
my $h = {};
$test->ok($h, 'got hashref');
$test->is($o->handle($h), $h, 'set handle to hashref');
$test->is($o->handle(), $h, 'read value of handle  - hashref');
my $a = [];
$test->ok($a, 'got arrayref');
$test->is($o->handle($a), $a, 'set handle to arrayref');
$test->is($o->handle(), $a, 'read value of handle  - arrayref');

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(handle)

=cut


__PACKAGE__->add_attr('dsn');

=pod

=begin btest(dsn)

my $o = __PACKAGE__->new();
my $dsn = $o->dsn;
$test->ok($o, "Got object");
$test->is(scalar(__PACKAGE__->dsn), undef, "could not call object method as class method");
$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
$test->is($o->dsn('abc'), 'abc', 'set dsn to abc');
$test->is($o->dsn(), 'abc', 'read value of dsn - abc');
my $h = {};
$test->ok($h, 'got hashref');
$test->is($o->dsn($h), $h, 'set dsn to hashref');
$test->is($o->dsn(), $h, 'read value of dsn  - hashref');
my $a = [];
$test->ok($a, 'got arrayref');
$test->is($o->dsn($a), $a, 'set dsn to arrayref');
$test->is($o->dsn(), $a, 'read value of dsn  - arrayref');
$test->is($o->dsn($dsn), $dsn, "reset dsn");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(dsn)

=cut

__PACKAGE__->add_attr('user');

=pod

=begin btest(user)

my $o = __PACKAGE__->new();
my $user = $o->user;
$test->ok($o, "Got object");
$test->is(scalar(__PACKAGE__->user), undef, "could not call object method as class method");
$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
$test->is($o->user('abc'), 'abc', 'set user to abc');
$test->is($o->user(), 'abc', 'read value of user - abc');
my $h = {};
$test->ok($h, 'got hashref');
$test->is($o->user($h), $h, 'set user to hashref');
$test->is($o->user(), $h, 'read value of user  - hashref');
my $a = [];
$test->ok($a, 'got arrayref');
$test->is($o->user($a), $a, 'set user to arrayref');
$test->is($o->user(), $a, 'read value of user  - arrayref');
$test->is($o->user($user), $user, "reset user");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(user)

=cut

__PACKAGE__->add_attr('pass');

=pod

=begin btest(pass)

my $o = __PACKAGE__->new();
my $pass = $o->pass();
$test->ok($o, "Got object");
$test->is(scalar(__PACKAGE__->pass), undef, "could not call object method as class method");
$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
$test->is(scalar($o->pass), undef, 'pass is undefined');
$test->is($o->pass('abc'), 'abc', 'set pass to abc');
$test->is($o->pass(), 'abc', 'read value of pass - abc');
my $h = {};
$test->ok($h, 'got hashref');
$test->is($o->pass($h), $h, 'set pass to hashref');
$test->is($o->pass(), $h, 'read value of pass  - hashref');
my $a = [];
$test->ok($a, 'got arrayref');
$test->is($o->pass($a), $a, 'set pass to arrayref');
$test->is($o->pass(), $a, 'read value of pass  - arrayref');
$test->is($o->pass($pass), $pass, "reset pass");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(pass)

=cut


=pod

=over

=item failed

Boolean attribute, set internally if the current transaction has been failed.

=cut

__PACKAGE__->add_attr('failed');

=pod

=begin btest(failed)

my $o = __PACKAGE__->new();
$test->ok($o, "Got object");
$test->is(scalar(__PACKAGE__->failed), undef, "could not call object method as class method");
$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
$test->is(scalar($o->failed), undef, 'failed is undefined');
$test->is($o->failed('abc'), 'abc', 'set failed to abc');
$test->is($o->failed(), 'abc', 'read value of failed - abc');
my $h = {};
$test->ok($h, 'got hashref');
$test->is($o->failed($h), $h, 'set failed to hashref');
$test->is($o->failed(), $h, 'read value of failed  - hashref');
my $a = [];
$test->ok($a, 'got arrayref');
$test->is($o->failed($a), $a, 'set failed to arrayref');
$test->is($o->failed(), $a, 'read value of failed  - arrayref');

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(failed)

=back

=cut




=pod

=head1 METHODS

=cut

sub init {

	my $self = shift->SUPER::init(
		'stack' => 0,
		@_
	) or return;

	my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($self->pkg, $self->dsn, $self->user, $self->pass));

	if (my $pooledobj = $self->pool->{$poolkey}) {
		$self = $pooledobj;
	}

	$self->recreate_handle() or return;

	$self->pool->{$poolkey} = $self;

	return $self;
}

__PACKAGE__->add_class_attr('pool', {});

=pod

=begin btest(new__only)

$test->ok(1, "Due to pooling, SUPER new tests cannot work. Assumes success");

=end btest(new__only)

=pod

=begin btest(init)

my $o = __PACKAGE__->new();
$test->ok($o, "got object for init");
$test->ok($o->dsn, "DSN is defined");
$test->ok($o->user, "user is defined");

local $@ = undef;

my $o2 = __PACKAGE__->new();
$test->ok($o, "got second object for init");
$test->is($o, $o2, "objects match, due to pooling");
$test->is($o->handle, $o2->handle, "handles match, due to pooling");


=end btest(init)

=cut

=pod

=item recreate_handle

recreates the database handle with the original parameters. This will blindly blow away the DBI handle,
so be careful with this method.

=cut

sub recreate_handle {
	my $self = shift;
	
        if ($self->handle && $self->stack) {
                $self->notify("warnings", "Warning - driver destroyed with transaction stack");
	}

	if ($self->handle) {
		$self->wipe();
		$self->handle->disconnect;
	}

	my $h = $self->create_handle(
		'dsn'			=> $self->dsn,
		'user'			=> $self->user,
		'pass'			=> $self->pass,
		'AutoCommit'	=> 0,
	) or return;
	
	return $self->handle($h);
}		

=pod

=begin btest(recreate_handle)

=end btest(recreate_handle)

=cut

=pod

=over

=item create_handle

Takes a hash of values (dsh, user, pass) which are used to create a new database handel.
By default, uses DBI's connect_cached method. Can be overridden in subclasses.

=cut

sub create_handle {
	my $class = shift;
	my %init = @_;

	my $h = DBI->connect_cached(
		$init{'dsn'},
		$init{'user'},
		$init{'pass'},
		{'AutoCommit' => $init{'AutoCommit'}},
	) or return $class->error(DBI->errstr, "BD-01");

	return $h;
}

=pod

=begin btest(create_handle)

local $@ = undef;
eval {
	__PACKAGE__->create_handle(); #fails w/o args
};
$test->ok($@, "DBI connect failed");

=end btest(create_handle)

=cut


sub DESTROY {
	my $self = shift;
	if ($self->handle && $self->stack) {
		$self->notify("warnings", "Warning - driver destroyed with transaction stack");
		$self->stack(0);
		$self->handle->rollback;
		$self->handle->disconnect;
	};
};

=pod

=begin btest(DESTROY)

=end btest(DESTROY)

=cut


=pod

=item AUTOLOAD

friggin' DBI cannot be subclassed. So AUTOLOAD sits in between. Any method called on a Basset::DB
object that it doesn't understand creates a new method that passes through to the internal handle
and calls the method on that. So, obviously, only use DBI methods.

=cut

sub AUTOLOAD {
	my $self = shift;
	(my $method = $Basset::DB::AUTOLOAD) =~ s/^(.+):://;
	
	if ($method ne 'DESTROY') {

		if (defined $self->handle){ 
			no strict 'refs';
			my $pkg = $self->pkg;
			
			*{$pkg . "::$method"}  = sub {
				my $self	= shift;

				if (my $handle = $self->handle) {
					local $@ = undef;
					my $rc = undef;
					eval {
						$rc = $handle->$method(@_);
					};
					if ($@) {
						return $self->error("Cannot call method ($method) : DBI does not support ($@)", "BD-14");
					} else {
						return $rc || $self->error($handle->errstr, "BD-11");
					};
				} else {
					return $self->error("Cannot call method ($method) : no handle", "BD-12");
				}
			};

			return $self->$method(@_);
#			shift->$accessor($method, @static_args, @_)};
#			return $self->handle->$method(@_);
		} else {
			return $self->error("Cannot do anything without handle", "BD-09");
		};
	}

};

=pod

=begin btest(AUTOLOAD)

=end btest(AUTOLOAD)

=cut


__PACKAGE__->add_attr('stack');

{
	my $stacks = {};

=pod

=item stack

This is your transaction stack for your driver. You will rarely (if ever) need to see
this directly.

 $driver->begin();
 print $driver->stack(); #1
 $driver->begin();
 print $driver->stack(); #2
 $driver->begin();
 print $driver->stack(); #3
 
=cut
	
=pod

=begin btest(stack)

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->is($o->stack, 0, "stack is 0");
$test->is($o->stack(5), 5, "stack does increment w/transatcions");
$test->is($o->stack, 5, "stack is at 5");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(stack)

=cut


=pod

=item begin

Adds 1 to your transaction stack

=cut

	sub begin {
		my $self = shift;
		
		return $self->error("Cannot begin transaction - failed", "BD-13") if $self->failed;
		
		return $self->stack($self->stack + 1);
	}

=pod

=begin btest(begin)

my $o = __PACKAGE__->new();
$o->wipe;
$test->ok($o, "got transaction enabled object");
$test->is($o->stack, 0, "stack is 0");
$test->is($o->begin, 1, "began transaction, stack is 1");
$test->is($o->stack, 1, "stack is 1");
$test->is($o->begin, 2, "began transaction, stack is 2");
$test->is($o->stack, 2, "stack is 2");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(begin)

=cut


=pod

=item end

Subtracts 1 from your transaction stack.

=cut

	sub end {
		my $self = shift;
		
		my $stack = $self->stack($self->stack - 1);

		if ($stack <= 0) {

			$self->stack(0);

			if ($self->failed) {
				$self->notify('warnings', 'Silently unfailing failed stack with last end');
				$self->unfail;
				return $self->error("Cannot end transaction - failed", "BD-13");
			}
			else {
				$self->finish() or return;
			}

			return '0 but true';
		} else {
			return $stack;
		};
	}

=pod

=begin btest(end)

my $o = __PACKAGE__->new();
$o->wipe;
$test->ok($o, "got transaction enabled object");
$test->is($o->stack, 0, "stack is 0");
$test->is($o->begin, 1, "began transaction, stack is 1");
$test->is($o->stack, 1, "stack is 1");
$test->is($o->begin, 2, "began transaction, stack is 2");
$test->is($o->stack, 2, "stack is 2");
$test->is($o->end, 1, "end transaction, stack is 1");
$test->is($o->stack, 1, "stack is 1");
$test->is($o->end, '0 but true', "end transaction, stack is 0 (but true)");
$test->is($o->stack, 0, "stack is 0");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(end)

=cut


=pod

=item finish

automagically finishes your transaction and sets your stack back to 0, regardless of how many items are on your stack.
Use this method with extreme care.

=cut

	sub finish {
		my $self = shift;

		my $handle = $self->handle;

		$handle->commit()
			or return $self->error($handle->errstr, "BD-07");

		$self->stack(0);
		return 1;
	}
	
=pod

=begin btest(finish)

my $o = __PACKAGE__->new();
$o->wipe;
$test->ok($o, "got transaction enabled object");
$test->is($o->stack, 0, "stack is 0");
$test->is($o->begin, 1, "began transaction, stack is 1");
$test->is($o->stack, 1, "stack is 1");
$test->is($o->begin, 2, "began transaction, stack is 2");
$test->is($o->stack, 2, "stack is 2");
$test->is($o->finish, 1, "finished transaction");
$test->is($o->stack, 0, "stack is 0");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(finish)

=cut



=pod

=item fail

fails your transaction and rolls it back from the database. If you just want to fail your transaction
but otherwise not roll it back, then simply set failed = 1.

=cut

	sub fail {
		my $self = shift;
		
		return $self->wipe();
	}
	
=pod

=begin btest(fail)

my $o = __PACKAGE__->new();
$o->wipe;
$test->ok($o, "got transaction enabled object");
$test->is($o->stack, 0, "stack is 0");
$test->is($o->begin, 1, "began transaction, stack is 1");
$test->is($o->stack, 1, "stack is 1");
$test->is($o->begin, 2, "began transaction, stack is 2");
$test->is($o->stack, 2, "stack is 2");
$test->is($o->fail, 1, "failed transaction");
$test->is($o->stack, 0, "stack is 0");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(fail)

=cut

=pod

=item unfail

unfails a transaction. If a fatal error occurs and you want to continue, you must unfail

=cut

sub unfail {
	my $self = shift;
	$self->failed(0);
	$self->handle->rollback();
	return '0 but true';
}

=pod

=begin btest(unfail)

my $o = __PACKAGE__->new();
$o->wipe;
$test->ok($o, "got transaction enabled object");
$test->is($o->failed(1), 1, "driver transaction failed");
$test->ok($o->unfail, "unfailed transaction");
$test->ok(! $o->failed, "transaction no longer failed");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(unfail)

=cut

=pod

=item wipe

fails your transaction and rolls it back from the database if you have pending items on your stack.

=cut

	sub wipe {
		my $self = shift;

		my $handle = $self->handle;
		$handle->rollback()
			or return $self->error($handle->errstr, "BD-08");
	
		$self->stack(0);
		$self->failed(0);
	
		return 1;
	};
};

=pod

=begin btest(wipe)

my $o = __PACKAGE__->new();
$o->wipe;
$test->ok($o, "got transaction enabled object");
$test->is($o->stack, 0, "stack is 0");
$test->is($o->begin, 1, "began transaction, stack is 1");
$test->is($o->stack, 1, "stack is 1");
$test->is($o->begin, 2, "began transaction, stack is 2");
$test->is($o->stack, 2, "stack is 2");
$test->is($o->wipe, 1, "wiped transaction");
$test->is($o->stack, 0, "stack is 0");

my $poolkey = join(',', map{defined $_ ? $_ : 'undef'} ($o->dsn, $o->user, $o->pass));
delete $o->pool->{$poolkey};

=end btest(wipe)

=cut

=pod

=item copy

Copying Basset::DB objects is frowned upon. Nonetheless, if you must do it, you're still going
to get the same database handle back. That is to say, the exact same object.

Note - as a result of how this has to work (and some DBI bitching), copying Basset::DB objects
is not thread safe.

=cut

sub copy {
	my $self = shift;
	if (@_) {
		return $self->SUPER::copy(@_);
	} else {
		#grab our handle
		my $h = $self->handle;
		#wipe it out. Our copy is primitive and just dumps and evals the object
		$self->handle(undef);
		my $copy = $self->SUPER::copy;
		#reset the handle
		$self->handle($h);
		#set it in the copy
		$copy->handle($h);
		
		return $copy;
	}
}

=pod

=begin btest(copy)

my $obj = __PACKAGE__->new();
#$test->ok($obj, "Got object for copy test");
my $o2 = $obj->copy;
#$test->is($obj->copy, $o2->copy, "Copied objects match");

=end btest(copy)

=cut



=pod

=item sql_type

This is a wrapper method to DBI's sql_types constants. Pass in a string value consisting of the
sql type string, and it spits back the relevant DBI constant.

 my $some_constant = Basset::DB->sql_type('SQL_INTEGER');

Very useful if you're binding values or such.

=cut

our %cache = ();
sub sql_type {
	my $class	= shift;
	
	return $class->error("Cannot return type without type", "BD-02") unless @_;
	
	my $type	= shift;

	return undef unless defined $type;

	#return $type if $type =~ /^\d+$/;

	my $return	= $cache{$type} || eval $type || undef;

	$cache{$type} = $return;

	return $return;
};

=pod

=begin btest(sql_type)

$test->is(scalar(__PACKAGE__->sql_type), undef, "Cannot return type w/o type");
$test->is(__PACKAGE__->errcode, "BD-02", "proper error code");
{
	use DBI qw(:sql_types);
	$test->is(__PACKAGE__->sql_type('SQL_INTEGER'), SQL_INTEGER(), "proper type for integer");
	$test->is(__PACKAGE__->sql_type('SQL_INTEGER'), SQL_INTEGER(), "proper type for integer");
	$test->is(__PACKAGE__->sql_type('SQL_VARCHAR'), SQL_VARCHAR(), "proper type for varchar");
	$test->is(__PACKAGE__->sql_type(SQL_VARCHAR()), SQL_VARCHAR(), "proper type for varchar, given int");
	$test->is(__PACKAGE__->sql_type('__j_junk_type'), undef, "unknown type returns undef");
	$test->is(__PACKAGE__->sql_type(undef), undef, "undef type returns undef");
}

=end btest(sql_type)

=cut


=pod

=item tables

returns an array of all tables in your database. You may optionally pass in a database handle
to get all of the tables for that handle instead of the default

=cut

sub tables {
	my $class = shift;

	my $driver = shift || $class->new();

	my $query = "show tables";

	my $stmt = $driver->prepare_cached($query)
		or return $class->error($driver->errstr, "BD-03");

	$stmt->execute() or return $class->error($stmt->errstr, "BD-04");

	my @tables = ();
	while (my ($table) = $stmt->fetchrow_array){
		push @tables, $table;
	};

	$stmt->finish()
		or return $class->error($stmt->errstr, "BD-05");

	return @tables;

};

=pod

=item ping

just a wrapper around DBI's ping

=cut

sub ping {
	return shift->handle->ping;
};

=pod

=begin btest(tables)

=end btest(tables)

=cut


=pod

=item optimize_tables

MySQL only, most likely. Calls the "optimize table" command on all tables in your database,
or only upon those tables that you've passed in, if you prefer.

=cut

sub optimize_tables {
	my $class = shift;
	my @tables = @_ || $class->tables;

	my $driver = $class->new();

	foreach my $table (@tables){
		my $query = "optimize table $table";

		my $stmt = $driver->prepare_cached($query)
			or return $class->error($driver->errstr, "BD-03");

		$stmt->execute() or return $class->error($stmt->errstr, "BD-04");

		$stmt->finish()
			or return $class->error($stmt->errstr, "BD-05");
	};

	return @tables;
};

=pod

=begin btest(optimize_tables)

=end btest(optimize_tables)

=cut


1;
