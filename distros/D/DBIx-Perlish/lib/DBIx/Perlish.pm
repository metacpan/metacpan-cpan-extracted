package DBIx::Perlish;

use 5.014;
use warnings;
use strict;
use Carp;

use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS $SQL @BIND_VALUES);
require Exporter;
use base 'Exporter';
use Keyword::Pluggable;

$VERSION = '1.03';
@EXPORT = qw(sql);
@EXPORT_OK = qw(union intersect except subselect);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use DBIx::Perlish::Parse;

sub union (&;$) {}
sub intersect (&;$) {}
sub except (&;$) {}
sub subselect (&) {}

my $default_object;
my $non_object_quirks = {};

sub optree_version
{
	return 1 if $^V lt 5.22.0;
	return 2;
}

sub lexify
{
	my ( $text, $insert ) = @_;
	$insert .= 'sub ' if $$text =~ /^\s*\{/;
	substr($$text, 0, 0, $insert);
}

sub import
{
	my $pkg = caller;
	local @EXPORT_OK = @EXPORT_OK;
	local %EXPORT_TAGS = %EXPORT_TAGS;
	if ($pkg && $pkg->can("except")) {
		# XXX maybe check prototype here
		pop @EXPORT_OK;
		%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);
	}
	my @shift;
	@shift = (shift()) if @_ % 2;
	my %p = @_;
	if ($p{prefix} && $p{prefix} =~ /^[a-zA-Z_]\w*$/) {
		no strict 'refs';
		if ( $p{dbh} && ref $p{dbh} && (ref $p{dbh} eq "SCALAR" || ref $p{dbh} eq "REF")) {
			my $dbhref = $p{dbh};
			*{$pkg."::$p{prefix}_fetch"} =
			*{$pkg."::$p{prefix}_select"} =
				sub (&) { my $o = DBIx::Perlish->new(dbh => $$dbhref); $o->fetch(@_) };
			*{$pkg."::$p{prefix}_update"} =
				sub (&) { my $o = DBIx::Perlish->new(dbh => $$dbhref); $o->update(@_) };
			*{$pkg."::$p{prefix}_delete"} =
				sub (&) { my $o = DBIx::Perlish->new(dbh => $$dbhref); $o->delete(@_) };
			*{$pkg."::$p{prefix}_insert"} =
				sub { my $o = DBIx::Perlish->new(dbh => $$dbhref); $o->insert(@_) };
			return;
		}
	}

	my $prefix = delete($p{prefix}) // 'db';
	my $dbh    = delete($p{dbh}) // '$dbh';
	my $iprefix = '__' . $dbh . '_execute_perlish';
	$iprefix =~ s/\W//g;

	for (
		[fetch  => " $dbh, q(fetch), "],
		[select => " $dbh, q(fetch), "],
		[update => " $dbh, q(update), "],
		[delete => " $dbh, q(delete), "],
	) {	
		my ($name, $code) = @$_;
		Keyword::Pluggable::define
			keyword    => $prefix . '_' . $name, 
			code       => sub { lexify( $_[0], $iprefix.$code ) },
			expression => 1,
			package    => $pkg
		;
	}
	Keyword::Pluggable::define
		keyword    => $prefix . '_insert',
		code       => $iprefix . "_insert $dbh, ",
		expression => 1,
		package    => $pkg
	;

	{
		no strict 'refs';
		*{$pkg."::${iprefix}"} = sub ($$&) { 
			my ( $dbh, $method, $sub ) = @_;
			my $o = DBIx::Perlish->new(dbh => $dbh); 
			$o->$method($sub);
		};
		*{$pkg."::${iprefix}_insert"} = sub { 
			my $o = DBIx::Perlish->new(dbh => shift);
			$o->insert(@_)
		};
	}
	DBIx::Perlish->export_to_level(1, @shift, %p);
}

sub init { warn "DBIx::Perlish::init is deprecated" }

sub new
{
	my ($class, %p) = @_;
	unless (UNIVERSAL::isa($p{dbh}, "DBI::db")) { # XXX maybe relax for other things?
		die "Invalid database handle supplied in the \"dbh\" parameter.\n";
	}
	my $me = bless { dbh => $p{dbh}, quirks => {} }, $class;
	if ($p{quirks} && ref $p{quirks} eq "ARRAY") {
		for my $q (@{$p{quirks}}) {
			$me->quirk(@$q);
		}
	}
	return $me;
}

sub quirk
{
	my $flavor = shift;
	my $quirks = $non_object_quirks;
	if (ref $flavor) {
		$quirks = $flavor->{quirks};
		$flavor = shift;
	}
	$flavor = lc $flavor;
	if ($flavor eq "oracle") {
		my $qtype = shift;
		if ($qtype eq "table_func_cast") {
			my ($func, $cast) = @_;
			die "table_func_cast requires a function name and a type name" unless $cast;
			$quirks->{oracle_table_func_cast}{$func} = $cast;
		} else {
			die "unknown quirk $qtype for $flavor";
		}
	} else {
		die "there are currently no quirks for $flavor";
	}
}

sub _get_flavor
{
	my ($real_dbh) = @_;
	my $dbh = tied(%$real_dbh) || $real_dbh;
	return lc $dbh->{Driver}{Name};
}

sub gen_sql_select
{
	my ($moi, $sub) = @_;
	my $me = ref $moi ? $moi : {};

	my $dbh = $me->{dbh};
	my @kf;
	my $flavor = _get_flavor($dbh);
	my $kf_convert = sub { return $_[0] };
	if ($flavor eq "pg" && $dbh->{FetchHashKeyName}) {
		if ($dbh->{FetchHashKeyName} eq "NAME_uc") {
			$kf_convert = sub { return uc $_[0] };
		} elsif ($dbh->{FetchHashKeyName} eq "NAME_lc") {
			$kf_convert = sub { return lc $_[0] };
		}
	}
	my ($sql, $bind_values, $nret, %flags) = gen_sql($sub, "select", 
		flavor     => $flavor,
		dbh        => $dbh,
		quirks     => $me->{quirks} || $non_object_quirks,
		key_fields => \@kf,
		kf_convert => $kf_convert,
	);
	$flags{key_fields} = \@kf if @kf;
	return $sql, $bind_values, $nret, %flags;
}

sub query
{
	my ($moi, $sub) = @_;
	my $me = ref $moi ? $moi : {};
	my ( $sql ) = $moi->gen_sql_select($sub);
	return $sql;
}

sub fetch
{
	my ($moi, $sub) = @_;
	my $me = ref $moi ? $moi : {};

	my $nret;
	my $dbh = $me->{dbh};
	my %flags;

	($me->{sql}, $me->{bind_values}, $nret, %flags) = $me->gen_sql_select($sub);
	$SQL = $me->{sql}; @BIND_VALUES = @{$me->{bind_values}};

	if ($flags{key_fields}) {
		my @kf = @{ $flags{key_fields} // [] };
		my $kf = @kf == 1 ? $kf[0] : [@kf];
		my $r = $dbh->selectall_hashref($me->{sql}, $kf, {}, @{$me->{bind_values}}) || {};
		my $postprocess;
		if ($nret - @kf == 1) {
			# Only one field returned apart from the key field,
			# change hash reference to simple values.
			$postprocess = sub {
				my ($h, $level) = @_;
				if ($level <= 1) {
					delete @$_{@kf} for values %$h;
					$_ = (values %$_)[0] for values %$h;
				} else {
					for my $nh (values %$h) {
						$postprocess->($nh, $level-1);
					}
				}
			};
		} else {
			$postprocess = sub {
				my ($h, $level) = @_;
				if ($level <= 1) {
					delete @$_{@kf} for values %$h;
				} else {
					for my $nh (values %$h) {
						$postprocess->($nh, $level-1);
					}
				}
			};
		}
		$postprocess->($r, scalar @kf);
		return wantarray ? %$r : $r;
	} else {
		if ($nret > 1) {
			my $r = $dbh->selectall_arrayref($me->{sql}, {Slice=>{}}, @{$me->{bind_values}}) || [];
			return wantarray ? @$r : $r->[0];
		} else {
			my $r = $dbh->selectcol_arrayref($me->{sql}, {}, @{$me->{bind_values}}) || [];
			return wantarray ? @$r : $r->[0];
		}
	}
}

# XXX refactor update/delete into a single implemention if possible?
sub update
{
	my ($moi, $sub) = @_;
	my $me = ref $moi ? $moi : {};

	my $dbh = $me->{dbh};
	($me->{sql}, $me->{bind_values}) = gen_sql($sub, "update",
		flavor => _get_flavor($dbh),
		dbh    => $dbh,
		quirks => $me->{quirks} || $non_object_quirks,
	);
	$SQL = $me->{sql}; @BIND_VALUES = @{$me->{bind_values}};
	$dbh->do($me->{sql}, {}, @{$me->{bind_values}});
}

sub delete
{
	my ($moi, $sub) = @_;
	my $me = ref $moi ? $moi : {};

	my $dbh = $me->{dbh};
	($me->{sql}, $me->{bind_values}) = gen_sql($sub, "delete",
		flavor => _get_flavor($dbh),
		dbh    => $dbh,
		quirks => $me->{quirks} || $non_object_quirks,
	);
	$SQL = $me->{sql}; @BIND_VALUES = @{$me->{bind_values}};
	$dbh->do($me->{sql}, {}, @{$me->{bind_values}});
}

sub insert
{
	my ($moi, $table, @rows) = @_;
	my $me = ref $moi ? $moi : {};

	my $dbh = $me->{dbh};
	my %sth;
	for my $row (@rows) {
		my @keys = sort keys %$row;
		my $sql = "insert into $table (";
		$sql .= join ",", @keys;
		$sql .= ") values (";
		my (@v, @b);
		my $skip_prepare;
		for my $v (@$row{@keys}) {
			if (ref $v eq 'CODE') {
				push @v, scalar $v->();
				$skip_prepare = 1;
			} else {
				push @v, "?";
				push @b, $v;
			}
		}
		$sql .= join ",", @v;
		$sql .= ")";
		if ($skip_prepare) {
			return undef unless defined $dbh->do($sql, {}, @b);
		} else {
			my $k = join ";", @keys;
			$sth{$k} ||= $dbh->prepare($sql);
			return undef unless defined $sth{$k}->execute(@b);
		}
	}
	return scalar @rows;
}

sub sql ($) {
	my $self = shift;
	if (ref $self && $self->isa("DBIx::Perlish")) {
		$self->{sql};
	} else {
		sub { $self }
	}
}
sub bind_values { $_[0]->{bind_values} ? @{$_[0]->{bind_values}} : () }

sub gen_sql
{
	my ($sub, $operation, %args) = @_;

	$args{quirks} = $non_object_quirks unless $args{quirks};
	my $S = DBIx::Perlish::Parse::init(%args, operation => $operation);
	DBIx::Perlish::Parse::parse_sub($S, $sub);
	my $sql = "";
	my $next_bit = "";
	my $nret = 9999;
	my $no_aliases;
	my $dangerous;
	my %flags;
	if ($operation eq "select") {
		my $nkf = 0;
		if ($S->{key_fields}) {
			$nkf = @{$S->{key_fields}};
			push @{$args{key_fields}}, @{$S->{key_fields}} if $args{key_fields};
		}
		$sql = "select ";
		$sql .= "distinct " if $S->{distinct};
		if ($S->{returns}) {
			$sql .= join ", ", @{$S->{returns}};
			$nret = @{$S->{returns}};
			for my $ret (@{$S->{returns}}) {
				$nret = 9999 if $ret =~ /\*/;
			}
			$flags{returns_dont_care} = 1 if
				1 == @{$S->{returns}} && 
				$S->{returns}->[0] =~ /^(.*)\.\*/ &&
				$S->{returns_dont_care}->{$1}
			;
		} else {
			$sql .= "*";
		}
		$next_bit = " from ";
		die "all returns are key fields, this is nonsensical\n" if $nkf == $nret;
	} elsif ($operation eq "delete") {
		$no_aliases = 1;
		$dangerous = 1;
		$next_bit = "delete from ";
	} elsif ($operation eq "update") {
		$no_aliases = 1;
		$dangerous = 1;
		$next_bit = "update ";
	} else {
		die "unsupported operation: $operation\n";
	}
	my %tabs;
	for my $var (keys %{$S->{vars}}) {
		$tabs{$S->{var_alias}->{$var}} =
			$no_aliases ?
				"$S->{vars}->{$var}" :
				"$S->{vars}->{$var} $S->{var_alias}->{$var}";
	}
	for my $tab (keys %{$S->{tabs}}) {
		$tabs{$S->{tab_alias}->{$tab}} =
			$no_aliases ?
				"$tab" :
				"$tab $S->{tab_alias}->{$tab}";
	}
	unless (keys %tabs) {
		if ($operation eq "select" && $S->{returns}) {
			if ($args{flavor} && $args{flavor} eq "oracle") {
				$tabs{dual} = "dual";
			} else {
				$next_bit = " ";
			}
		} else {
			die "no tables specified in $operation\n";
		}
	}
	$sql .= $next_bit;
	my %seentab;
	my $joins = "";
	for my $j ( @{$S->{joins}} ) {
		my ($join, $tab1, $tab2, $condition) = @$j;
		$condition = ( defined $condition) ? " on $condition" : '';
		die "not sure what to do with repeated tables ($tabs{$tab1} and $tabs{$tab2}) in a join\n"
			if $seentab{$tab1} && $seentab{$tab2};
		if ($seentab{$tab2}) {
			($tab1, $tab2) = ($tab2, $tab1);
			if ($join eq "left outer") {
				$join = "right outer";
			} elsif ($join eq "right outer") {
				$join = "left outer";
			}
		}
		if ($seentab{$tab1}) {
			$joins .= " " if $joins;
			$joins .= "$join join $tabs{$tab2}$condition";
		} else {
			$joins .= ", " if $joins;
			$joins .= "$tabs{$tab1} $join join $tabs{$tab2}$condition";
		}
		$seentab{$tab1}++;
		$seentab{$tab2}++;
	}
	my @joins = $joins ? ($joins) : ();
	$sql .= join ", ", @joins, map { $tabs{$_} } grep { !$seentab{$_} } sort keys %tabs;

	my @sets     = grep { $_ ne "" } @{$S->{sets}};
	my @where    = grep { $_ ne "" } @{$S->{where}};
	my @having   = grep { $_ ne "" } @{$S->{having}};
	my @group_by = grep { $_ ne "" } @{$S->{group_by}};
	my @order_by = grep { $_ ne "" } @{$S->{order_by}};

	if ($S->{autogroup_needed} && !$S->{no_autogroup} &&
		!@group_by && @{$S->{autogroup_by}})
	{
		@group_by = grep { $_ ne "" } @{$S->{autogroup_by}};
	}
	die "nothing to update\n" if $operation eq "update" && !@sets;

	$sql .= " set "      . join ", ",    @sets     if @sets;
	$sql .= " where "    . join " and ", @where    if @where;
	$sql .= " group by " . join ", ",    @group_by if @group_by;
	$sql .= " having "   . join " and ", @having   if @having;
	$sql .= " order by " . join ", ",    @order_by if @order_by;

	if ($dangerous && !@where && !$S->{seen_exec}) {
		die "unfiltered $operation is dangerous: use exec if you want it\n";
	}

	my $use_rownum = $args{flavor} && $args{flavor} eq "oracle";

	unless ($use_rownum) {
		if ($S->{limit}) {
			$sql .= " limit $S->{limit}";
		}
		if ($S->{offset}) {
			$sql .= " offset $S->{offset}";
		}
	}
	my $v = $S->{set_values};
	push @$v, @{$S->{ret_values}};
	push @$v, @{$S->{join_values}};
	push @$v, @{$S->{values}};

	for my $add (@{$S->{additions}}) {
		$sql .= " $add->{type} $add->{sql}";
		push @$v, @{$add->{vals}};
	}
	$sql =~ s/\s+$//;

	if ( $use_rownum && ( $S->{limit} || $S->{offset} )) {
		my @p;
		push @p, "ROWNUM > " . $S->{offset} if $S->{offset};
		push @p, "ROWNUM <= " . ($S->{limit} + ($S->{offset} // 0)) if $S->{limit};
		$sql = "select * from ($sql) where " . join(' and ', @p);
	}

	return ($sql, $v, $nret, %flags);
}


1;
__END__

=head1 NAME

DBIx::Perlish - a perlish interface to SQL databases

=head1 VERSION

This document describes DBIx::Perlish version 1.00


=head1 SYNOPSIS

    use DBI;
    use DBIx::Perlish;

    my $dbh = DBI->connect(...);

    # selects:
    my @rows = db_fetch {
        my $x : users;
        defined $x->id;
        $x->name !~ /\@/;
    };

    # sub-queries:
    my @rows = db_fetch {
        my $x : users;
        $x->id <- subselect {
            my $t2 : table1;
            $t2->col == 2 || $t2->col == 3;
            return $t2->user_id;
        };
        $x->name !~ /\@/;
    };

    # updates:
    db_update {
        data->num < 100;
        data->mutable;

        data->num = data->num + 1;
        data->name = "xyz";
    };

    # more updates:
    db_update {
        my $d : data;
        $d->num < 100, $d->mutable;

        $d = {
            num  => $d->num + 1,
            name => "xyz"
        };
    };

    # deletes:
    db_delete {
        my $t : table1;
        !defined $t->age  or
        $t->age < 18;
    };

    # inserts:
    my $id = 42;
    db_insert 'users', {
        id   => $id,
        name => "moi",
    };


=head1 DESCRIPTION

The C<DBIx::Perlish> module provides the ability to work with databases
supported by the C<DBI> module using Perl's own syntax for four most
common operations: SELECT, UPDATE, DELETE, and INSERT.

By using C<DBIx::Perlish>, you can write most of your database
queries using a domain-specific language with Perl syntax.
Since a Perl programmer knows Perl by definition,
and might not know SQL to the same degree, this approach
generally leads to a more comprehensible and maintainable
code.

The module is not intended to replace 100% of SQL used in your program.
There is a hope, however, that it can be used to replace
a substantial portion of it.

The C<DBIx::Perlish> module quite intentionally neither implements
nor cares about database administration tasks like schema design
and management.  The plain C<DBI> interface is quite sufficient for
that.  Similarly, and for the same reason, it does not take care of
establishing database connections or handling transactions.  All this
is outside the scope of this module.


=head2 Ideology

There are three sensible and semi-sensible ways of arranging code that
works with SQL databases in Perl:

=over

=item SQL sprinkling approach

One puts queries wherever one needs to do something with the database,
so bits and pieces of SQL are intermixed with the program logic.
This approach can easily become an incomprehensible mess that is difficult
to read and maintain.

=item Clean and tidy approach

Everything database-related is put into a separate module, or into a
collection of modules.  Wherever database access is required,
a corresponding sub or method from such a module is called from the
main program.  Whenever something is needed that the DB module does
not already provide, a new sub or method is added into it.

=item Object-relational mapping

One carefully designs the database schema and an associated collection
of classes, then formulates the design in terms of any of the existing
object-relational mapper modules like C<Class::DBI>, C<DBIx::Class>
or C<Tangram>, then uses objects which perform all necessary queries
under the hood.  This approach is even cleaner than "clean and tidy"
above, but it has other issues.  Some schemas do not map well into
the OO space.  Typically, the resulting performance is an issue
as well.  The performance issues can in some cases be alleviated
by adding hand-crafted SQL in strategic places, so in this regard
the object-relational mapping approach can resemble the "clean and tidy"
approach.

=back

The C<DBIx::Perlish> module is meant to eliminate the majority
of the "SQL sprinkling" style of database interaction.
It is also fully compatible with the "clean and tidy" method.

=head2 Procedural interface

=head3 db_fetch {}

The C<db_fetch {}> function queries and returns data from
the database.

The function parses the supplied query sub,
converts it into the corresponding SQL SELECT statement,
and executes it.

What it returns depends on two things: the context and the
return statement in the query sub, if any.

If there is a return statement which specifies exactly one
column, and C<db_fetch {}> is called in the scalar context,
a single scalar representing the requested column is returned
for the first row of selected data.  Example:

    my $somename = db_fetch { return user->name };

Borrowing DBI's terminology, this is analogous to

    my $somename =
        $dbh->selectrow_array("select name from user");

If there is a return statement which specifies exactly one
column, and C<db_fetch {}> is called in the list context,
an array containing the specified column for all selected
rows is returned.  Example:

    my @allnames = db_fetch { return user->name };

This is analogous to

    my @allnames =
        @{$dbh->selectcol_arrayref("select name from user")};

When there is no return statement, or if 
the return statement specifies multiple columns,
then an individual row is represented by a hash
reference with column names as the keys.

In the scalar context, a single hashref is returned, which
corresponds to the first row of selected data.  Example:

    my $h = db_fetch { my $u : user };
    print "name: $h->{name}, id: $h->{id}\n";

In DBI parlance that would look like

    my $h = $dbh->selectrow_hashref("select * from user");
    print "name: $h->{name}, id: $h->{id}\n";

In the list context, an array of hashrefs is returned,
one element for one row of selected data:

    my @users = db_fetch { my $u : user };
    print "name: $_->{name}, id: $_->{id}\n" for @users;

Again, borrowing from DBI, this is analogous to

    my @users = @{$dbh->selectall_arrayref("select * from user",
        {Slice=>{}})};
    print "name: $_->{name}, id: $_->{id}\n" for @users;

There is also a way to specify that one or several of
the return values are the B<key fields>, to obtain a behavior
similar to that of the DBI's C<selectall_hashref()> function.
A return value is a B<key field> if it is prepended with B<-k>:

    my %data = db_fetch {
        my $u : users;
        return -k $u->name, $u;
    };

This is somewhat analogous to

    my %data = %{$dbh->selectall_hashref(
      "select name, * from users", "name")};

If the C<db_fetch {}> containing key fields is called in the
scalar context, it returns a hash reference instead of a hash.
In both cases the complete result set is returned.

This is different from calling the C<db_fetch {}> without key fields
in the scalar context, which always returns a single row (or a single
value), as explained above.

The individual results in such a result set will be hash references
if the return statement specifies more than one column (not counting
the key fields), or a simple value if the return statement specifies
exactly one column in addition to the key fields.  For example,

   my %data = db_fetch {
      my $u : user;
      return -k $u->id, $u;
   };
   print "The name of the user with ID 42 is $data{42}{name}\n";

but:

   my %data = db_fetch {
      my $u : user;
      return -k $u->id, $u->name;
   };
   print "The name of the user with ID 42 is $data{42}\n";

In any case, the key fields themselves are never present in the result,
unless they were specified in the return statement independently.

The C<db_fetch {}> function will throw an exception if it is unable to
find a valid database handle to use, or if it is unable to convert its
query sub to SQL.

In addition, if the database handle is configured to throw exceptions,
the function might throw any of the exceptions thrown by DBI.

L</Subqueries> are permitted in db_fetch's query subs.

Please see L</Query sub syntax> below for details of the
syntax allowed in query subs.

The C<db_fetch {}> function is exported by default.

=head3 db_select {}

The C<db_select {}> function is an alias to the C<db_fetch {}>.
It is exported by default.

=head3 db_update {}

The C<db_update {}> function updates rows of a database table.

The function parses the supplied query sub,
converts it into the corresponding SQL UPDATE statement,
and executes it.

The function returns whatever DBI's C<do> method returns.

The function will throw an exception if it is unable to find
a valid database handle to use, or if it is unable to convert
its query sub to SQL.

In addition, if the database handle is configured to throw exceptions,
the function might throw any of the exceptions thrown by DBI.

A query sub of the C<db_update {}> function must refer
to precisely one table (not counting tables referred to
by subqueries).

Neither C<return> statements nor C<last> statements are
allowed in the C<db_update {}> function's query subs.

An attempt to call the C<db_update {}> function with
no filtering expressions in the query sub will throw
an exception since such is very likely a dangerous mistake.
To allow such an update to proceed, include an C<exec>
call with no parameters anywhere in the query sub.

L</Subqueries> are permitted in db_update's query subs.

Please see L</Query sub syntax> below for details of the
syntax allowed in query subs.

Examples:

    db_update {
        tbl->id == 41;
        tbl->id = tbl->id - 1;
        tbl->name = "luff";
    };

    db_update {
        tbl->id = 42;
		exec;  # without this an exception is thrown
    };

    db_update {
        my $t : tbl;
        $t->id == 40;
        $t = {
            id   => $t->id + 2,
            name => "LIFF",
        };
    };

    db_update {
        tbl->id == 40;
        tbl() = {
            id   => tbl->id + 2,
            name => "LIFF",
        };
    };

The C<db_update {}> function is exported by default.


=head3 db_delete {}

The C<db_delete {}> function deletes data from
the database.

The C<db_delete {}> function parses the supplied query sub,
converts it into the corresponding SQL DELETE statement,
and executes it.

The function returns whatever DBI's C<do> method returns.

The function will throw an exception if it is unable to find
a valid database handle to use, or if it is unable to convert
its query sub to SQL.

In addition, if the database handle is configured to throw exceptions,
the function might throw any of the exceptions thrown by DBI.

A query sub of the C<db_delete {}> function must refer
to precisely one table (not counting tables referred to
by subqueries).

Neither C<return> statements nor C<last> statements are
allowed in the C<db_delete {}> function's query subs.

An attempt to call the C<db_delete {}> function with
no filtering expressions in the query sub will throw
an exception since such is very likely a dangerous mistake.
To allow such a delete to proceed, include an C<exec>
call with no parameters anywhere in the query sub.

L</Subqueries> are permitted in db_delete's query subs.

Please see L</Query sub syntax> below for details of the
syntax allowed in query subs.

Examples:

    db_delete { $x : users; exec; } # delete all users

    # delete with a subquery
    db_delete {
        my $u : users;
        $u->name <- subselect {
            visitors->origin eq "Uranus";
            return visitors->name;
        }
    }

The C<db_delete {}> function is exported by default.


=head3 db_insert()

The C<db_insert()> function inserts rows into a
database table.

This function is different from the rest 
because it does not take a query sub as the parameter.

Instead, it takes a table name as its first parameter,
and any number of hash references afterwards.

For each specified hashref, a new row is inserted
into the specified table.  The resulting insert statement
specifies hashref keys as the column names, with corresponding
values taken from hashref values.  Example:

    db_insert 'users', { id => 1, name => "the.user" };

A value can be a call to the exported C<sql()> function,
in which case it is inserted verbatim into the generated
SQL, for example:

    db_insert 'users', {
        id => sql("some_seq.nextval"),
        name => "the.user"
    };

The function returns the number of insert operations performed.
If any of the DBI insert operations fail, the function returns
undef, and does not perform remaining inserts.

The function will throw an exception if it is unable to find
a valid database handle to use.

In addition, if the database handle is configured to throw exceptions,
the function might throw any of the exceptions thrown by DBI.

The C<db_insert {}> function is exported by default.

=head3 subselect()

This call, formerly known as as internal form of C<db_fetch>, 
is basically an SQL SELECT statement. See L</Subqueries>.

=head3 union()

This is a helper sub which is meant to be used inside
query subs.  Please see L</Compound queries' statements>
for details.  The C<union()> can be exported via C<:all>
import declaration.

=head3 intersect()

This is a helper sub which is meant to be used inside
query subs.  Please see L</Compound queries' statements>
for details.  The C<intersect()> can be exported via C<:all>
import declaration.

=head3 except()

This is a helper sub which is meant to be used inside
query subs.  Please see L</Compound queries' statements>
for details.  The C<except()> can be exported via C<:all>
import declaration.

=head3 quirk()

Unfortunately it is not always possible to generate an
SQL statement which is valid for different DBI drivers,
even when the C<DBIx::Perlish> module has the knowledge
about what driver is in use.

The C<quirk()> sub exists to alleviate this problem in
certain situations by registering "quirks".
Please avoid using it if possible.

It accepts at least two positional parameters.  The
first parameter is the DBI driver flavor.
The second parameter identifies a particular quirk.
The rest of parameters are quirk-dependent.

It is a fatal error to attempt to register a quirk that
is not recognized by the module.

Currently only Oracle has any quirks, which are listed
below:

=over

=item table_func_cast

When table functions are used in Oracle, one sometimes
gets an error
"ORA-22905: cannot access rows from a non-nested table item".
The solution recommended by Oracle is to do an explicit type
cast to a correct type.  Since the C<DBIx::Perlish> module
has no way of knowing what the correct type is, it needs
a little help.  The C<table_func_cast> quirk requires two extra
parameters, the name of a table function and the type to cast
it to.

=back


=head3 $SQL and @BIND_VALUES

The C<DBIx::Perlish> module provides two global variables
(not exported) to aid in debugging.
The C<$DBIx::Perlish::SQL> variable contains the text of 
the SQL which was generated during the most recent
invocation of one of C<db_fetch {}>, C<db_update {}>,
or C<db_delete {}>.
The C<@DBIx::Perlish::BIND_VALUES> array contains the bind values
to be used with the corresponding SQL code.


=head2 Query sub syntax

The important thing to remember is that although the query subs have Perl
syntax, they do B<not> represent Perl, but a specialized "domain specific"
database query language with Perl syntax.

A query sub can consist of the following types of statements:

=over

=item *

table variables declarations;

=item *

query filter statements;

=item *

return statements;

=item *

assignments;

=item *

result limiting and ordering statements;

=item *

conditional statements;

=item *

statements with label syntax;

=item *

compound queries' statements.

=back

The order of the statements is generally not important,
except that table variables have to be declared before use.

=head3 Table variables declarations

Table variables declarations allow one to associate
lexical variables with database tables.  They look
like this:

    my $var : tablename;

It is possible to associate several variables with the
same table;  this is the preferable mechanism if self-joins
are desired.

In case the table name is not known until runtime, it is also
possible to write for example

    my $var : table = $data->{tablename};

In this case the attribute "table" must be specified verbatim,
and the name of the table is taken from the right-hand side of the
assignment.

Database schemas ("schemaname.tablename") are supported in
several different ways:

=over

=item Using the runtime mechanism described above:

    my $tabnam = "schemaname.tablename";
    db_fetch {
        my $t : table = $tabnam;
    };

=item Using a similar verbatim "table" attribute with a string constant:

    my $t : table = "schemaname.tablename";

=item Using attribute argument with the verbatim "table" attribute:

    my $t : table(schemaname.tablename);

=item Using schema name as the attribute and table name as its argument:

    my $t : schemaname(tablename);

=back

Last, but not least, a combination of verbatim "table" attribute
with a nested L</subselect {}> can be used to implement I<inline views>:

    my $var : table = subselect { ... };

In this case a B<select> statement corresponding to
the nested L</subselect {}> will represent the table.
Please note that not all database drivers support
this, although at present the C<DBIx::Perlish> module
does not care and will generate SQL which will subsequently
fail to execute.

Another possibility for declaring table variables is
described in L</Statements with label syntax>.

Please note that L</db_update {}> and L</db_delete {}> must
only refer to a single table.

=head3 Query filter statements

Query filter statements have a general form of Perl expressions.
Binary comparison operators, logical "or" (both high and lower
precedence form), matching operators =~ and !~, binary arithmetic
operators, string concatenation, defined(expr),
and unary ! are all valid in the filters.
There is also a special back-arrow, "comes from" C<E<lt>-> binary
operator used for matching a column to a set of values, and for
subqueries.

Individual terms can refer to a table column using dereferencing
syntax
(one of C<tablename-E<gt>column>,
C<$tablevar-E<gt>column>,
C<tablename-E<gt>$varcolumn>, or
C<$tablevar-E<gt>$varcolumn>),
to an integer, floating point, or string constant, to a function
call, to C<next> statement with an argument,
or to a scalar value in the outer scope (simple scalars,
hash elements, or dereferenced hashref elements chained to
an arbitrary depth are supported).

Inside constant strings, table column specifiers are interpolated;
the result of such interpolation is represented as a sequence
of explicit SQL concatenation operations.
The variable interpolation syntax is somewhat different from
normal Perl rules, which does not interpolate method calls.
So it is perfectly legal to write

    return "abc $t->name xyz";

When it is impossible to distinguish between the column name
and the following characters, the hash element syntax must be
used instead:

    return "abc$t->{name}xyz";

Of course, one may want to avoid the trouble altogether and use explicit Perl
concatenation in such cases:

    return "abc" . $t->name . "xyz";

Please note that specifying column names as hash elements
is I<only> valid inside interpolated strings;  this may change
in the future versions of the module.

Please also note that column specifiers of
C<tablename-E<gt>column> form cannot be embedded into strings;
again, use explicit Perl concatenation in such cases.

Function calls can take an arbitrary number of arguments.
Each argument to a function must currently be a term,
although it is expected that more general expressions will
be supported in the future.
The function call appear verbatim in the resulting SQL,
with the arguments translated from Perl syntax to SQL
syntax.  For example:

    lower($t1->name) eq lower($t2->lastname);

Some of the functions are handled specially:

=over

=item C<lc> and C<uc>

The Perl builtins C<lc> and C<uc> are translated into C<lower> and
C<upper>, respectively.

=item C<extract>

A two-argument form of the C<extract> function, where the first
argument is a constant string, will be converted into the form
understood by the SQL standard.  For example,

    extract(day => $t->field)

will be converted into something like

    EXTRACT(DAY FROM t01.field)

as is required.

=back

Another special case is when C<sql()> function (with a single
parameter) is called.  In this case the parameter of the
function call inserted verbatim into the generated SQL,
for example:

    db_update {
        tab->state eq "new";
        tab->id = sql "some_seq.nextval";
    };

There is also a shortcut when one can use backquotes for
verbatim SQL pieces:

    db_update {
        tab->state eq "new";
        tab->id = `some_seq.nextval`;
    };

A C<next> statement with a (label) argument is interpreted as
an operator of getting the next value out of a sequence,
where the label name is the name of the sequence.
Syntax specific to the DBI driver will be used to represent
this operation.  It is a fatal error to use such a statement
with DBI drivers which do not support sequences.  For example,
the following is exactly equivalent to the example above,
except it is more portable:

    db_update {
        tab->state eq "new";
        tab->id = next some_seq;
    };

The "comes from" C<E<lt>-> binary operator can be used in the
following manner:

    my @ary = (1,2,3);
    db_fetch {
        tab->id  <-  @ary;
    };

This is equivalent to SQL's C<IN I<list>> operator, where
the list comes from the C<@ary> array.  An array reference
or an anonymous array can also be used in place of the C<@ary>
here.

The C<E<lt>-> operator can also be used with L</Subqueries>,
below.


=head3 Return statements

Return statements determine which columns are returned by
a query under what names.
Each element in the return statement can be either
a reference to the whole table, an expression involving
table columns, or a string constant,
in which case it is taken as an alias to
the next element in the return statement:

    return ($table->col1, anothername => $table->col2);

If an element is a reference to the whole table,
it is understood that all columns from this table
are returned:

    return ($t1->col1, $t1->col2, $t2);

Table references cannot be aliased by a name.

One can also specify a "distinct" or "DISTINCT"
string constant in the beginning of the return list,
in which case duplicated rows will be eliminated
from the result set.

It is also permissible to use a C<next> operator with a label
argument (see above) in return statements:

    return next some_seq;

Return statements are only valid in L</db_fetch {}>.

Query subs representing subqueries using the reverse
arrow notation must have exactly one return statement
returning exactly one column (see L</Subqueries> below).


=head3 Assignments

Assignments can take two form: individual column assignments
or bulk assignments.  The former must have a reference to
a table column on the left-hand side, and an expression
like those accepted in filter statements on the right-hand
side:

    table1->id = 42;
    $t->column = $t->column + 1;

The bulk assignments must have a table specifier on the left-hand
side, and a hash reference on the right-hand side.
The keys of the hash represent column names, and the values
are expressions like those in the individual column
assignments:

    $t = {
        id     => 42,
        column => $t->column + 1
    };

or

    tablename() = {
        id     => 42,
        column => tablename->column + 1
    };

Please note a certain ugliness in C<tablename()> in the last example,
so it is probably better to either use table vars, or stick to the
single assignment syntax of the first example.

It is possible to intermix hashes and hashrefs dereferencings with
verbatim key/value pairs in bulk assignments:

    $t = {
        id     => 42,
        column => $t->column + 1,
        %$hashref_from_outer_scope
    };

Please note that the right hand side of the bulk assignment must
be an anonymouse hash reference.  Thus, the following is invalid:

    $t = $hashref_from_outer_scope;

Instead, write

    $t = {%$hashref_from_outer_scope};

The latter emphasizes the fact that this is the bulk assignment, which
is not clear from the former statement.

Assignment statements are only valid in L</db_update {}>.

=head3 Result limiting and ordering statements

The C<last> command can be used to limit the number of
results returned by a fetch operation.

If it stands on its own anywhere in the query sub, it means "stop
after finding the first row that matches other filters", so it
is analogous to C<LIMIT 1> in many SQL dialects.

It can also be used in conjunction with a range C<..> operator,
so that

    last unless 5..20;

is equivalent to

    OFFSET 5 LIMIT 16


The C<sort> builtin can be used to specify the desired order
of the results:

    sort $t->col1, $t->col2;

is equivalent to

    ORDER BY col1, col2

In order to support the ordering direction, the sort expressions
can be preceded by a literal string which
must satisfy the pattern /^(asc)/i (for ascending order,
which is the default), or /^(desc)/i for descending order:

    sort desc => $t->col1, asc => $t->col2;

is equivalent to

    ORDER BY col1 DESC, col2

Result limiting and ordering statements are only valid in L</db_fetch {}>.


=head3 Conditional statements

There is a limited support for parse-time conditional expressions.

At the query sub parsing stage, if the conditional does not mention
any tables or columns, and refers exclusively to the values from the
outer scope, it is evaluated, and the corresponding filter (or any other
kind of statement) is only put into the generated SQL if the condition
is true.

For example,

    my $type = "ICBM";
    db_fetch {
        my $p : products;
        $p->type eq $type if $type;
    };

will generate the equivalent to C<select * from products where type = 'ICBM'>,
while the same code would generate just C<select * from products> if C<$type>
were false.

The same code could be written with a real C<if> statement as well:

    my $type = "ICBM";
    db_fetch {
        my $p : products;
        if ($type) {
            $p->type eq $type;
        }
    };

Similarly,

    my $want_z = 1;
    db_fetch {
        my $p : products;
        return $p->x, $p->y         unless $want_z;
        return $p->x, $p->y, $p->z  if     $want_z;
    };

will generate the equivalent of C<select x, y from products> when
C<$want_z> is false, and C<select x, y, z from products> when
C<$want_z> is true.


=head3 Statements with label syntax

There is a number of special labels which query sub syntax allows.

Specifying label C<distinct:> anywhere in the query sub leads to duplicated
rows being eliminated from the result set.

Specifying label C<limit:> followed by a number (or a scalar variable
representing a number) limits the number of rows returned by the query.

Specifying label C<offset:> followed by a number N (or a scalar variable
representing a number N) skips first N rows from the returned result
set.

Specifying label C<order:>, C<orderby:>, C<order_by:>,
C<sort:>, C<sortby:>, or C<sort_by:>, followed by a list of
expressions will sort the result set according to the expressions.
For details about the sorting criteria see the documentation
for C<ORDER BY> clause in your SQL dialect reference manual.
Before a sorting expression in a list one may specify one of the
string constants "asc", "ascending", "desc", "descending" to
alter the sorting order, or even generic direction and column, for example:

    db_fetch {
        my $t : tbl;
        order_by: asc => $t->name, desc => $t->age, $direction, $column;
    };

Specifying label C<group:>, C<groupby:>, or C<group_by:>,
followed by a list of column specifiers is equivalent to
the SQL clause C<GROUP BY col1, col2, ...>.

The module implements an I<experimental> feature which
in some cases allows one to omit the explicit
C<group_by:> label.  If there is an explicit C<return> statement
which mentions an aggregate function alongside "normal"
column specifiers, and that return statement does not
reference the whole table, and the explicit C<group_by:> label
is not present in the query, the 
C<DBIx::Perlish> module will generate one automatically.
For example, the following query:

    db_fetch {
        my $t : tab;
        return $t->name, $t->type, count($t->age);
    };

will execute the equivalent of the following SQL statement:

  select name, type, count(age) from tab group by name, type

The C<avg()>, C<count()>, C<max()>, C<min()>, and C<sum()>
functions are considered to be aggregate.

Similarly, using an aggregate function in a filtering expression
will lead to automatic introduction of a HAVING clause:

    db_fetch {
        my $w : weather;
        max($w->temp_lo) < 40;
        return $w->city;
    };

will translate into an equivalent of

    select city from weather group by city having max(temp_lo) < 40

Specifying label C<table:> followed by a lexical variable
declaration, followed by an assignment introduces an alternative
table declaration syntax.  The value of the expression on the right
hand side of the assignment is taken to be the name of the table:

    my $data = { table => "mytable" };
    db_fetch {
        table: my $t = $data->{table};
    };

This is useful if you don't know the names of your table until
runtime.

All special labels are case insensitive.

Special labels are only valid in L</db_fetch {}>.


=head3 Compound queries' statements

The SQL compound queries UNION, INTERSECT, and EXCEPT are supported
using the following syntax:

    db_fetch {
        {
            ... normal query statements ...
        }
        compound-query-keyword
        {
            ... normal query statements ...
        }
    };

Here I<compound-query-keyword> is one of C<union>,
C<intersect>, or C<except>.

This feature will only work if the C<use> statement for
the C<DBIx::Perlish> module was written with C<:all>
export declaration, since C<union>, C<intersect>, and C<except>
are subs that are not exported by default by the module.

It is the responsibility of the programmer to make sure
that results of the individual queries used in a compound
query are compatible with each other.


=head3 Subqueries

It is possible to use subqueries in L</db_fetch {}>, L</db_update {}>,
and L</db_delete {}>.

There are two variants of subqueries.  The first one is a
call, as a complete statement,
to L</db_fetch {}> anywhere in the body of the query sub.
This variant corresponds to the C<EXISTS (SELECT ...)> SQL
construct, for example:

    db_delete {
        my $t : table1;
        subselect {
            $t->id == table2->table1_id;
        };
    };

Another variant corresponds to the C<column IN (SELECT ...)> SQL
construct.  It uses a special syntax with back-arrow C<E<lt>->
(read it as "comes from"),
which signifies that the column specifier on the left gets
its values from whatever is returned by a L</db_fetch {}> on
the right:

    db_delete {
        my $t : table1;
        $t->id  <-  subselect {
            return table2->table1_id;
        };
    };

This variant puts a limitation on the return statement in the sub-query
query sub.  Namely, it must contain a return statement with exactly one
return value.

If the right-hand side of the "comes from" operator is a function call,
the function is assumed to be a function potentially returning a set
of values, or a "table function", in Oracle terminology.
Such construct is converted into a driver-dependent subselect involving
the table function:

    db_fetch {
        tbl->id  <-  tablefunc($id);
    };

Where result of a subquery comes from a function, the following syntax can be
also used:
    
    db_fetch {
        my $t : table = tablefunc($id);
	return $t;
    };

This allows for SQL syntax like

   SELECT t.* FROM tablefunc(?) t, other_table

where joins of subselects are not enough.

=head3 Joins

Joins are implemented similar to subqueries, using embedded C<db_fetch> call to
specify a join condition. The join syntax is one of (the last two are
equivalent):

    join $t1 BINARY_OP $t2;
    join $t1 BINARY_OP $t2 => subselect { CONDITION };
    join $t1 BINARY_OP $t2 <= subselect { CONDITION };

where CONDITION is an arbitrary expression using fields from C<$t1> and C<$t2>
, and BINARY_OP is one of C<*>,C<+>,C<x>,C<&>,C<|>,C<< < >>,C<< > >> operators,
which correspond to the following standard join types:

=over

=item Inner join

This corresponds to either of C<*>, C<&>, and C<x> operators.
The C<subselect {}> condition for inner join may be omitted,
in which case it degenerates into a I<cross join>.

=item Full outer join

It is specified with C<+> or C<|>.
The C<DBIx::Perlish> module does not care
that some database engines do not support full outer join,
nor does it try to work around this limitation.

=item Left outer join

C<< < >>

=item Right outer join

C<< > >>

=back

Example:

    my $x : x;
    my $y : y;
    join $y * $x => subselect { $y-> id == $x-> id };

=head2 Object-oriented interface

=head3 new()

Constructs and returns a new DBIx::Perlish object.

Takes named parameter.

One parameter, C<dbh>, is required and
must be a valid DBI database handler.

Another parameter which the C<new()> understands is C<quirks>,
which, if present, must be a reference to an array of anonymous
arrays, each corresponding to a single call to C<quirk()>.
Please see C<quirk()> for details.

Can throw an exception if the supplied parameters
are incorrect.

=head3 fetch()

An object-oriented version of L</db_fetch {}>.

=head3 update()

An object-oriented version of L</db_update {}>.

=head3 delete()

An object-oriented version of L</db_delete {}>.

=head3 insert()

An object-oriented version of L</db_insert()>.

Returns the SQL string, most recently generated by database
queries performed by the object.
Returns undef if there were no queries made thus far.

Example:

    $db->query(sub { $u : users });
    print $db->sql, "\n";

=head3 query($sub)

Returns converts C<$sub> into SQL text.
Useful for debugging and passing down prepared queries

=head3 sql()

Serves the purpose of injecting verbatim pieces of SQL into query subs (see
L</Query filter statements>) or into the values to be inserted via
L</db_insert()>.

The C<sql()> function is exported by default.

=head3 bind_values()

Takes no parameters.
Returns an array of bind values that were used in the most recent
database query performed by the object.
Returns an empty array if there were not queries made thus far.

Example:

    $db->query(sub { users->name eq "john" });
    print join(", ", $db->bind_values), "\n";

=head3 quirk()

An object-oriented version of L</quirk()>.

=head3 optree_version

Returns 1 if perl version is prior 5.22, where there are no optimizations on the optree.
Returns 2 otherwise, when perl introduced changes to optree, that caused certain uncompatibilities.
See more in C<BACKWARD COMPATIBILITY>

=head2 Working with multiple database handles

There are several ways in which the C<DBIx::Perlish> module can be used
with several different database handles within the same program:

=over

=item Using object-oriented interface

The advantage of this approach is that there is no confusion
about which database handle is in use, since a DBIx::Perlish object
is always created with an explicit database handle as a parameter
to L</new()>.

The obvious disadvantage is that one has to explicitly use "sub"
when specifying a query sub, so the syntax is unwieldy.

=item Using special import syntax

It is possible to import differently named specialized versions
of the subs
normally exported by the C<DBIx::Perlish> module, which will
use specified database handle.  The syntax is as follows:

    use DBIx::Perlish;
    my $dbh = DBI->connect(...);

    my $foo_dbh = DBI->connect(...);
    use DBIx::Perlish prefix => "foo", dbh => \$foo_dbh;

    my $bar_dbh = DBI->connect(...);
    use DBIx::Perlish prefix => "bar", dbh => \$bar_dbh;

    my @default =  db_fetch { ... };
    my @foo     = foo_fetch { ... };
    my @bar     = bar_fetch { ... };

The syntax and semantics of such specialized versions is exactly
the same as with the normal L</db_fetch {}>, L</db_select {}>,
L</db_update {}>, L</db_delete {}>, and L</db_insert()>,
except that they use the database handle specified in the C<use>
statement for all operations.  As can be seen from the example above,
the normal versions still work as intended, employing the usual mechanisms
for determining which handle to use.

=back


=head2 Database driver specifics

The generated SQL output can differ depending on
the particular database driver in use.

=head3 MySQL

Native MySQL regular expressions are used if possible and if
a simple C<LIKE> won't suffice.

=head3 Oracle

The function call C<sysdate()> is transformed into C<sysdate>
(without parentheses).

Selects without table specification are assumed to be
selects from DUAL, for example:

    my $newval = db_fetch { return `tab_id_seq.nextval` };

Table functions in Oracle are handled specially.

There are quirks (see L</quirk()>) that can be registered
for Oracle driver.

=head3 Postgresql

Native Postgresql regular expressions are used if possible and if
a simple C<LIKE> won't suffice.

The same applies to PgLite, which is a Postgresql-like wrapper around
SQLite.  In this case, "native" PgLite regular expressions are actually
native Perl regular expressions, but the C<DBIx::Perlish> module
pretends it does not know about it.

=head3 SQLite

Native Perl regular expressions are used with SQLite even for
simple match cases, since SQLite does not know how to optimize
C<LIKE> applied to an indexed column with a constant prefix.

=head2 Implementation details and more ideology

To achieve its purpose, this module uses neither operator
overloading nor source filters.

The operator overloading would only work if individual tables were
represented by Perl objects.  This means that an object-relational
mapper like C<Tangram> can do it, but C<DBIx::Perlish> cannot.

The source filters are limited in other ways: the modules using them
are often incompatible with other modules that also use source filtering,
and it is B<very> difficult to do source filtering when any degree of
flexibility is required.  Only perl can parse Perl!

The C<DBIx::Perlish> module, on the other hand, leverages perl's ability
to parse Perl and operates directly on the already compiled Perl code.
In other words, it parses the Perl op tree (syntax tree).

The idea of this module came from Erlang.  Erlang has a so called
I<list comprehension syntax>, which allows one to generate lists
using I<generator> expressions and to select the list elements using
I<filter> expressions.  Furthermore, the authors of the Erlang database,
Mnesia, hijacked this syntax for the purpose of doing database queries
via a mechanism called I<parse transform>.
The end result was that the database queries in Erlang are expressed
by using Erlang's own syntax.

I found this approach elegant, and thought "why something like this
cannot be done in Perl"?


=head1 CONFIGURATION AND ENVIRONMENT

DBIx::Perlish requires no configuration files or environment variables.

=head2 Running under L<Devel::Cover>

When the C<DBIx::Perlish> module detects that the current program
is being run under L<Devel::Cover>,
it tries to cheat a little bit and feeds L<Devel::Cover>
with I<false> information to make those
query subs which were parsed by the module
to appear "covered".

This is done because the query subs are B<never> executed,
and thus would normally be presented as "not covered" by
the L<Devel::Cover> reporter.
Although a developer has no trouble deciding to ignore
such "red islands", he has to perform this decision every
time he looks at the coverage data, which tends to become
annoying rather quickly.

Currently, only statement and sub execution data are faked.

=head1 DEPENDENCIES

The C<DBIx::Perlish> module needs at least perl 5.14.

This module requires C<DBI> to do anything useful.

In order to support the special handling of the C<$dbh> variable,
C<Keyword::Pluggable> needs to be installed. C<Devel::Caller> is 
needed for some magic, and C<Pod::Markdown> is a developer dependency
for auto-generating README.md.

Other modules used used by C<DBIx::Perlish> are included
into the standard Perl distribution.

=head1 INCOMPATIBILITIES

Starting with version 0.54 the handling of key fields
(return -k $t->field) has incompatibly changed.
The previous behavior was to always return individual
results as hash references, even when only one
column (not counting the key fields) was specified
in the return statement.  The current behavior is
to return simple values in this case.

If you use C<DBIx::Perlish> together with L<HTML::Mason>,
you are likely to see warnings "Useless use of ... in void context"
that Mason helpfully converts into fatal errors.

To fix this, edit your C<handler.pl> and add the following line:

  $ah->interp->ignore_warnings_expr("(?i-xsm:Subroutine .* redefined|Useless use of .+ in void context)");

Here C<$ah> must refer to an instance of C<HTML::Mason::ApacheHandler>
class.

Mason is to blame for this, since it disregards
warnings' handlers installed by other modules.

=head1 BACKWARD COMPATIBILITY

Perl 5.22 introduced certain changes to the way optree is constructed.
Some of these cannot be adequately treated, because whole constructs might be
simply optimized away before even they hit the parser (example: C<join(1,2)> gets translated into constant C<2>).

Known cases are not documented so far, but look in the tests for I<optree_version> invocations
to see where these are found.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dbix-perlish@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

A number of features found in many SQL dialects is not supported.

The module cannot handle more than 100 tables in a single
query sub.

Although variables closed over the query sub can be used
in it, only simple scalars, hash elements, and dereferenced
hasref elements are understood at the moment.

If you would like to see something implemented,
or find a nice Perlish syntax for some SQL feature,
please let me know!

=head1 AUTHOR

Anton Berezin  C<< <tobez@tobez.org> >>

=head1 ACKNOWLEDGEMENTS

Special thanks to Dmitry Karasik,
who contributed code and syntax ideas on several occasions,
and with whom I spent considerable time discussing
this module.

I would also like to thank
Henrik Andersen,
Mathieu Arnold,
Phil Regnauld,
and Lars Thegler,
for discussions, suggestions, bug reports and code contributions.

This work is in part sponsored by Telia Denmark.


=head1 SUPPORT

There is also the project website at
  http://dbix-perlish.tobez.org/


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2013, Anton Berezin C<< <tobez@tobez.org> >>. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
