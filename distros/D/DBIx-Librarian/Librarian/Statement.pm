package DBIx::Librarian::Statement;

require 5.005;
use strict;
use base qw(Class::Virtual);
use vars qw($VERSION);
$VERSION = '0.4';

use Carp;
use Time::HiRes qw( gettimeofday tv_interval );

use Log::Channel;
{
    my $execlog = new Log::Channel "exec";
    sub execlog { $execlog->(@_) }
    my $perflog = new Log::Channel "perf";
    sub perflog { $perflog->(@_) }
    my $rowlog = new Log::Channel "rows";
    sub rowlog { $rowlog->(@_) }
    my $bindlog = new Log::Channel "bind";
    sub bindlog { $bindlog->(@_) }
}

__PACKAGE__->virtual_methods(qw(fetch));

=head1 NAME

DBIx::Librarian::Statement - an active SQL statement in a Librarian

=head1 SYNOPSIS

Internal class used by DBIx::Librarian.  Implementation of BUILDER
pattern (Librarian is the Director, Statement is the Builder).

Recognizes the following extensions to the SQL SELECT directive:

    SELECT*	return zero or more rows as an array
    SELECT?	return zero or one rows as a scalar
    SELECT1	return exactly one row as a scalar

For the SELECT? and SELECT1 flavors, an exception will be raised if
more than one row is returned.  For the SELECT1 flavor, an exception
will be raised if no rows are found.

The default behavior for an unadorned SELECT is multi-row SELECT*.

=head1 METHODS

=cut

my %select_mode = (
		   "*"	=> "SelectMany",
		   "?"	=> "SelectOne",
		   "1"	=> "SelectExactlyOne",
		   ""	=> "SelectMany",
		  );

=item B<new>

  my $stmt = new DBIx::Librarian::Statement ($dbh, $sql);

Prepares the SQL statement in $sql against the database connection
in $dbh.  Handles bind variables and direct substitution.

=cut

sub new {
    my ($proto, $dbh, $sql, %config) = @_;

    my $class = ref ($proto) || $proto;
    my $self = {
		DBH => $dbh
	       };
    while (my ($key, $val) = each %config) {
	$self->{$key} = $val;
    }


    # WARNING: Oracle does not like ? placeholders inside comments.
    #   If Statement thinks that the ? in the comment is a bind value
    #   and includes a value for it in the execute() list, Oracle receives
    #   more values than it expects.
    #   mysql seems to handle this correctly.
    #   May need to strip comments from SQL before converting placeholders.
    #   Yuck.  Is there a cross-platform way to do this?


    my @bindvars = $sql =~ /[^A-Za-z0-9:]:([[:word:].]+)/mog;
    if (@bindvars) {
	$sql =~ s/([^A-Za-z0-9:]):[[:word:].]+/$1?/og;
    }
    $self->{BINDVARS} = \@bindvars;

    if ($sql =~ /^select/io) {
	my ($mode) = $sql =~ /^select(\S*)/io;

	croak "Unrecognized select mode $mode in\n$sql\n"
	  unless $select_mode{$mode};

	# delegate SELECT processing based on expected rows returned

	$class = __PACKAGE__ . "::$select_mode{$mode}";
	my $classpath = $class;
	$classpath =~ s{::}{/}g;
	require "$classpath.pm";

	$sql =~ s/^select\S*/select/io;

	$self->{IS_SELECT} = 1;
    }


    bless ($self, $class);


    my @directvars;
    if ($sql =~ /\$\w+/o) {
	# requires on-demand parsing
	@directvars = $sql =~ /\$(\w+)/og;
	$self->{DIRECTVARS} = \@directvars;
#	$self->{SQL} = $sql;
    }
    else {
	# can prepare in advance
	$self->_prepare($sql);
    }

    $self->{SQL} = $sql;

    return $self;
}


sub _prepare {
    my ($self, $sql) = @_;

    execlog "PREPARE SQL:\n", $sql, "\n====================\n";

    my $sth = $self->{DBH}->prepare($sql);
    if (!$sth) {
	croak $self->{DBH}->errstr;
    }
    $self->{STH} = $sth;
}


=item B<execute>

  $stmt->execute($data);

Returns the number of rows affected for INSERTs, UPDATEs and DELETES;
zero for SELECTs.
Croaks on any database error or if any SELECT criteria are violated.

=cut

sub execute {
    my ($self, $data) = @_;

    execlog "EXECUTE SQL:\n", $self->{SQL}, "\n==========\n";

    $self->_substitutions($data);

    my @bindlist = $self->_bind($data);

    if ($self->{IS_SELECT} && !$data) {
	# caller(0) gives this line here in Statement.pm
	# caller(1) gives line in _execute() in Librarian.pm
	# caller(2) gives line in execute() in Librarian.pm
	# caller(3) gives the application code invoking Librarian::execute()
	my (undef, $filename, $line) = caller(3);
	croak "Missing required data parameter for SQL execute(\"$self->{NAME}\")\n at $filename line $line\n";
    }

    my $t0 = [ gettimeofday ];

    if (! $self->{STH}->execute(@bindlist)) {
	croak $self->{DBH}->errstr. " in SQL\n$self->{STH}->{Statement}\n";
    }

    my $elapsed = tv_interval ($t0, [ gettimeofday ]);
    perflog "ELAPSED TIME: ", $elapsed, "\n";

    my $rows;
    if ($self->{IS_SELECT}) {
	$rows = $self->fetch($data);
	rowlog "ROWS RETRIEVED: ", $rows, "\n";
    }
    else {
	rowlog "ROWS ALTERED: ", $self->{STH}->rows, "\n";
	$rows = $self->{STH}->rows;
    }

    return $rows;
}


sub _substitutions {
    my ($self, $data) = @_;

    return unless $self->{DIRECTVARS};

    # The SQL contains "$parameter" substitutions.
    # Must be re-prepared before every execution.

    my $sql = $self->{SQL};
    foreach my $directvar (@{$self->{DIRECTVARS}}) {
	my $val;
	if ($self->{ALLARRAYS}) {
	    $val = $data->{$directvar}[0];
	} else {
	    croak "Expected scalar for $directvar" if ref($data->{$directvar});
	    $val = $data->{$directvar};
	}
	bindlog sprintf ("\tSUB \$%s = %s\n",
			 $directvar,
			 $val || '(null)');
	$sql =~ s/\$$directvar(\W|$)/$val$1/g;
    }

    my $sth = $self->{DBH}->prepare($sql);
    if (!$sth) {
	croak $self->{DBH}->errstr . " in SQL\n$sql\n";
    }
    $self->{STH} = $sth;
}


sub _bind {
    my ($self, $data) = @_;

    return unless $self->{BINDVARS};

    # The SQL contains ":parameter" placeholders, which have already
    # been converted to standard ? markers by prepare().  Pull the
    # list of bind variables.

    my @bindlist;

    foreach my $bindvar (@{$self->{BINDVARS}}) {
	my $val;
	my $node = $data;
	my $key = $bindvar;
	while ($key =~ /\./) {
	    # drill down into the hierarchy as needed to find sub-elements
	    my ($base, $subkey) = $key =~ /(.*?)\.(.*)/;
	    croak "Expected scalar for $key" if !defined $node->{$base} || !ref($node->{$base});
	    $node = $node->{$base};
	    $key = $subkey;
	}
	if ($self->{ALLARRAYS}) {
	    $val = $node->{$key}[0];
	} else {
	    croak "Expected scalar for $key" if ref($data->{$key});
	    $val = $node->{$key};
	}

	bindlog sprintf ("\tBIND :%s = %s\n",
			 $bindvar,
			 $val || '(null)');
	push @bindlist, $val;
    }

    return @bindlist;
}

1;

=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2001-2003 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
