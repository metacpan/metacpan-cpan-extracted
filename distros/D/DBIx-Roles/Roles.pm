# $Id: Roles.pm,v 1.18 2006/01/30 10:58:51 dk Exp $

package DBIx::Roles;

use DBI;
use Scalar::Util qw(weaken);
use strict;
use vars qw($VERSION %loaded_packages $DBI_connect %DBI_select_methods $debug $ExportDepth);

$VERSION = '1.04';
$ExportDepth = 0;
$DBI_connect = \&DBI::connect;
%DBI_select_methods = map { $_ => 1 } qw(
	selectrow_array
	selectrow_arrayref
	selectrow_hashref
	selectall_arrayref
	selectall_hashref
	selectcol_arrayref
);

sub import
{
	shift;
	return unless @_;

	# if given list of imports, override DBI->connect() with it
	my $callpkg = caller($ExportDepth);
	no strict;
	*{$callpkg."::DBIx_ROLES"}=[@_];	
	use strict;
	local $SIG{__WARN__} = sub {};
	*DBI::connect = \&__DBI_import_connect;
}

# called instead of DBI-> connect
sub __DBI_import_connect
{
	shift;
	my $callpkg = caller(0);
	no strict;
	my @packages = @{$callpkg."::DBIx_ROLES"};
	use strict;
	if ( @packages) {
		return DBIx::Roles-> new( @packages)-> connect( @_);
	} else {
		return $DBI_connect->( 'DBI', @_);
	}
}

# prepare new instance, do not connect to DB
sub new
{
	my ( $class, @packages) = @_; 

	# load the necessary packages
	for my $p ( @packages) {
		$p = "DBIx::Roles::$p" unless $p =~ /:/;
		next if exists $loaded_packages{$p};
		eval "use $p;";
		die $@ if $@;
		$loaded_packages{$p} = 1;
	}
	push @packages, 'DBIx::Roles::Default';

	##  create the object:
	# internal data instance
	my $instance	= {
		dbh	=> undef,     # DBI handle 

		packages=> \@packages, # array of DBIx::Roles::* packages to use
		private	=> {          # packages' private data - all separated
			map { $_ => undef } @packages
		}, 
		defaults=> {},        # default values and source packages for attributes 
		disabled=> {},        # dynamically disabled packages
		attr	=> {},        # packages' public data - all mixed, and
		vmt	=> {},        # packages' public methods - also all mixed
		                      # name clashes in public and vmt will be explicitly fatal 

		loops   => [], 
	};

	# populate package info
	for my $p ( @packages) {
		my $ref = $p->can('initialize');
		next unless $ref;
		my ( $storage, $data, @vmt) = $ref->( $instance);
		$instance-> {private}-> {$p} = $storage;

		# store default data
		if ( $data) {
			my $dst = $instance->{attr};
			my $def = $instance->{defaults};
			while ( my ( $key, $value) = each %$data) {
				die 
					"Fatal: package '$p' defines attribute '$key' ".
					"that conflicts with package '$def->{$key}->[0]'"
						if exists $dst->{$key};
				$def->{$key} = [$p, $value];
				$dst->{$key} = $value;
			}
		}

		# store public methods
		my $dst = $instance->{vmt};
		for my $key ( @vmt) {
			die 
				"Fatal: package '$p' defines method '$key' ".
				"that conflicts with package '$dst->{$key}'"
					if exists $dst->{$key};
			$dst->{$key} = $p;
		}
	}
	# DBIx::Roles::Instance provides API for the packages 
	bless $instance, 'DBIx::Roles::Instance';

	# DBI attributes
	my $self 	= {};
	tie %{$self}, 'DBIx::Roles::Instance', $instance;
	bless $self, $class;

	# use this trick for cheap self-referencing ( otherwise the object is never destroyed )
	$instance->{self} = $self;
	weaken( $instance->{self});

	return $self;
}

# connect to DB
sub connect
{
	my $self = shift;

	unless ( ref($self)) {
		# called as DBIx::Roles-> connect(), packages provided
		$self = $self-> new( @{shift()});
	} # else the object is just being reconnected

	my $inst = $self-> instance; 

	$self-> disconnect if $inst->{dbh};

	my @p = @_;

	# ask each package what do they think about params to connect
	$inst-> dispatch( 'rewrite', 'connect', \@p);

	# now, @p can be assumed to be in DBI-compatible format
	my ( $dsn, $user, $password, $attr) = @p;
	$attr ||= {};

	# validate each package's individual parameters
	for my $k ( keys %$attr) {
		next unless exists $inst->{defaults}->{$k};
		$inst-> dispatch( 'STORE', $k, $attr->{$k});
	}

	# apply eventual attributes passed from outside,
	# override with defaults those that have survived disconnect()
	for my $k ( keys %{$inst->{defaults}}) {
		if ( exists $attr-> {$k}) {
			$inst-> {attr}-> {$k} = $attr-> {$k};
			delete $attr-> {$k};
		} else {
			$inst-> {attr}-> {$k} = $inst->{defaults}->{$k}->[1];
		};
	}

	# try to connect
	return $self 
		if $inst-> {dbh} = $inst-> connect( $dsn, $user, $password, $attr);
	die "Unable to connect: no suitable roles found\n" 
		if $attr->{RaiseError};
	return undef;
}

# access object data instance
sub instance {  tied %{ $_[0] } }

# disconnect from DB, but retain the object
sub disconnect
{
	my $self = $_[0];
	my $inst = $self-> instance;
	
	$inst-> disconnect if $inst->{dbh};
}

sub AUTOLOAD
{
	my @p = @_;

	use vars qw($AUTOLOAD);
	my $method = $AUTOLOAD;
	$method =~ s/^.*:://;

	my $self = shift @p;
	my $inst = $self-> instance;

	my $package;

	if ( 
		exists( $DBI::DBI_methods{common}->{$method}) or
		exists( $DBI::DBI_methods{db}->{$method})
	) {
		# is it a DBI native method?
		# rewrite
		$inst-> dispatch( 'rewrite', $method, \@p);

		# dispatch
		@_ = ( $inst, $method, @p);
		goto $inst-> can('dispatch_dbi_method');
	} elsif ( exists $inst->{vmt}->{$method}) {
		# is it an exported method for outside usage?
		my $package = $inst->{vmt}->{$method};
		my $ref = $package-> can( $method);
		die "Package '$package' declared method '$method' as available, but it is not"
			unless $ref; # XXX AUTOLOAD cases are not handled
		@_ = ( $inst, $inst->{private}->{$package}, @p);
		goto $ref;
	} else {
		# none of the above, try wildcards
		@_ = ( $inst, 'any', $method, @p);
		goto $inst-> can('dispatch');
	}
}

sub DESTROY
{
	my $self = $_[0];
	my $inst = $self-> instance;
	$inst-> disconnect if $inst->{dbh};

	untie %$inst;
}

# internal API
package DBIx::Roles::Instance;

# since DBI::connect can be overloaded, call the connect method by reference
sub DBI_connect { shift; $DBIx::Roles::DBI_connect->('DBI', @_ ) }

# iterate through each package in the recursive way
sub get_super
{
	my ( $self) = @_;

	my $ref;
	my $ctx = $self->{loops}->[-1];
	while ( 1) {
		if ( $ctx->[0] < scalar @{$self-> {packages}}) {
			# next package
			my $package = $self-> {packages}->[ $ctx->[0]++];
			next if $self->{disabled}->{$package};
			next unless $ref = $package-> can( $ctx->[1]);
			print STDERR ('  'x @{$self->{loops}}), "-> $package\n" if $DBIx::Roles::debug;
			return ( $ref, $self-> {private}-> {$package});
		} elsif ( $ctx->[2]) {
			# signal end of list
			return $ctx->[2]->( $self, $ctx);
		} else {
			return;
		}
	}
}

# iterate through each package in the recursive way
sub super
{
	my $self = shift;
	my ( $ref, $private) = $self-> get_super;
	return unless $ref;
	unshift @_, $self, $private;
	goto $ref;
}

# saves and restores context of dispatch calls - needed if underlying roles 
# are needed to be restarted
sub context
{
	if ( $#_) {
		@{$_[0]->{loops}->[-1]} = @{$_[1]};
	} else {
		return [ @{$_[0]->{loops}->[-1]} ];
	}
}

# call $method in all packages, where available, returns the result of the call
sub dispatch
{
	my $self = shift;
	my $eol_handler = shift if $_[0] and ref($_[0]);
	my $method = shift;

	my @ret;
	my $wa = wantarray;
	push @{$self->{loops}}, [ 0, $method, $eol_handler, 0];
	print STDERR ('  'x @{$self->{loops}}), "dispatch(",
		( join ',', map { defined($_) ? $_ : "undef"} $method,@_), ")\n"
			if $DBIx::Roles::debug;
	eval {
		if ( $wa) {
			@ret = $self-> super( @_);
		} else {
			$ret[0] = $self-> super( @_);
		}
	};
	print STDERR ('  'x @{$self->{loops}}), "done $method\n" if $DBIx::Roles::debug;
	pop @{$self->{loops}};
	die $@ if $@;
	return wantarray ? @ret : $ret[0];
}

# if called, then that means that all $method hooks were called,
# and now 'dbi_method' round must be run 
sub _dispatch_dbi_eol
{
	my ( $self, $ctx, $params) = @_;

	$ctx->[0] = 0;               # reset the counter
	my $method = $ctx->[1];
	$ctx->[1] = 'dbi_method';    # call that hook instead 
	$ctx->[2] = undef;           # clear the eol handler
	print STDERR ('  'x @{$self->{loops}}), "done($method),dispatch(dbi_method)\n" if $DBIx::Roles::debug;
	return sub { $_[0]-> super( $method, @_[2..$#_]) }
}

# dispatch a native DBI method - first $method, then dbi_method hooks
sub dispatch_dbi_method
{
	my ( $self, $method, @parameters) = @_;
	splice( @_, 1, 0, \&_dispatch_dbi_eol);
	goto &dispatch;
}

sub enable_roles
{ 
	my $hash = shift->{disabled};
	for my $p (@_) {
		my $g = ($p =~ /:/) ? $p : "DBIx::Roles::$p";
		$hash->{$g}-- if $hash->{$g} > 0;
	}
}

sub disable_roles 
{ 
	my $hash = shift->{disabled};
	for my $p (@_) {
		my $g = ($p =~ /:/) ? $p : "DBIx::Roles::$p";
		$hash->{$g}++;
	}
}

# R/W access to the underlying DBI connection handle
sub dbh
{
	return $_[0]-> {dbh} unless $#_;
	$_[0]-> {dbh} = $_[1];
}

# access to the DBIx::Roles object
sub object { $_[0]-> {self} }

# all unknown functions, called by roles internally, are assumed to be DBI methods
sub AUTOLOAD
{
	use vars qw($AUTOLOAD);

	my $method = $AUTOLOAD;
	$method =~ s/^.*:://;
	
	splice( @_, 1, 0, $method);
	goto &dispatch_dbi_method;
}

sub TIEHASH { $_[1] }
sub EXISTS  { shift-> dispatch( 'EXISTS', @_) }
sub FETCH   { shift-> dispatch( 'FETCH',  @_) }
sub STORE   { shift-> dispatch( 'STORE',  @_) }
sub DELETE  { shift-> dispatch( 'DELETE', @_) }

sub DESTROY { shift-> dispatch( 'DESTROY') }

package DBIx::Roles::Default;

sub connect
{
	my ( $self, $storage, $dsn, $user, $password, $attr) = @_;
	return $DBIx::Roles::DBI_connect->( 'DBI', $dsn, $user, $password, $attr);
}

sub disconnect
{
	my $self = $_[0];

	$self-> {dbh}-> disconnect;
	$self-> {dbh} = undef;
}

sub dbi_method
{
	my ( $self, $storage, $method, @parameters) = @_;
	return $self-> {dbh}-> $method( @parameters);
}

sub any
{
	my ( $self, $storage, $method) = @_;
	my @c = caller( $self-> {loops}->[-1]->[3] * 2);
	die "Cannot locate method '$method' at $c[1] line $c[2]\n";
}

sub EXISTS
{
	my ( $self, $storage, $key) = @_;
	if ( exists $self-> {attr}-> {$key}) {
		return exists $self-> {attr}-> {$key};
	} else {
		return exists $self-> {dbh}-> {$key};
	}
}

sub FETCH
{
	my ( $self, $storage, $key) = @_;
	if ( exists $self-> {attr}-> {$key}) {
		return $self-> {attr}-> {$key};
	} else {
		return $self-> {dbh}-> {$key};
	}
}

sub STORE
{
	my ( $self, $storage, $key, $val) = @_;
	if ( exists $self-> {attr}-> {$key}) {
		$self-> {attr}-> {$key} = $val;
	} else {
		$self-> {dbh}-> {$key} = $val;
	}
}

sub DELETE
{
	my ( $self, $storage, $key) = @_;
	if ( exists $self-> {attr}-> {$key}) {
		delete $self-> {attr}-> {$key};
	} else {
		delete $self-> {dbh}-> {$key};
	}
}

1;

__DATA__

=pod

=head1 NAME

DBIx::Roles - Roles for DBI handles

=head1 DESCRIPTION

The module provides common API for using roles (AKA mixins/interfaces/plugins)
on DBI handles. The problem it solves is that there are a lot of interesting
and useful C<DBIx::> modules on CPAN, that extend the DBI functionality in one
or another way, but mostly they insist on wrapping the connection handle
themselves, so it is usually not possible to use them together.
Also, once in a while, one needs a local nice-to-have hack, which is not really
good enough for CPAN, but is still useful - for example, a common C<<
DBI->connect() >> wrapper that reads DSN from the config file. Of course, one
might simply write a huge wrapper for all possible add-ons, but this approach
is not really scalable. Instead, this module allows to construct your own
functionality for the DB connection handle, by picking from various bells and
whistles provided by other C<DBIx::Roles::*> modules.

The package is bundled with a set of predefined role modules ( see L<"Predefined role modules">).

=head1 SYNOPSIS

There are three ways to use the module for wrapping a DBI connection handle.
The best is IMO is this:

   use DBIx::Roles qw(AutoReconnect SQLAbstract);
   my $dbh = DBI-> connect($dsn, $user, $pass);

When the module is imported with a list of roles, it overrides C<< DBI-> connect >>
so that calls within the current package result in creation of C<DBIx::Roles>
object, which then behaves identically to the DBI handle. Calls to 
C<< DBI-> connect >> outside the package are not affected, moreover, different
packages can import C<DBIx::Roles> with different roles.

The more generic syntax can be used to explicitly list the required roles:

   use DBIx::Roles;
   my $dbh = DBIx::Roles->new( qw(AutoReconnect SQLAbstract));
   $dbh-> connect( $dsn, $user, $pass);

or even

   use DBIx::Roles;
   my $dbh = DBIx::Roles-> connect( 
   	[qw(AutoReconnect SQLAbstract)], 
	$dsn, $user, $pass
   );

All these are equivalent, and result in construction of an object that plays
roles C<DBIx::Roles::AutoReconnect> and C<DBIx::Roles::SQLAbstract>, plus does all 
DBI functionality.

An example below uses C<DBIx::Roles> to contact a PostgreSQL DB, and then read 
some backend information:

   use strict;
   use DBIx::Roles qw(SQLAbstract StoredProcedures);
   
   # connect to a predefined DB template1
   my $d = DBI-> connect( 'dbi:Pg:dbname=template1', 'pgsql', '');
   
   # StoredProcedures converts pg_backend_pid() into "SELECT * FROM pg_backend_pid()"
   print "Backend PID: ", $d-> pg_backend_pid, "\n";
   
   # SQLAbstract declares select(), use it to read currently connected clients
   use Data::Dumper;
   my $st = $d-> select( 'pg_stat_activity', '*');
   print Dumper( $st-> fetchall_arrayref );
   
   # done
   $d-> disconnect;

The roles used in the example are basically syntactic sugar, but there are other roles
that do alter the program behavior, if applied. For example, adding C<AutoReconnect> to 
the list of the imported roles makes C<select()> calls restartable.

=head1 Predefined role modules

All modules included in packages have their own manual pages, so only brief
descriptions are provided here:

L<DBIx::Roles::AutoReconnect> - Restarts DB call if database connection breaks.
Based on idea of L<DBIx::AutoReconnect>

L<DBIx::Roles::Buffered> - Buffers write-only queries. Useful with lots of INSERTs
and UPDATEs over slow remote connections.

C<DBIx::Roles::Default> - not a module on its own, but a package that is
always imported, and need not to be imported explicitly. Implements actual calls
to DBI handle.

L<DBIx::Roles::Hook> - Exports callbacks to override DBI calls.

L<DBIx::Roles::InlineArray> - Flattens arrays passed as parameters to DBI calls into strings.

L<DBIx::Roles::RaiseError> - Change defaults to C<< RaiseError => 1 >>

L<DBIx::Roles::Shared> - Share DB connection handles. To be used instead of C<< DBI-> connect_cached >>.

L<DBIx::Roles::SQLAbstract> - Exports methods C<insert>,C<select>,C<update> etc in the
L<SQL::Abstract> fashion. Inspired by L<DBIx::Abstract>.

L<DBIx::Roles::StoredProcedures> - Treats any method reached AUTOLOAD as a call to a 
stored procedure.

L<DBIx::Roles::Transaction> - Allow nested transactions like C<DBIx::Transaction> does.

=head1 Programming interfaces

The interface that faces the caller is not fixed. Depending on the
functionality provided by roles, the methods can be added, deleted, or
completely changed. For example, the mentioned before hack that would want to
connect to a database using a DSN being read from a config file, wouldn't need
the first three parameters to C<connect> to be present, and rather would modify
the C<connect> call so that instead of

   connect( $dsn, $user, $pass, [$attr])

it might look like

   connect( [$attr])

Using this fictional module, I'll try to illustrate to how a DBI interface
can be changed.

=head2 Writing a new role

To be accessible, a new role must reside in a unique module ( and usually a
unique package). The C<DBIx::Roles> prefix is not required, but is a
convenience hack, and is added by default if the imported role name does not
contain colons. So, if the role is to be imported as 

    use DBIx::Roles qw(Config);

then it must be declared as

    package DBIx::Roles::Config;

=head2 Modifying parameters passed to DBI methods

To modify the parameters passed the role must define C<rewrite> method to
transform the parameters:

    sub rewrite
    {
        my ( $self, $storage, $method, $parameters) = @_;
	if ( $method eq 'connect') {
	     my ( $dsn, $user, $pass) = read_from_config;
	     unshift @$parameters, $dsn, $user, $pass;
	}
	return $self-> super( $method, $parameters);
    }

The method is called before any call to DBI methods, so parameters are translated
to the DBI syntax.

=head2 Overloading DBI methods

If a particular method call is needed to be overloaded, for example, C<ping>,
the package must define a method with the same name:

    sub ping 
    { 
       my ( $self, $storage, @parameters) = @_;
       ...
    }

Since all roles are called recursively, one inside another, a role that
wishes to propagate the call further down the line, must call

    return $self-> super( @parameters)

as it is finished. If, on the contrary, the role decides to intercept the call,
C<super> need not to be called.  Also, in case one needs to intercept not just
one but many DBI calls, it is possible to declare a method that is called when
any DBI call is issued:

    sub dbi_method
    {
       my ( $self, $storage, $method, @parameters) = @_;
       print "DBI method $method called\n";
       return $self-> super( $method, @parameters);
    }

Note: C<super> is important, and forgetting to call it leads to strange errors

=head2 Overloading DBI attributes

Changes to DBI attributes such as C<PrintError> and C<RaiseError> can be caught
by C<STORE> method:

    sub STORE
    {
        my ( $self, $storage, $key, $val) = @_;
	print "$key is about to be set to $val, but I won't allow that\n";
	if ( rand 2) {
	    $val_ref = 42; # alter
	} else {
	    return;  # deny change
	}
        return $self-> super( $key, $val);
    }

=head2 Declaring own attributes, methods, and private storage

If a module needs its own attributes, method, or private storage, it needs to 
declare C<initialize> method:

   sub initialize
   {
       my ( $self ) = @_;
       return {
           # external attributes
           ConfigName => '/usr/local/etc/mydbi.conf',
       }, {
           # private storage
	   inifile => Config::IniFile->new,
	   loaded  => 0, 
       }, 
       # external methods
       qw(print_config load_config);
   }

The method is expected to return at least 2 references, first is a hash
reference to the external attributes and the second is the private storage.
Additional names are exported so these can be called directly.

In the example, the code that uses the role can change attributes as

    $dbh-> {ConfigName} = 'my.conf';

Changes to the attributes can be detected in C<STORE>, as described above.
Also, the exported methods can be accessed by the caller directly:

    $dbh-> print_conf;

Note that if roles with clashing attributes or method namespaces are applied
to the same C<DBIx::Roles> object, an exception is generated on the loading stage.

Finally, private storage is available as the second argument in all method calls
to the role ( it is referred here as C<$storage> ).

=head2 Overloading AUTOLOAD

If module declares C<any> method, all calls that are caught in C<AUTOLOAD>
are dispatched to it:

   sub any
   {
       my ( $self, $storage, $method, @parameters) = @_;
       if ( 42 == length $method) {
	   return md5( @parameters);
       }
       return $self-> super( $method, @parameters);
   }

L<DBIx::Role::StoredProcedures> uses this technique to call stored procedures.

=head2 Issuing DBI calls

The underlying DBI handle can be reached ( and changed ) by C<dbh> method:

    my $dbh = $self-> dbh;
    $self-> dbh( DBI-> connect( ... ));

but calling methods on it is not always the right thing to do. Instead of a
direct call, it is often preferable to call a the method so that it is 
re-injected through C<dispatch>, and travels through all roles. For example 

    sub my_fancy_select { shift-> selectall_arrayref( "SELECT ....") }

is better than

    sub my_fancy_select { shift-> dbh-> selectall_arrayref( "SELECT ....") }

because if gives chance to the other roles to override the call.

Also, it is also possible to reach to the external layer of the object:

    $self-> object-> selectall_arrayref(...)

but there's no guarantee that other roles won't change syntax of the call, so
calls on C<object> are not advisable.

=head2 Issuing DBI::connect

Calls to C<< DBI->connect >> are allowed be made directly, but there's another level
of flexibility: 

    $self-> DBI_connect()

does the same thing by default, but can be overridden, and thus is preferred to
the hardcoded C<< DBI-> connect >>.

=head2 Dispatching calls to role methods

There are two methods that cycle through list of applied roles, and
call a method, if available:

=over

=item dispatch $self, $method, @parameters

Calls $method in each role namespace, returns values returned by the
first role in the role chain.

=item dispatch_dbi_method $self, $wantarray, $method, @parameters

Same principle as dispatch, but first calls for $method, and then,
for C<dbi_method>, so that when the last role's $method calls C<super>,
the call is dispatched to the first role's C<dbi_method>.

=back

=head2 Restarting DBI calls

If the next role method is needed to be called indirectly,
one can get a reference to the next method by calling

    ( $ref, $private_storage) = $self-> get_super;

which returns the code reference and an extra parameter for the method.  If the
method is to be called repeatedly, it should be noted that inside that call
C<super> can also be called repeatedly. To save and restore the call context,
use read-write method C<context>:

   my $ctx = $self-> context;
   AGAIN: eval { $ref->( $self, $private_storage, @param); }
   if ( $@) {
       $self-> context( $ctx);
       goto AGAIN;
   }

Note: L<DBIx::Roles::AutoReconnect> restarts DBI calls when failed, 
check out its source code.

=head2 Hiding the list of roles

It is possible to create a package that exports a particular set of roles,
without requiring the caller to list them. Consider code for module C<MyDBI>:

   package MyDBI;

   sub import
   {
   	local $DBIx::Roles::ExportDepth = 1;
   	import DBIx::Roles qw(InlineArray Buffered StoredProcedures);
   }

This module, if C<use>'d, overloads the package of the caller so that
calls to C<< DBI->connect >> return a C<DBIx::Roles> object with the
list of roles predefined by C<MyDBI>.

It is also possible to define local roles, without exporting these to
a separate module. Hacking C<$DBIx::Roles::loaded_packages>
prevents C<DBIx::Role> from loading modules listed there:
   
   package MyDBI;
   
   $DBIx::Roles::loaded_packages{'DBIx::Roles::My_DBI_Role'} = 1;

   sub import
   {
   	local $DBIx::Roles::ExportDepth = 1;
   	import DBIx::Roles qw(My_DBI_Role InlineArray Buffered StoredProcedures);
   }

   package DBIx::Roles::My_DBI_Role;

   sub connect { .. read from config, for example ... }

=head2 Dynamically disable and enable roles

A pair of methods, C<disable_roles> and C<enable_roles> accepts a list
of roles and disables/enables these in an incremental fashion, so that

   $self-> disable_roles(qw(MyRole));
   $self-> disable_roles(qw(MyRole));
   $self-> enable_roles(qw(MyRole));

leaves the role disabled. The methods don't fail if there's no corresponding
role(s).
   
=head2 Accessing the internals

C<DBIx::Roles> defines method C<instance> that returns the underlying object
with API described above. All management of list of roles, call propagation,
etc etc is possible via this reference. In particular, the underlying DB
connection handle can be reached by reading C<< $db-> instance-> dbh >> .

=head1 BUGS

C<< DBI-> connect_cached >> is not supported. Use L<DBIx::Roles::Shared>>
instead.

=head1 SEE ALSO

Dependencies - L<DBI>, L<SQL::Abstract>

Similar or related modules - L<DBIx::Abstract>, L<DBIx::AutoReconnect>,
L<DBIx::Simple>, L<DBIx::SQLEngine>

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
