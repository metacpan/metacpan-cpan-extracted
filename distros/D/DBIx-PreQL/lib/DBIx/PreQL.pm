package DBIx::PreQL;
use strict;
use warnings;
use Carp qw< croak carp >;
require overload;   # Just for Overloaded()

use constant TAG_ALWAYS         => '*';
use constant TAG_NEVER          => '#';
use constant TAG_IF_ALL_EXIST   => '&';
use constant TAG_IF_ANY_EXIST   => '|';
use constant TAG_IF_PREFIXED    => qr/^([&|])(?![&|])(\S*)$/;

# Substitution types:
#   !ifset!,        !~ifnotset!
#   ?param?,        ?@array_ref?
#   ?=same_as?,     ?!distinct?
#   ?"literal_sql?


sub _parse_data {
    my( $data ) = @_;

    croak "data must be a hash reference"
        unless  ! defined($data)
            ||  ref($data) eq 'HASH';

    return $data || {};
}


sub _parse_wanted {
    my( $w ) = @_;

    return if ! defined $w;

    return $w if ref $w eq 'CODE';

    if( ref $w eq 'ARRAY' ) {
        my %w; @w{@$w} = (1) x @$w;

        return sub { return $w{$_[0]} };
    }

    croak "wanted must be an array ref or code ref";
}


sub _split_query {
    my( $q ) = @_;

    croak "No query specified"
        if  ! defined($q)  ||  ! length($q);

    my @lines = grep /\S/,  # Remove blank lines
        map {
            # Split into lines, removing trailing whitespace:
            split /[^\S\n]*\n/, $_
        } ref $q eq 'ARRAY' ?  @$q : ($q);
    my $indent;
    for(  @lines  ) {
        next    # Lines with nothing after the tag have no indentation
            if  ! /^(\s*\S+\s+)/;
        my $l = length( $1 );   # Measure how much the SQL is indented
        $indent = $l            # Track the least amount of indentation
            if  ! $indent  ||  $l < $indent;
    }
    return( $indent, @lines );
}


sub _parse_line {
    my( $line, $indent ) = @_;

    my( $pre, $tag, $post, $sql ) = $line =~ /^(\s*)(\S+)(\s*)(.*)$/
        or  die "Impossible: SQL template line w/o tag:\n$line\nfound";

    my $context = ":\n    $tag $sql\n";     # Used for error messages.
    # Preserve indentation (using minimal spaces):
    $indent = ' ' x( length("$pre$tag$post") - $indent );


    my $prefix = '';
    if(  $tag =~ TAG_IF_PREFIXED  ) {   # '&', '|', '&FOO', or '|BAR' tag:
        ( $prefix, $tag ) = ( $1, $2 );

        # Note that '&*' and '|*' act like '&' and '|' (respectively)
        $tag = TAG_ALWAYS
            if  '' eq $tag;
    }

    return $prefix, $tag, $indent, $sql, $context;
}

sub _find_named_placeholders {
    my( $sql, $data ) = @_;

    my( @pholders, @found, @missing );
    while(  $sql =~ /\?[\@=!"]?(\w+)\?/g  ) {
        my $name = $1;
        push @pholders, $name;

        if( defined $data->{$name} ) {
            push @found, $name;
        }
        else {
            push @missing, $name
        }
    }

    return {
        all     => \@pholders,
        found   => \@found,
        missing => \@missing,
    };
}

sub _find_dependencies {
    my( $sql, $data ) = @_;

    my( @deps, @found, @lost );
    while(  $sql =~ /!(~?)(\w+)!/g  ) {
        my( $negated, $name ) = ( $1, $2 );

        push @deps, $name;

        my $found = defined $data->{$name};
        $found = ! $found
            if  $negated;

        if( $found ) {
            push @found, $name;
        } else {
            push @lost, $name;
        }
    }

    return {
        all     => \@deps,
        found   => \@found,
        missing => \@lost,
    };
}

sub _select_line {
    my( $line, $base_indent, $data, $want, $known_tags ) = @_;

    my( $prefix, $tag, $indent, $sql, $context ) = _parse_line( $line, $base_indent );

    return
        if TAG_NEVER eq $tag;

    my $nph  = _find_named_placeholders( $sql, $data );
    my $deps = _find_dependencies( $sql, $data );

    return
        if  @{$nph->{missing}}
        &&  $prefix;  # $tag starts with '&' or '|'

    croak "Missing tag?$context"    # Catch "* SELECT\n  *\n* FROM\n"
        if  $sql !~ /\S/;           #                  ^ missing tag

#TAG_IF_ALL_EXIST,     {
#    die_msg     => "No parameters nor dependency markers specified",
#    die_unless  => [ $nph->{all}, $deps->{all} ],
#    skip_if     => [ $deps->{missing} ],
#},
#
#TAG_IF_ANY_EXIST, {
#    die_msg => "No dependency markers specified",
#    die_unless  => [ $deps->{all} ],
#    skip_unless => [ $deps->{found} ],
#},
#TAG_ALWAYS, {
#    die_msg => "Dependency markers ({$deps->{all}}) used with wrong tag type"
#    die_if  => [ $deps->{all} ],
#}




    if( TAG_IF_ALL_EXIST eq $prefix ) {
        croak "No parameters nor dependency markers specified$context"
            if  ! @{$nph->{all}}
            &&  ! @{$deps->{all}};
        return
            if  @{$deps->{missing}};
    } elsif( TAG_IF_ANY_EXIST eq $prefix ) {
        croak "No dependency markers specified$context"
            if  ! @{$deps->{all}};
        return
            if  ! @{$deps->{found}};
    } else {
        croak "Dependency markers (@{$deps->{all}}) used with wrong tag type$context"
            if  @{$deps->{all}};

        if( TAG_ALWAYS ne $tag ) {  # Handle custom tags:
            if(  $known_tags  ) {
                croak "Unknown tag found$context"
                    if  ! $known_tags->{$tag}++;
            } else {
                croak "Missing tag?$context"
                    if  $tag =~ /,$/
                    ||  grep( $_ eq uc $tag, qw<
                            SELECT FROM LEFT RIGHT INNER OUTER JOIN USING ON
                            WHERE AND OR
                            ORDER GROUP BY LIMIT OFFSET HAVING
                            UNION ALL DISTINCT
                            INSERT UPDATE ALTER CREATE DROP
                            WITH OVER BETWEEN
                        > );
            }
            croak "No wanted function provided when using custom tag$context"
                if  ! $want;
            return
                if  ! $want->( $tag, $data );
        }
    }

    croak "Missing named place-holders (@{$nph->{missing}})$context"
        if  @{$nph->{missing}};

    return( $indent . $sql, $context );
}


sub _bad_type {
    my( $sigil, $name, $val, $context ) = @_;

    my $type = ref($val);
    croak "Invalid type ($type) for ?$sigil$name?$context";
}

{
    #SIGIL => { VALTYPE => sub { param => ?, repl => ? } } 
    # sub takes args $name, $value.
    # returns kvp list of param and repl to override defaults.
    my %NPH_HANDLER = (
        ''  => { ''     => sub { param => [$_[0]]   },
                 SCALAR => sub { repl  => ${$_[1]}  },
               },
        '@' => { ARRAY  => sub { param => [$_[0]]   } },
        '"' => { ''     => sub { repl  => $_[1]     },
                 SCALAR => sub { repl  => ${$_[1]}  },
               },
        '=' => { ''     => sub { param => [$_[0]], repl => '= ?' },
                 SCALAR => sub { repl  => "= ${$_[1]}"  },
                 NULL   => sub { repl  => 'IS NULL'  },
               },
        '!' => { ''     => sub { param => [$_[0]], repl => '<> ?' },
                 SCALAR => sub { repl  => "<> ${$_[1]}"  },
                 NULL   => sub { repl  => 'IS NOT NULL'  },
               },
    );

    sub _process_named_placeholder {
        my ($sigil, $name, $value) = @_;

        my $type = ref $value || '';
        $type = 'NULL'
            if $type && _is_null( $type );

        return 
            unless exists( $NPH_HANDLER{$sigil} )
                && exists( $NPH_HANDLER{$sigil}{$type} );

        my $handler = $NPH_HANDLER{$sigil}{$type};

        return { repl => '?', param => [], $handler->($name, $value) };
    }

}

sub _substitute_line {
    my( $sql, $context, $data ) = @_;

    # Remove dependency markers and extra whitespace:
    #   "a   !b! !c!"           => "a"
    #   "a!b!c"                 => "ac"
    #   "a !b! c" or "a !b!c"   => "a c"
    $sql =~ s/(\s*)!~?\w+!(?=(\s*)(\S?))/
        $1 && !$2 && length $3 ? ' ' : '';
    /ge;

    # Replace named parameters with computed text
    # Fill param array.
    my @params;
    $sql =~ s{\?([\@=!"]?)(\w+)\?}{
        my( $sigil, $name ) = ( $1, $2 );
        my $value = $data->{$name};

        my $np = _process_named_placeholder( $sigil, $name, $value )
            or _bad_type( $sigil, $name, $value, $context );

        push @params, @{$np->{param}};

        $np->{repl};
    }ge;

    return( $sql, @params );
}


sub build_query {
    my( $class, %a ) = @_;
    croak "You must call build_query() as a class method"
        if  $class ne __PACKAGE__;

    my $data        = _parse_data( delete $a{data} );
    my $want        = _parse_wanted( delete $a{wanted} );
    my @query_lines = _split_query( delete $a{query} );
    my $indent      = shift @query_lines;
    my $keep_keys   = delete $a{keep_keys};
    my $known_tags  = delete $a{known_tags};
    $known_tags &&= { map { $_ => 1 } @$known_tags };

    my @unexpected_keys = sort keys %a;
    croak "Unexpected arguments given to build_query(): @unexpected_keys"
        if @unexpected_keys;

    my @query;      # Accumulate lines in loop
    my @binds;      # Build list in loop

    for ( @query_lines ) {
        # Determine if we should include this line:
        my( $line, $context ) = _select_line(
            $_, $indent, $data, $want, $known_tags,
        )
            or  next;

        ( $line, my @params ) = _substitute_line( $line, $context, $data );

        # Remove trailing comma if in front of 'FROM':
        $query[-1] =~ s/,\s*$//
            if  @query  &&  $line =~ /^\s*FROM\b/i;

        # Remove leading 'AND' if behind 'WHERE':
        $line =~ s/^(\s*)AND\b/$1   /
            if  @query  &&  $query[-1] =~ /\bWHERE\s*$/i;

        push @query, $line;
        push @binds, @params;
    }

    my $query = join "\n", @query;

    if( ! $keep_keys ) {
        $_ = $data->{$_}
            for  @binds;
    }

    if(  $known_tags  ) {
        my @unused = grep 1==$known_tags->{$_}, sort keys %$known_tags;
        carp "Some known tags never used (@unused)"
            if  @unused;
    }

    return $query, @binds;
}


sub _is_ref {
    my( $val ) = @_;
    return 0
        if  ! ref $val
        ||  overload::Method( $val, '""' );
    return 1;
}


sub _is_a {
    my( $val, $type ) = @_;
    return 0
        if  ! _is_ref( $val );
    my $isa = eval { $val->isa($type) };
    $isa = UNIVERSAL::isa( $val, $type )
        if  ! defined $isa;
    return $isa;
}


sub _is_null {
    my( $val ) = @_;
    return 1
        if  _is_a( $val, 'SCALAR' )
        &&  $$val =~ /^\s*NULL\s*$/i;
    return 0;
}


1;

__END__

=head1 NAME

DBIx::PreQL - beat dynamic SQL into submission

=head1 SYNOPSIS

    use DBIx::PreQL   ();


    my $q = <<END_SQL;
        *   SELECT
        &       count(*),                   !total!
        *       name,
    END_SQL




    my $q = <<END_SQL;
        *   SELECT
        &       count(*),                   !total!
        D       name,
        D       height,
        *   FROM tbl_monkey
        *   WHERE
        &       AND barrel_id = ?barrel_id?
        &       AND name ILIKE '%' || ?monkey_name? || '%'
        &       AND color ?=monkey_color?
        &       AND ARRAY[type] <@ ?\@types? -- "IN"
        &   ORDER BY name                   !~total!
    END_SQL

    my $total = undef;
    my $rows = $db->select_all( DBIx::PreQL->build_query(
        query  => $q,
        data   => {
            barrel_id       => 32,
            monkey_color    => \'NULL',
            total           => $total,
            types           => [ 'ape', 'chimp' ],
        },
        wanted => ! $total ? ['D'] : [],    # Want 'D'ata if not $total
    ) );

    # Runs the following with @params = ( 32, ['ape','chimp'] ):
    #   SELECT
    #       name,
    #       height
    #   FROM tbl_monkey
    #   WHERE
    #           barrel_id = ?
    #       AND color IS NULL
    #       AND ARRAY[type] <@ ? -- "IN"
    #   ORDER BY name

=head1 DESCRIPTION

This module generates queries based on a query template, a hash of related
data, and possibly a list of wanted tags or a function that determines which
tags are wanted.

=head2 SQL Template

This templating system adds only a handful of concepts to standard SQL text.

The query template is processed on a line-by-line basis.

Each line consists of a B<tag> followed by the B<body> of the line.  That
is, each line is composed of: optional whitespace, a tag composed of one
or more non-whitespace characters, a separator of one or more whitespace
characters, and the remainder of the line is the embedded SQL (the B<body>).

Each line B<body> consists of plain SQL text and perhaps some
B<named place-holders> and/or B<dependency markers>.

=head3 Body Text

=over 4

=item Named place-holders

A B<named place-holder> is a name bracketed by question marks, like
C<?key_name?>.  Use named place-holders where you would normally use
place-holders (C<?>) in SQL (with DBI).

When a named place-holder is included in a query, it gets replaced by just
a question mark (C<?>, a regular DBI place-holder) and the named value gets
pushed onto the list of query parameters.

There are also special forms of place-holders (C<?=key_name?>, C<?!key_name?>,
C<?@key_name?>, and C<?"key_name?>) which we will describe later.

=item Dependency markers

A B<dependency marker> is a name bracketed by exclamation points, like
C<!key_name!>.  Use dependency markers to indicate that a given line
should only be included in the generated query if the named value is
defined in the data hash.

When the template is processed, dependency markers are just removed (and
nothing is added to the list of query parameters).

If a line has multiple dependency markers, then you can request that the
line be included if I<any> of them are defined or only if I<all> of them
are defined (in the data hash).  See the Tags section for how this is done.

You can also use C<!~key_name!> to negate the dependency.  Lines marked with
a negated dependency are only included if the named key is I<undefined> (or
missing) from the data hash.

=back

=head3 Tags

Each tag indicates how to decide whether to include the tagged line of SQL in
the generated query.

Tags must be one or more non-whitespace characters.

There are several pre-defined tags that don't require the use of a 'wanted'
list / function:

=over 4

=item C<*>

A tag of C<*> (asterisk) means I<always include this line>.  The skeleton of
your query will be lines starting with C<*>.

=item C<#>

A tag of C<#> (pound sign) means I<never include this line>.  Yep, they are
just comments.

=item C<&>

A tag of C<&> (ampersand) means I<include this line if we have data for
ALL named place-holders and ALL dependency markers>.  These lines are
the work-horse lines that will handle most of the dynamic query assembly.

You can also use a custom tag that I<starts> with an ampersand (C<&>), like
C<'&TOT'>.  For such tags, first we check that we have data for all named
place-holders and all dependency markers.  If not, then the line is simply
excluded.  Otherwise, the C<&> is stripped and the remainder of the tag
is treated as a custom tag and will be checked against your 'wanted' list /
function.

The tag is C<&> to match Perl's C<&&> operator since a line like

    & LIMIT ?limit? !~total! !paged!

only gets included if

        defined $data->{limit}
    &&  ! defined $data->{total}
    &&  defined $data->{paged}

=item C<|>

A tag of C<|> (vertical bar) means I<include this line if we have data for
ANY dependency markers as well as for ALL named place-holders>.  These
lines will be less common.

Similar to C<&>, you can use a custom tag that I<starts> with a vertical
bar (C<|>), like C<'|SUM'>.  For such tags, first we check that we have data
for ANY dependency markers and for ALL named place-holders.  If not, then the
line is simply excluded.  Otherwise, the C<|> is stripped and the remainder
of the tag is treated as a custom tag and will be checked against your
'wanted' list / function.

The tag is a C<|> because of how it treats dependency markers.  A line with
two dependency markers, say C<!tot!> and C<!~sum!>, only gets included if

    defined $data->{tot}  ||  ! defined $data->{sum}

and the C<|> tag was chosen to match the C<||> operator in that expression.
(Named place-holders are treated the same as for the C<&> tag since having
an undefined or missing value for a place-holder would just be fatal.)

=back

Any other block of characters is a B<custom tag>.  Whether to include a line
marked by a custom tag or not is determined by a 'wanted' list / function.
If you use custom tags, then I<you must supply a 'wanted' list / function>
(described later).

To catch accidental omission of a tag, tags that are common SQL keywords
(like 'FROM') or that end with a comma are fatally rejected (unless you
specify a C<'known_tags'> list).

For the same reason, an empty SQL line is fatally rejected unless you used
the C<'#'> tag or also omitted the tag.  So there is no way to include a
blank line in the generated SQL because we want to catch cases like:

    query => [
        '*  SELECT',
        '       *',     # Oops, left off the tag on this line
        '*    , CASE ... END AS ...',
        '*  FROM ...',
        ...
    ],

You can use C<"* --"> to include a nearly-blank (SQL comment) line in the
generated SQL.

=head3 Advanced template features

=over 4

=item SELECT trailing-comma clean-up

When including a line of SQL that begins with the I<word> C<FROM> (case
insensitive, ignoring white-space), we remove the last character of the
previous (included) line, if and only if it is a comma (C<,>).

So, please put a comma after the last value in your SELECT list (if you can
follow it by a line that starts with C<FROM>) in order to simplify editing
of the template.

No special provisions are made for handling trailing commas anywhere else
in SQL.

=item WHERE clause leading-AND clean-up

To greatly simplify the very common case of building a C<WHERE> clause from
a subset of several optional conditional expressions that should all be
separated by C<AND>, we can also remove an C<AND> that appears immediately
after a C<WHERE>.

Specifically, if we include a line of SQL that ends with the word C<WHERE>
(case insensitive, ignoring white-space) and the next (included) line of SQL
begins with the word C<AND> (case insensitive, ignoring white-space), then we
will replace the C<AND> with spaces.

Alternatively, you can replace your C<'WHERE'> with C<'WHERE TRUE'>.  You
should certainly do this if there is a chance that sometimes I<all> of the
conditional expressions will be omitted.  For example,

    *   SELECT some, stuff
    *   WHERE
    &       AND foo = ?foo?
    &       AND bar = ?bar?
    *   ORDER BY some

will result in an SQL syntax error if neither 'foo' nor 'bar' keys are
present (and defined) in the data hash.  But this can and should be prevented
by instead writing:

    *   SELECT some, stuff
    *   WHERE TRUE
    &       AND foo = ?foo?
    &       AND bar = ?bar?
    *   ORDER BY some

=item C<?=key_name?>

A special form of named place-holder includes an equals sign (C<=>) before
the key name.  This place-holder does special handling for C<NULL> values.
To specify a C<NULL> value, use C<\'NULL'> as the associated value (a SCALAR
reference to the string C<'NULL'>).

So, a template line like:

    &   AND affil_parent ?=parent?

will become (if the 'parent' key is defined) either:

    AND affil_parent = ?

or

    AND affil_parent IS NULL

The second case (where the place-holder is replaced by C<'IS NULL'>) happens
if C<$data->{parent}> is C<\'NULL'> (ignoring case and external whitespace).
For this case, the list of query parameters is not added to.

The first case (where the place-holder is replaced by C<'= ?'>) happens
if C<$data->{parent}> is not a reference (but is defined).  For this case,
C<$data->{parent}> (or just 'parent') is pushed onto the list of query
parameters.

=item C<?!key_name?>

A similar special form of named place-holder includes an exclamation point
(C<!>) before the key name.  This place-holder similarly supports C<\'NULL'>
as the associated value.  But this place-holder represents "distinct from"
(the opposite meaning compared to C<?=key_name?>).  Note that actually using
"is distinct from" or "is not distinct from" in your template is discouraged
for these cases as the Postgres query optimizer can be hampered by such.

So, a template line like:

    &   AND affil_parent ?!parent?

will become (if the 'parent' key is defined) either:

    AND affil_parent <> ?

or

    AND affil_parent IS NOT NULL

The second case (where the place-holder is replaced by C<'IS NOT NULL'>)
happens if C<$data->{parent}> is C<\'NULL'> (ignoring case and external
whitespace).  For this case, the list of query parameters is not added to.

The first case (where the place-holder is replaced by C<< '<> ?' >>)
happens if C<$data->{parent}> is not a reference (but is defined).  For
this case, C<$data->{parent}> (or just 'parent') is pushed onto the list
of query parameters.

=item C<?@key_name?>

A place-holder with an at sign (like C<?@key_name?>) requires that the
associated value be an ARRAY reference but otherwise behaves identically
to a plain, named placed-holder.  DBD::Pg will treat the array reference
as a Postgres array value.

There are a few gotchas with using Postgres array values and C<?@key_name?>
so let's give an example of typical usage.  First, let's show the typical
case that one would end up replacing with a use of C<?@key_name?>:

    push @where, 'account_id IN (' . join(',',('?')x@sub_accts) . ')';
    push @param, @sub_accts;
    # ...
        join( ' AND ', @where )
    # ...

which ends up generating SQL that includes something like:

    ... AND account_id IN (?,?,?,?,?) AND ...

where the number of C<'?'>s matches the number of elements in C<@sub_accts>.

The SQL we want to generate to use a Postgres array value instead would be:

    ... AND ARRAY[account_id] <@ ? AND ...

C<ARRAY[account_id]> makes a Postgres array value containing a single value
(the value of account_id).  C<< <@ >> means "is contained in".  And the C<?>
is a plain DBI place-holder.

So the new code would look something like:

    $rows = $db->select_all( DBIx::PreQL->build_query( {
        data => {
            sub_accts => \@sub_accts,
            # ...
        },
        query => [
            # ...
            "&  AND ARRAY[account_id] <@ ?\@sub_accts?",
            # ...
        ],
        # ...
    } ) );

Note how I had to put a backslash (C<\>) in front of the at sign in
C<?\@sub_accts?> because my SQL template string was enclosed in double
quotes.  If I hadn't done that, the query would not have worked.  Luckily,
build_query() would almost certainly have complained because that line had
a C<'&'> tag but no named place-holders.

Note that a reference to an I<empty> array would mean that

    ARRAY[account_id] <@ ?\@empty?

would never be true (it would generate an SQL syntax error using the old
method).  Sometimes that is what is wanted.  Often, an empty array means that
the condition should just be ignored.  You can accomplish that easily as
follows:

        data => {
            sub_accts => @sub_accts ? \@sub_accts : undef,
            # ...
        },
        query => [
            # ...
            "&  AND ARRAY[account_id] <@ ?\@sub_accts?",
            # ...
        ],

=item C<?"key_name?>

For the rare, complicated case, you can put a double quote before the key
name in a named place-holder.  This place-holder will be replaced by the
string value associated with that key name in the data hash.  So the string
value should be a snippet of valid SQL.

For example:

    &   AND affil_parent IS ?"parent? NULL

could be combined with:

    data => {
        parent => $has_parent ? 'NOT' : '',
        # ...
    },

to only find items with a non-NULL affil_parent if C<$has_parent> is true and
vice versa.

=back

=head3 Special data values

The values in the C<'data'> hash are usually expected to be strings (or maybe
numeric values).  But some other types of values are also handled by this
templating system.

=over 4

=item C<undef()>

The named key being present but with an undefined value associated with it
causes the templating system to act the same as if the key were not present.

=item C<\$sql>

If the associated value for a named place-holder is a reference to a scalar,
then the referenced scalar is expected to contain a valid snippet of literal
SQL (similar to how AT::SQL and other helpers treat such SCALAR refs).  The
named place-holder will be replaced with the literal SQL (not with C<'?'>)
and the list of query parameters will not be added to.

For C<?=key_name?>, C<'= '> will also be inserted just prior to the literal
SQL snippet, unless the snippet is equivalent to C<NULL>, in which case it
will be preceded with C<'IS '> instead.  While for C<?!key_name?>, C<'<> '>
will precede the snippet, except for C<NULL> which will be preceded by
C<'IS NOT '>.

For C<?@key_name?>, a reference to a scalar is a fatal error.

For dependency markers, the value being a reference does not (currently)
matter.

=item C<\'NULL'>

A reference to a string of C<'NULL'> (ignoring case and external whitespace)
is treated differently from a reference to some other snippet of SQL only for
the C<?=key_name?> and C<?!key_name?> place-holders (as documented elsewhere).

=item C<\@list>

DBD::Pg can use ARRAY references to represent a Postgres array value,
including in a query parameter.  So it is good to allow an array reference
as a data value.  However, it is quite hard to imagine a spot in an SQL
template where a Postgres array and a non-array value would both be
equally valid.

So we require you to declare whether or not you expect the place-holder to
take an ARRAY reference.  C<?@key_name?> requires an array reference.  Other
place-holders treat an array reference as a fatal error.

=item Stringifier

If a data value is a reference to a blessed object that overloads
stringification, then no special behavior is triggered.  The object may
be pushed onto the list of query parameters where it will likely later
be stringified.

In such a case, the blessed object being a reference to a SCALAR or to an
ARRAY will be ignored.  So, for example, a blessed reference to an ARRAY
that overloads stringification is a fatal error for a C<?@key_name?>
place-holder.

=item Other references

Other types of references are treated as fatal errors by named place-holders.
Dependency markers currently treat any kind of reference the same as a
non-reference.  But these behaviors should not be relied upon.

Future versions of this module may add additional special treatments for
different types of references, including changing how dependency markers
treat reference values.

=back

=head3 'wanted' list / function

The C<'wanted'> argument can be a reference to an array containing just the
custom tags whose lines should be included in the generated query.

For truly complicated cases, the C<'wanted'> argument can be a CODE reference
that is called for each custom tag.  The associated line(s) will be included
in the generated query if and only if the sub returns a true value for that
tag.

A C<'wanted'> function takes two arguments: a tag and the C<'data'> hash-ref.

For example, here is one that includes lines for tags that are the same as any
(lower-case) C<'data'> hash key having a defined value:

    wanted => sub {
        my( $tag, $data ) = @_;
        return defined $data->{ lc $tag };
    },

Here is a more complex example.  Not that this is a great example of
a case where a C<'wanted'> I<function> is preferred over a simpler
C<'wanted'> I<list>.  But it I<is> a good example of a relatively sane
C<'wanted'> function that also avoids the example being extremely complex.

    my( $query, @params ) = DBIx::PreQL->build_query(
        data    => \%data,
        query   => [
           "*   SELECT",
           "C       count(*),",
           "D       m.name,",
           "D       m.height,",
           "*   FROM tbl_monkey AS m",
           "T   JOIN tbl_tree AS t USING( monkey_id )",
           "*   WHERE",
           "&T      AND t.height >= ?min_height?",
           "&T      AND t.bark = ?bark?",
           "*       AND barrel_id ?=barrel_id?",
           "*       AND m.name ILIKE '%' || ?monkey_name? || '%'",
           "*       AND m.color ?!skip_color?",
           "D   ORDER BY name",
        ],
        known_tags => [qw< C D T >],
        wanted  => sub {
            my( $tag, $data ) = @_;
            return defined $data->{total}
                if  'C' eq $tag;            # 'C'ount
            return ! defined $data->{total}
                if  'D' eq $tag;            # 'D'ata (not 'count')
            return 0 < grep defined $data->{$_}, 'min_height', 'bark';
                if  'T' eq $tag;            # 'T'rees
            die "Unknown tag ($tag)";
        },
    );

But note that this equivalent version is simpler in several respects:

    my( $query, @params ) = DBIx::PreQL->build_query(
        data        => \%data,
        query       => [
           "*   SELECT",
           "&       count(*),                       !total!",
           "D       m.name,",
           "D       m.height,",
           "*   FROM tbl_monkey AS m",
           "|   JOIN tbl_tree AS t USING( monkey_id ) !bark! !min_height!",
           "*   WHERE",
           "&       AND t.height >= ?min_height?",
           "&       AND t.bark = ?bark?",
           "*       AND barrel_id ?=barrel_id?",
           "*       AND m.name ILIKE '%' || ?monkey_name? || '%'",
           "*       AND m.color ?!skip_color?",
           "&   ORDER BY name                       !~total!",
        ],
        wanted      => defined $total ? [] : ['D'],
        known_tags  => ['D'],
    );

This is also the our only example that makes use of the C<'|'> tag.

=head2  Caution

Conditional generation of SQL is a problem with many bad solutions and no
really good ones.  This library attempts to offer a solid less-bad solution
that keeps SQL near the surface and favors simplicity and readability over
enforced correctness.  If you want correctness, you will have to provide it
yourself.

Don't get too fancy with your 'wanted' subroutines.

Pay attention to your C<AND>s, C<OR>s, and other joining words / characters.

=head1 EXPORTS

NONE, but please include the empty list when you C<use> the module:

    use DBIx::PreQL ();

so the fact that nothing is being imported is obvious to the person reading
that code.

=head1 SUBROUTINES

=head2 build_query()

build_query is called as a class method with arguments in name/value pairs:

    ( $query, @params ) = DBIx::PreQL->build_query(
        query       => $template_string,
        data        => \%data,
        wanted      => \@wanted_tags,
        known_tags  => \@tag_list,
        keep_keys   => $boolean,
    );

Most of the prior documentation covers the details of using this method, the
only functionality provided by this module.

=head3 Arguments:

=over 4

=item query

Required.  A string of several (tagged) lines that is your query template.
You can also pass a reference to an array of lines.

=item data

Virtually required.  A reference to a hash whose keys can be referenced in
your query template and whose values can end up in the resulting parameter
list (or even incorporated into the generated SQL).

Technically, you don't have to provide a C<'data'> argument.  But not
providing one rather severely restricts your templating options and so
is a rather unlikely scenario.

=item wanted

This argument is required if you use any custom tags.  This argument is
ignored otherwise.

Either 1) a reference to an array containing the list of (custom) tags whose
lines should be included in the generated SQL.

Or 2) a reference to a subroutine that will be passed a C<$tag> and the
C<'data'> hash-ref and that returns a true value if lines having that C<$tag>
should be included (and returns a false value if such lines should be
excluded).

=item known_tags

Optional.  A reference to an array of custom tag strings.  Used to catch
typos when composing custom tags.  Finding a custom tag not in this list is
a fatal error.  Having a tag in this list that is never found is a warning.

=item keep_keys

Optional.  A boolean value.  Unlikely to be used.

When true, place-holder names (the I<keys> to the C<'data'> hash-ref) are
what get pushed onto the query parameter list.  When false (the default),
what gets pushed onto the query parameter list are the I<values> from the
C<'data'> hash-ref.

=back

Returns a string which is the generated SQL query and a list of query
parameters to be used with that query.

=cut
