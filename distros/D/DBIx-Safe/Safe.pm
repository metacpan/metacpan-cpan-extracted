# -*-cperl-*-
#
# Copyright 2006-2007 Greg Sabino Mullane <greg@endpoint.com>
#
# DBIx::Safe is a safer way of handling database connections.
# You can specify exactly which commands can be run.
#


package DBIx::Safe;

use 5.008003;
use utf8;
use strict;
use warnings;
use IO::Handle;
use DBI 1.42;

{

our $VERSION = '1.2.5';

*STDOUT->autoflush(1);
*STDERR->autoflush(1);

my %inner;

sub TIEHASH {
	my $class = shift;
	my $arg = shift;
	my $self = bless {}, $class;
	$inner{$self} = $arg;
	return $self;
}

sub STORE {
	my ($self,$key,$value) = @_;
	my $inner = $inner{$self};

	my $origkey = $key;
	$key = lc $key;
	die "Invalid access\n" unless index $key, 'dbixsafe_';

	if (exists $inner->{dbixsafe_allow_attribute}{$key}) {
		$inner->{dbixsafe_allow_attribute}{$key}++;
		$inner->{dbixsafe_sdbh}{$origkey} = $value;
		return;
	}
	die qq{Cannot change attribute "$key"};
}

sub FETCH {
	my ($self,$key) = @_;
	my $inner = $inner{$self};

	die "Invalid access\n" unless index $key, 'dbixsafe_';

	## Assume it is a $dbh value, and return it
	return $inner->{dbixsafe_sdbh}{$key};
}

sub FIRSTKEY {
	my $self = shift;
	my $inner = $inner{$self};
	my $foo = keys %{$inner->{dbixsafe_sdbh}};
	return each %{$inner->{dbixsafe_sdbh}};
}


sub new {
	my $class = shift;
	my $arg = shift;

	ref $arg and ref $arg eq 'HASH'
		or die qq{Method new() requires a hashref arguments};
	exists $arg->{dbh} or die qq{Required argument 'dbh' was not found\n};
	my $sdbh = $arg->{dbh};
	ref $sdbh and ref $sdbh eq 'DBI::db'
		or die qq{Argument 'dbh' is not a database handle\n};

	## This is where the real information is stored
	my %self = (
				dbixsafe_sdbh            => $sdbh,
				dbixsafe_allow_command   => {},
				dbixsafe_allow_regex     => {},
				dbixsafe_deny_regex      => {},
				dbixsafe_allow_attribute => {},
				);

	## Now let's make sure we know how to handle this type of database
	my $db = $sdbh->{Driver}{Name}
		or die qq{Failed to figure out driver name\n};
	if ($db eq 'Pg') {
		$self{dbixsafe_db} = 'Postgres';
		## Make sure we have the required versions
		my $libversion = $sdbh->{pg_lib_version};
		$libversion =~ /^\d+$/ and $libversion >= 80000
			or die qq{Must use a DBD::Pg compiled against version 8.0 or higher, this is $libversion\n};
		my $version = $sdbh->{pg_server_version};
		$libversion =~ /^\d+$/ and $libversion >= 70400
			or die qq{Must use against a Postgres server version 7.4 or higher, this is $version\n};
	} # end Postgres
	else {
		die "Sorry, I do not work with that type of database yet: $db\n";
	}

	## We'll be returning a tied hashref as the object
	my %object;
	my $codename = bless \%object, $class;
	$inner{$codename} = \%self;
	tie %object, 'DBIx::Safe', \%self;

	if (exists $arg->{allow_command}) {
		$self{dbixsafe_allow_command} = allow_command($codename, $arg->{allow_command});
	}
	if (exists $arg->{allow_regex}) {
		$self{dbixsafe_allow_regex} = allow_regex($codename, $arg->{allow_regex});
	}
	if (exists $arg->{deny_regex}) {
		$self{dbixsafe_deny_regex} = deny_regex($codename, $arg->{deny_regex});
	}
	if (exists $arg->{allow_attribute}) {
		$self{dbixsafe_allow_attribute} = allow_attribute($codename, $arg->{allow_attribute});
	}

	return $codename;

} ## end of new

sub DESTROY {
	my $self = shift;
	delete $inner{$self};
	return;
}


## Specifically unsupported database handle methods

sub prepare_cached {
	my $self = shift;
	die qq{Method prepare_cached() not supported yet\n};
}


sub safeprepare {

	## The main gatekeeper

	my $self = shift;
	my $type = shift;
	my $string = shift;

	$self = $inner{$self};

	die "Invalid type passed to safeprepare\n"
		unless $type =~ /^(?:do|prepare)$/io;

	## Figure out the first word in the statement

	$string =~ s/^\s*(\w+)\s*/$1 /
		or die qq{Could not find first word in string "$string"\n};
	my $firstword = lc $1; ## no critic

	## We flat out do not allow some commands in SQL statements
	my %transword = map { $_ => 1 } (qw(begin commit rollback release));
	if (exists $transword{$firstword}) {
		die "Cannot use $firstword in a statement\n";
	}

	## Check for denied regexes
	for my $deny (keys %{$self->{dbixsafe_deny_regex}}) {
		if ($string =~ $deny) {
			die qq{Forbidden statement\n};
		}
	}

	my $sdbh = $self->{dbixsafe_sdbh};

	if ($self->{dbixsafe_db} eq 'Postgres') {
		## Only a few words can pass through pg_prepare_now
		if ($firstword =~ /^(?:select|update|delete|insert)$/) {
			if (!exists $self->{dbixsafe_allow_command}{$firstword}) {
				die qq{(pg) Invalid statement: $string\n};
			}
			local $sdbh->{pg_prepare_now} = 1;
			my $sth = $sdbh->prepare($string);
			$self->{dbixsafe_allow_command}{$firstword}++;
			return $sth if $type eq 'prepare';
			return $sth->execute(@_);
		}
	}
	## Put other DBDs here
	else {
		die qq{Do not know how to handle that DBD yet!\n};
	}

	## Nobody else is allowed to have a semi-colon
	if ($string =~ /;/) {
		die qq{Commands cannot contain semi-colons};
	}

	## Is this an allowed word?
	my $found = 0;
	if (exists $self->{dbixsafe_allow_command}{$firstword}) {
		$self->{dbixsafe_allow_command}{$firstword}++;
		$found = 1;
	}
	else {
		## May be allowed as a regular expression
		for my $regex (keys %{$self->{dbixsafe_allow_regex}}) {
			## warn "Checking regex $regex against $string\n";
			if ($string =~ /^$regex/) {
				$self->{dbixsafe_allow_regex}{$regex}++;
				$found=2;
				last;
			}
		}
	}

	$found or die qq{Invalid statement: $string\n};

	if ($type eq 'do') {
		return $sdbh->do($string);
	}

	my $sth = $sdbh->prepare($string);

	return $sth if $type eq 'prepare';

	return $sth->execute(@_);

} ## end of safeprepare


## Query-related database handle methods

sub prepare {
	my $self = shift;
	return $self->safeprepare('prepare' => @_);
}


sub do {
	my $self = shift;
	return $self->safeprepare('do' => @_);
}


sub selectall_arrayref {
	my ($self, $string, $attr, @bind) = @_;
	my $sth = (ref $string) ? $string
		: $self->safeprepare('prepare', $string, $attr);
	$sth->execute(@bind);
	my $slice = $attr->{Slice}; # typically undef, else hash or array ref
	if (!$slice and $slice=$attr->{Columns}) {
		if (ref $slice eq 'ARRAY') { # map col idx to perl array idx
			$slice = [ @{$attr->{Columns}} ]; # take a copy
			for (@$slice) { $_-- }
		}
	}
	my $rows = $sth->fetchall_arrayref($slice, my $MaxRows = $attr->{MaxRows});
	$sth->finish if defined $MaxRows;
	return $rows;
} ## end of selectlall_arrayref


sub selectall_hashref {
	my ($self, $string, $key_field, $attr, @bind) = @_;
	my $sth = (ref $string) ? $string
		: $self->safeprepare('prepare', $string, $attr);
	$sth->execute(@bind);
	return $sth->fetchall_hashref($key_field);
} ## end of selectall_hashref


sub selectrow_array {
	my ($self, $string, $key_field, $attr, @bind) = @_;
	my $sth = (ref $string) ? $string
		: $self->safeprepare('prepare', $string, $attr);
	$sth->execute(@bind);
	my $row = $sth->fetchrow_arrayref() and $sth->finish();
	return $row->[0] unless wantarray;
	return @$row;
} ## end of selectrow_array


sub selectrow_arrayref {
	my ($self, $string, $key_field, $attr, @bind) = @_;
	my $sth = (ref $string) ? $string
		: $self->safeprepare('prepare', $string, $attr);
	$sth->execute(@bind);
	my $row = $sth->fetchrow_arrayref() and $sth->finish();
	return $row;
} ## end of selectrow_arrayref


sub selectrow_hashref {
	my ($self, $string, $key_field, $attr, @bind) = @_;
	my $sth = (ref $string) ? $string
		: $self->safeprepare('prepare', $string, $attr);
	$sth->execute(@bind);
	my $row = $sth->fetchrow_hashref() and $sth->finish();
	return $row;
} ## end of selectrow_hashref


sub selectcol_arrayref {
	my ($self, $string, $attr, @bind) = @_;
	my $sth = (ref $string) ? $string
		: $self->safeprepare('prepare', $string, $attr);
	$sth->execute(@bind);
	my @columns = ($attr->{Columns}) ? @{$attr->{Columns}} : (1);
	my @values  = (undef) x @columns;
	my $idx = 0;
	for (@columns) {
		$sth->bind_col($_, \$values[$idx++]) || return;
	}
	my @col;
	if (my $max = $attr->{MaxRows}) {
		push @col, @values while @col<$max && $sth->fetch;
	}
	else {
		push @col, @values while $sth->fetch;
	}
	return \@col;
} ## end of selectcol_hashref



## All other database handle methods we support

sub dbh_method {
	my $self = shift;
	(my $method = (caller 1)[3]) =~ s/^DBIx::Safe::(\w+)$/$1/
		or die "Invalid call to change_regex\n";
	exists $inner{$self}{dbixsafe_allow_command}{$method}
		or die qq{Calling method '$method' is not allowed\n};
	return $inner{$self}{dbixsafe_sdbh}->$method(@_);
}

sub quote             { return dbh_method(@_); }
sub quote_identifier  { return dbh_method(@_); }
sub last_insert_id    { return dbh_method(@_); }
sub table_info        { return dbh_method(@_); }
sub column_info       { return dbh_method(@_); }
sub primary_key_info  { return dbh_method(@_); }
sub get_info          { return dbh_method(@_); }
sub data_sources      { return dbh_method(@_); }
sub can               { return dbh_method(@_); }
sub parse_trace_flag  { return dbh_method(@_); }
sub parse_trace_flags { return dbh_method(@_); }

## Read-only, no args
sub ping              { return dbh_method(@_); }
sub err               { return dbh_method(@_); }
sub errstr            { return dbh_method(@_); }
sub state             { return dbh_method(@_); } ## no critic

## Write-only
sub trace_msg         { return dbh_method(@_); }
sub func              { return dbh_method(@_); }

## Transactional
sub commit            { return dbh_method(@_); }
sub rollback          { return dbh_method(@_); }
sub begin_work        { return dbh_method(@_); }

## Postgres specific
sub pg_savepoint      { return dbh_method(@_); }
sub pg_rollback_to    { return dbh_method(@_); }
sub pg_release        { return dbh_method(@_); }


## Special case database handle methods
sub trace {
	my $self = shift;
	exists $inner{$self}{dbixsafe_allow_command}{trace}
		or !@_
		or die qq{Calling method 'trace' with arguments is not allowed\n};
	return $inner{$self}{dbixsafe_sdbh}->trace(@_);
}




## Generic internal list modifiers

sub change_string {

	## Adds or removes one or more strings from an internal list
	## Returns the new list, even if no args

	my ($self,$arg) = @_;
	(my $method = (caller 1)[3]) =~ s/^DBIx::Safe::(\w+)$/$1/
		or die "Invalid call to change_regex\n";
	my $key = $method;
	my $type = ($key =~ s/^un//) ? 'remove' : 'add';
	my $list = $inner{$self}{"dbixsafe_$key"}
		or die qq{Invalid method call: $method\n};

	defined $arg or return $list;

	my $usage = qq{Method $method must be passed a string or an array of them\n};
	my $strictdoubles = 1;
	my $strictexists = 0;

	my %string;
	if (ref $arg) {
		ref $arg eq 'ARRAY' or die $usage;
		for my $s (@$arg) {
			if (exists $string{lc $s} and $strictdoubles) {
				die qq{Method $method was passed in duplicate argument: $s\n};
			}
			$string{lc $s}++;
		}
	}
	else {
		$string{$arg}++;
	}

	my %command;
	for my $s (keys %string) {
		$s =~ s/^\s*(.+)\s*$/$1/;
		for my $c (split /\s+/ => lc $s) {
			if ($c !~ /^[a-z_]+$/) {
				die qq{Method $method was passed an invalid argument: $c\n};
			}
			if (exists $command{$c} and $strictdoubles) {
				die qq{Method $method was passed in duplicate argument: $c\n};
			}
			if ($type eq 'remove') {
				if (! exists $list->{$c} and $strictexists) {
					die qq{Method $method was passed in non-existent argument: $c\n};
				}
			}
			else {
				if (exists $list->{$c} and $strictexists) {
					die qq{Method $method was passed in already existing argument: $c\n};
				}
			}
			$command{$c}++;
		}
	}
	for my $c (keys %command) {
		if ($type eq 'remove') {
			delete $list->{$c};
		}
		else {
			if ($c eq 'autocommit') {
				## We don't hardcode the method here: too easy to accidentally break
				die qq{Attribute AutoCommit cannot be changed};
			}
			$list->{$c} = 0;
		}
	}

	return $list;

} ## end of change_string


sub change_regex {

	## Adds or removes one or more regular expressions from an internal list
	## Returns the new list, even if no args

	my ($self,$arg) = @_;
	(my $method = (caller 1)[3]) =~ s/^DBIx::Safe::(\w+)$/$1/
		or die "Invalid call to change_regex\n";
	my $key = $method;
	my $type = ($key =~ s/^un//) ? 'remove' : 'add';
	my $list = $inner{$self}{"dbixsafe_$key"}
		or die "Invalid nethod call: $method\n";

	defined $arg or return $list;

	my $usage = qq{Method $method must be passed a regular expression or an array of them\n};
	ref $arg or die $usage;

	my $strictdoubles = 1;
	my $strictexists = 0;

	my %regex;
	if (ref $arg eq 'ARRAY') {
		for my $r (@$arg) {
			ref $r and ref $r eq 'Regexp' or die $usage;
			if (exists $regex{$r} and $strictdoubles) {
				die qq{Method $method was passed in duplicate regexes for $r\n};
			}
			$regex{$r}++;
		}
	}
	elsif (ref $arg eq 'Regexp') {
		$regex{$arg}++;
	}
	else {
		die $usage;
	}

	for my $r (keys %regex) {
		if ($type eq 'remove') {
			if (! exists $list->{$r} and $strictexists) {
				die qq{Method $method was passed in a non-existent regex: $r\n};
			}
			delete $list->{$r};
		}
		else {
			if (exists $list->{$r} and $strictexists) {
				die qq{Method $method was passed in an already existing regex: $r\n};
			}
			$list->{$r} ||= 0;
		}
	}

	return $list;

} ## end of change_regex


sub allow_command     { return change_string(@_); }
sub unallow_command   { return change_string(@_); }
sub allow_attribute   { return change_string(@_); }
sub unallow_attribute { return change_string(@_); }
sub unallow_regex     { return change_regex(@_);  }
sub undeny_regex      { return change_regex(@_);  }
sub deny_regex        { return change_regex(@_);  }
sub allow_regex       { return change_regex(@_);  }

}

1;

__END__

=pod

=head1 NAME

DBIx::Safe - Safer access to your database through a DBI database handle

=head1 VERSION

This documents version 1.2.5 of the DBIx::Safe module

=head1 SYNOPSIS

  use DBIx::Safe;

  $dbh = DBI->connect($dbn, $user, $pass, {AutoCommit => 0});

  my $safedbh = DBIx::Safe->new({ dbh => $dbh });

  $safedbh->allow_command('SELECT INSERT UPDATE');

  $safedbh->allow_regex(qr{LOCK TABLE \w+ IN EXCLUSIVE MODE});

  $safedbh->deny_regex(qr{LOCK TABLE pg_});

  $safedbh->allow_attribute('PrintError RaiseError');

=head1 DESCRIPTION

The purpose of this module is to give controlled, limited access to an application, 
rather than simply passing it a raw database handle through DBI. DBIx::Safe acts as 
a wrapper to the database, by only allowing through the commands you tell it to. It 
filters all things related to the database handle - methods and attributes.

The typical usage is for your application to create a database handle via a normal 
DBI call to new(), then pass that to DBIx::Safe->new(), which will return you a 
DBIx::Safe object. After specifying exactly what is and what is not allowed, you can 
pass the object to the untrusted application. The object will act very similar to a 
DBI database handle, and in most cases can be used interchangeably.

By default, nothing is allowed to run at all. There are many things you can control. 
You can specify which SQL commands are allowed, by indicating the first word in the 
SQL statement (e.g. 'SELECT'). You can specify which database methods are allowed to 
run (e.g. 'ping'). You can specify a regular expression that allows matching SQL 
statements to run (e.g. 'qr{SET TIMEZONE}'). You can specify a regular expression 
that is NOT allowed to run (e.g. qr(UPDATE xxx}). Finally, you can indicate which 
database attributes are allowed to be read and changed (e.g. 'PrintError'). For all 
of the above, there are matching methods to remove them as well.

=head2 Deciding what statements to allow

Anytime a statement is sent to the server via the DBIx::Safe database handle, it is first 
examined to see if it is allowed to run or not. There are three major checks that occur 
when a statement is sent. First, the initial word of the statement, known as the command, 
is extracted. Next, the entire statement is checked against the list of denied regular expressions. 
Next, the command is checked against the list of allowed commands. If there is no match, 
the statement is checked against the list of allowed regular expressions.

Each DBD may implement additional or slightly different checks. For example, if using 
Postgres, no semi-colons are allowed unless the command is one of SELECT, INSERT, 
UPDATE, or DELETE, to prevent multiple commands from running. (The four listed commands 
can be checked in another way for multiple commands, so they are allowed to have 
semicolons).

=head2 Deciding what attributes to allow

Database handle attributes are controlled by a single list of allowed keys. If the 
key is allowed, the underlying database handle value is returned or changed (or both). 
Note that the attribute "AutoCommit" is never allowed to be changed.

=head2 Methods

=head3 new()

Creates a new DBIx::Safe object. Requires a mandatory "dbh" argument containing an active database 
handle. Optional arguments are "allow_command", "allow_regex", "deny_regex", and "allow_attribute".

=head3 allow_command()

Specifies which commands are allowed to be used. Can be a whitespace-separated list of words in a string, 
or an arrayref of such strings. Returns the current list of allowed commands. Duplicate commands will 
throw an error.

=head3 unallow_command()

Same as allow_command, but will remove words from the list.

=head3 allow_regex()

Specifies regular expressions which are allowed to run. Argument must be a regular expression, 
or an arrayref of regular expressions. Returns the current list.

=head3 unallow_regex()

Same as allow_regex, but will remove regexes from the list.

=head3 deny_regex()

Specifies regular expressions which are NOT allowed to run. Arguments and return the same as allow_regex().

=head3 undeny regex()

Same as deny_regex, but will remove regexes from the list.

=head3 allow_attribute()

Specifies database handle attributes that are allowed to be changed. By default, nothing can be read.
Argument is a whitespace-separated list of words in a string, or an arrayref of such strings. Returns 
the current list.

=head3 unallow_attribute()

Same as allow_attributes, but removes attributes from the list.

=head2 Testing

DBIx::Safe has a very comprehensive test suite, so please use it! The only thing you should need is a 
database connection, by setting the environment variables DBI_DSN and DBI_USER (and DBI_PASS if needed).

You can optionally run the module through Perl::Critic by setting the TEST_AUTHOR environment variable.
You will need to have the modules Perl::Critic and Test::Perl::Critic installed.

Please report any test failures to the author or bucardo-general@bucardo.org.

=head2 Supported Databases

Due to the difficulty of ensuring safe access to the database, each type of database must be specifically 
written into DBIx::Safe. Current databases supported are: Postgres (DBD::Pg).

=head1 WEBSITE

The latest version and other information about DBIx::Safe can be found at:
http://bucardo.org/dbix_safe/

=head1 DEVELOPMENT

The latest development version can be checked out by using git:

  git clone http://bucardo.org/dbixsafe.git/

=head1 BUGS

Bugs should be reported to the author or bucardo-general@bucardo.org.

=head1 AUTHOR

Greg Sabino Mullane <greg@endpoint.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2006-2007 Greg Sabino Mullane <greg@endpoint.com>.

This software is free to use: see the LICENSE file for details.

=cut
