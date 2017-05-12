package DBIx::Pg::CallFunction;
our $VERSION = '0.019';
use 5.008;

=head1 NAME

DBIx::Pg::CallFunction - Simple interface for calling PostgreSQL functions from Perl

=head1 VERSION

version 0.019

=head1 SYNOPSIS

    use DBI;
    use DBIx::Pg::CallFunction;

    my $dbh = DBI->connect("dbi:Pg:dbname=joel", 'joel', '');
    my $pg = DBIx::Pg::CallFunction->new($dbh);

Returning single-row single-column values:

    my $userid = $pg->get_userid_by_username({'username' => 'joel'});
    # returns scalar 123

Returning multi-row single-column values:

    my $hosts = $pg->get_user_hosts({userid => 123});
    # returns array ref ['127.0.0.1', '192.168.0.1', ...]

Returning single-row multi-column values:

    my $user_details = $pg->get_user_details({userid => 123});
    # returns hash ref { firstname=>..., lastname=>... }

Returning multi-row multi-column values:

    my $user_friends = $pg->get_user_friends({userid => 123});
    # returns array ref of hash refs [{ userid=>..., firstname=>..., lastname=>...}, ...]

=head1 DESCRIPTION

This module provides a simple efficient way to call PostgreSQL functions
with from Perl code. It only support functions with named arguments, or
functions with no arguments at all. This limitation reduces the mapping
complexity, as multiple functions in PostgreSQL can share the same name,
but with different input argument types.

Please see L<pg_proc_jsonrpc.psgi> for an example on how to use this module.

=head1 CONSTRUCTOR METHODS

The following constructor methods are available:

=over 4

=item my $pg = DBIx::Pg::CallFunction->new($dbh, [$hashref])

This method constructs a new C<DBIx::Pg::CallFunction> object and returns it.

$dbh is a handle to your database connection.

$hashref is an optional reference to a hash containing configuration parameters.
If it not present, the default values will be used.

=back

=head2 CONFIGURATION PARAMETERS

The following configuration parameters are available:

=over 4

=item EnableFunctionLookupCache

When enabled, the procedure returns set for each function will be cached.
This is disabled by default.

=item RaiseError

By default, this is enabled. It is used like L<DBI/RaiseError>.

=back

=head1 REQUEST METHODS

=over 4

=item my $output = $pg->$name_of_stored_procedure($hashref_of_input_arguments)

=item my $output = $pg->$name_of_stored_procedure($hashref_of_input_arguments, $namespace)

=back

=head1 SEE ALSO

This module is built on top of L<DBI>, and
you need to use that module (and the appropriate DBD::Pg driver)
to establish a database connection.

There is another module providing about the same functionality,
but without support for named arguments for PostgreSQL.
Have a look at this one if you need to access functions
without named arguments, or if you are using Oracle:

L<DBIx::ProcedureCall|DBIx::ProcedureCall>

=head1 LIMITATIONS

Requires PostgreSQL 9.0 or later.
Only supports stored procedures / functions with
named input arguments.

=head1 AUTHOR

Joel Jacobson L<http://www.joelonsql.com>

=head1 COPYRIGHT

Copyright (c) Joel Jacobson, Sweden, 2012. All rights reserved.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

use strict;
use warnings;

use Carp;
use DBI;

our $AUTOLOAD;

sub new
{
    my $class = shift;
    my $self =
    {
        dbh => shift,
        RaiseError => 1,
        EnableFunctionLookupCache => 0,

        prosetret_cache => {}
    };

    my $params = shift;
    if (defined $params)
    {
        $self->{RaiseError} = delete $params->{RaiseError} if exists $params->{RaiseError};
        $self->{EnableFunctionLookupCache} = delete $params->{EnableFunctionLookupCache} if exists $params->{EnableFunctionLookupCache};

        # If there were any unrecognized parameters left, report one of them
        if (scalar keys %{$params} > 0)
        {
            my $param = shift @{keys %{$params}};
            croak "unrecognized parameter $param";
        }
    }

    bless $self, $class;
    return $self;
}

sub set_dbh
{
    my ($self, $dbh) = @_;
    $self->{dbh} = $dbh;
}

sub AUTOLOAD
{
    my $self      = shift;
    my $args      = shift;
    my $namespace = shift;
    my $name   = $AUTOLOAD;
    return if ($name =~ /DESTROY$/);
    $name =~ s!^.*::([^:]+)$!$1!;
    return $self->_call($name, $args, $namespace);
}

# Calculates a cache key for a function, given its signature.
#
# The caller should sort  $argnames  before passing them to us.
sub _calculate_proretset_cache_key
{
    my ($self, $name, $argnames, $namespace) = @_;

    return (defined $namespace ? $namespace : "").".".
            $name."(".join(",", @{$argnames}).")";
}


# Because there is no way for us to do "proper" cache invalidation, we have to
# rely on detecting the SQLSTATEs of the cases where the cache entry might be
# stale.  Currently, these cases are:
#
#   1) A cached function gets dropped.  (SQLSTATE undefined_function)
#   2) A new function with the same signature is introduced (SQLSTATE
#      ambiguous_function)
sub _invalidate_proretset_cache_entry
{
    my ($self, $name, $argnames, $namespace) = @_;

    my $cachekey = $self->_calculate_proretset_cache_key($name, $argnames, $namespace);
    delete $self->{proretset_cache}->{$cachekey};
}

sub _proretset
{
    # Returns the value of pg_catalog.pg_proc.proretset for the function.
    # "proretset" is short for procedure returns set.
    # If 1, the function returns multiple rows, or zero rows.
    # If 0, the function always returns exactly one row.
    my ($self, $name, $argnames, $namespace) = @_;

    my $cachekey = undef;

    # do a cache lookup if the caller asked for that
    if ($self->{EnableFunctionLookupCache})
    {
        $cachekey = $self->_calculate_proretset_cache_key($name, $argnames, $namespace);
        if (exists ($self->{proretset_cache}->{$cachekey}))
        {
            my $cached = $self->{proretset_cache}->{$cachekey};
            return $cached;
        }
    }

    my $get_proretset;
    if (@$argnames == 0)
    {
        # no arguments
        $get_proretset = $self->{dbh}->prepare_cached("
            SELECT pg_catalog.pg_proc.proretset
            FROM pg_catalog.pg_proc
            INNER JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid = pg_catalog.pg_proc.pronamespace)
            WHERE (?::text IS NULL OR pg_catalog.pg_namespace.nspname = ?::text)
            AND pg_catalog.pg_proc.proname = ?::text
            AND pg_catalog.pg_proc.pronargs = 0
        ");
        $get_proretset->execute($namespace,$namespace,$name);
    }
    else
    {
        $get_proretset = $self->{dbh}->prepare_cached("
            WITH
            -- Unnest the proargname and proargmode
            -- arrays, so we get one argument per row,
            -- allowing us to select only the IN
            -- arguments and build new arrays.
            NamedInputArgumentFunctions AS (
                -- For functions with INOUT/OUT arguments,
                -- proargmodes is an array where each
                -- position matches proargname and
                -- indicates if its an IN, OUT or INOUT
                -- argument.
                SELECT
                    pg_catalog.pg_proc.oid,
                    pg_catalog.pg_proc.proname,
                    pg_catalog.pg_proc.proretset,
                    pg_catalog.pg_proc.pronargdefaults,
                    unnest(pg_catalog.pg_proc.proargnames) AS proargname,
                    unnest(pg_catalog.pg_proc.proargmodes) AS proargmode
                FROM pg_catalog.pg_proc
                INNER JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid = pg_catalog.pg_proc.pronamespace)
                WHERE (?::name IS NULL OR pg_catalog.pg_namespace.nspname = ?::name)
                AND pg_catalog.pg_proc.proname = ?::name
                AND pg_catalog.pg_proc.proargnames IS NOT NULL
                AND pg_catalog.pg_proc.proargmodes IS NOT NULL
            ),
            OnlyINandINOUTArguments AS (
                -- Select only the IN and INOUT
                -- arguments and build new arrays
                SELECT
                    oid,
                    proname,
                    proretset,
                    pronargdefaults,
                    array_agg(proargname) AS proargnames
                FROM NamedInputArgumentFunctions
                WHERE proargmode IN ('i','b')
                GROUP BY
                    oid,
                    proname,
                    proretset,
                    pronargdefaults
                UNION ALL
                -- For functions with only IN arguments,
                -- proargmodes IS NULL
                SELECT
                    pg_catalog.pg_proc.oid,
                    pg_catalog.pg_proc.proname,
                    pg_catalog.pg_proc.proretset,
                    pg_catalog.pg_proc.pronargdefaults,
                    pg_catalog.pg_proc.proargnames
                FROM pg_catalog.pg_proc
                INNER JOIN pg_catalog.pg_namespace ON (pg_catalog.pg_namespace.oid = pg_catalog.pg_proc.pronamespace)
                WHERE (?::name IS NULL OR pg_catalog.pg_namespace.nspname = ?::name)
                AND pg_catalog.pg_proc.proname = ?::name
                AND pg_catalog.pg_proc.proargnames IS NOT NULL
                AND pg_catalog.pg_proc.proargmodes IS NULL
            )
            -- Find any function matching the name
            -- and having identical argument names
            SELECT * FROM OnlyINandINOUTArguments
            WHERE ?::text[] <@ proargnames AND ((
                -- No default arguments
                pronargdefaults = 0 AND ?::text[] @> proargnames
            ) OR (
                -- Default arguments, only require first input arguments to match
                pronargdefaults > 0 AND ?::text[] @> proargnames[
                    1
                    :
                    array_upper(proargnames,1) - pronargdefaults
                ]
            ))
            -- The order of arguments doesn't matter,
            -- so compare the arrays by checking
            -- if A contains B and B contains A
        ") or croak "failed to prepare get_proretset query";
        $get_proretset->execute($namespace, $namespace, $name, $namespace, $namespace, $name, $argnames, $argnames, $argnames)
            or croak("failed to execute get_proretset query: " . $get_proretset->errstr);
    }


    my $proretset;
    my $i = 0;
    while (my $h = $get_proretset->fetchrow_hashref()) {
        $i++;
        $proretset = $h;
    }
    if ($i == 0)
    {
        croak "no function matches the input arguments, function: $name";
    }
    elsif ($i == 1)
    {
        # The function exists and can be called.  Add it to the cache if the
        # caller has asked for caching.
        $self->{proretset_cache}->{$cachekey} = $proretset->{proretset} if ($self->{EnableFunctionLookupCache});

        return $proretset->{proretset};
    }
    else
    {
        croak "multiple functions matches the same input arguments, function: $name";
    }
}

sub _call
{
    my ($self,$name,$args,$namespace) = @_;

    my $validate_name_regex = qr/^[a-zA-Z_][a-zA-Z0-9_]*$/;

    unless (defined $args)
    {
        $args = {};
    }

    croak "dbh and name must be defined" unless defined $self->{dbh} && defined $name;
    croak "invalid format of namespace" unless !defined $namespace || $namespace =~ $validate_name_regex;
    croak "invalid format of name" unless $name =~ $validate_name_regex;
    croak "args must be a hashref" unless ref $args eq 'HASH';

    my @arg_names = sort keys %{$args};
    my @arg_values = @{$args}{@arg_names};

    foreach my $arg_name (@arg_names)
    {
        if ($arg_name !~ $validate_name_regex)
        {
            croak "invalid format of argument name: $arg_name";
        }
    }

    my $proretset = $self->_proretset($name, \@arg_names, $namespace);

    my $placeholders = join ",", map { "$_ := ?" } @arg_names;
    my $sql = 'SELECT * FROM ' . (defined $namespace ? "$namespace.$name" : $name) . '(' . $placeholders . ');';

    local $self->{dbh}->{RaiseError} = 0;
    my $query = $self->{dbh}->prepare($sql);


    # reset the error information
    $self->{SQLState} = '00000';
    $self->{SQLErrorMessage} = undef;

    my $failed = !defined $query->execute(@arg_values);

    # If something went wrong, we might have to invalidate the cache entry for
    # this function.
    if ($failed && $self->{EnableFunctionLookupCache})
    {
        # List of SQLSTATEs that warrant cache invalidation.  See
        # _invalidate_proretset_cache_entry() for more information and
        # http://www.postgresql.org/docs/current/static/errcodes-appendix.html
        # for a list of error codes.
        #
        # Unfortunately there is no way to reliably tell whether our call or
        # something in the function we called caused the error.  However, for
        # our use case it doesn't really matter since in the worst case that
        # would only mean unnecessary invalidations for functions that are
        # already slow to run because they're broken.
        my @sqlstates = (
                            "42883", # undefined function
                            "42725"  # ambiguous function
                        );

        $self->_invalidate_proretset_cache_entry($name, \@arg_names, $namespace)
            if ((scalar grep { $_ eq $query->state } @sqlstates) > 0);
    }


	if ($failed && $self->{RaiseError})
	{
		croak "Call to $name failed: $DBI::errstr";
	}
	elsif ($failed)
	{
		# if we failed but RaiseError wasn't set, let the caller deal with the problem
		$self->{SQLState} = $query->state;
		$self->{SQLErrorMessage} = $query->errstr;
		return undef;
	}

    my $output;
    my $num_cols;
    my @output_columns;
    for (my $row_number=0; my $h = $query->fetchrow_hashref(); $row_number++)
    {
        if ($row_number == 0)
        {
            @output_columns = sort keys %{$h};
            $num_cols = scalar @output_columns;
            croak "no columns in return" unless $num_cols >= 1;
        }
        if ($proretset == 0)
        {
            # single-row
            croak "function returned multiple rows" if defined $output;
            if ($num_cols == 1)
            {
                # single-column
                $output = $h->{$output_columns[0]};
            }
            elsif ($num_cols > 1)
            {
                # multi-column
                $output = $h;
            }
        }
        elsif ($proretset == 1)
        {
            # multi-row
            if ($num_cols == 1)
            {
                # single-column
                push @$output, $h->{$output_columns[0]};
            }
            elsif ($num_cols > 1)
            {
                # multi-column
                push @$output, $h;
            }
        }
    }
    return $output;
}

1;

=begin Pod::Coverage

new

=end Pod::Coverage

# vim: ts=8:sw=4:sts=4:et
