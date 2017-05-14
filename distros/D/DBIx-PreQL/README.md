# NAME


DBIx::PreQL - less awful SQL generation through templates


# SYNOPSIS


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


# DESCRIPTION

This module generates queries based on a query template, a hash of related
data, and possibly a list of wanted tags or a function that determines which
tags are wanted.


## SQL Template


This templating system adds only a handful of concepts to standard SQL text.


The query template is processed on a line-by-line basis.


Each line consists of a __tag__ followed by the __body__ of the line.  That
is, each line is composed of: optional whitespace, a tag composed of one
or more non-whitespace characters, a separator of one or more whitespace
characters, and the remainder of the line is the embedded SQL (the __body__).


Each line __body__ consists of plain SQL text and perhaps some
__named place-holders__ and/or __dependency markers__.


### Body Text


- Named place-holders


A __named place-holder__ is a name bracketed by question marks, like
`?key_name?`.  Use named place-holders where you would normally use
place-holders (`?`) in SQL (with DBI).


When a named place-holder is included in a query, it gets replaced by just
a question mark (`?`, a regular DBI place-holder) and the named value gets
pushed onto the list of query parameters.


There are also special forms of place-holders (`?=key_name?`, `?!key_name?`,
`?@key_name?`, and `?"key_name?`) which we will describe later.


- Dependency markers


A __dependency marker__ is a name bracketed by exclamation points, like
`!key_name!`.  Use dependency markers to indicate that a given line
should only be included in the generated query if the named value is
defined in the data hash.


When the template is processed, dependency markers are just removed (and
nothing is added to the list of query parameters).


If a line has multiple dependency markers, then you can request that the
line be included if _any_ of them are defined or only if _all_ of them
are defined (in the data hash).  See the Tags section for how this is done.


You can also use `!~key_name!` to negate the dependency.  Lines marked with
a negated dependency are only included if the named key is _undefined_ (or
missing) from the data hash.


### Tags


Each tag indicates how to decide whether to include the tagged line of SQL in
the generated query.


Tags must be one or more non-whitespace characters.


There are several pre-defined tags that don't require the use of a 'wanted'
list / function:


- `*`


A tag of `*` (asterisk) means _always include this line_.  The skeleton of
your query will be lines starting with `*`.


- `#`


A tag of `#` (pound sign) means _never include this line_.  Yep, they are
just comments.


- `&`


A tag of `&` (ampersand) means _include this line if we have data for
ALL named place-holders and ALL dependency markers_.  These lines are
the work-horse lines that will handle most of the dynamic query assembly.


You can also use a custom tag that _starts_ with an ampersand (`&`), like
`'&TOT'`.  For such tags, first we check that we have data for all named
place-holders and all dependency markers.  If not, then the line is simply
excluded.  Otherwise, the `&` is stripped and the remainder of the tag
is treated as a custom tag and will be checked against your 'wanted' list /
function.


The tag is `&` to match Perl's `&&` operator since a line like


    & LIMIT ?limit? !~total! !paged!


only gets included if


        defined $data->{limit}
    &&  ! defined $data->{total}
    &&  defined $data->{paged}


- `|`


A tag of `|` (vertical bar) means _include this line if we have data for
ANY dependency markers as well as for ALL named place-holders_.  These
lines will be less common.


Similar to `&`, you can use a custom tag that _starts_ with a vertical
bar (`|`), like `'|SUM'`.  For such tags, first we check that we have data
for ANY dependency markers and for ALL named place-holders.  If not, then the
line is simply excluded.  Otherwise, the `|` is stripped and the remainder
of the tag is treated as a custom tag and will be checked against your
'wanted' list / function.


The tag is a `|` because of how it treats dependency markers.  A line with
two dependency markers, say `!tot!` and `!~sum!`, only gets included if


    defined $data->{tot}  ||  ! defined $data->{sum}


and the `|` tag was chosen to match the `||` operator in that expression.
(Named place-holders are treated the same as for the `&` tag since having
an undefined or missing value for a place-holder would just be fatal.)


Any other block of characters is a __custom tag__.  Whether to include a line
marked by a custom tag or not is determined by a 'wanted' list / function.
If you use custom tags, then _you must supply a 'wanted' list / function_
(described later).


To catch accidental omission of a tag, tags that are common SQL keywords
(like 'FROM') or that end with a comma are fatally rejected (unless you
specify a `'known_tags'` list).


For the same reason, an empty SQL line is fatally rejected unless you used
the `'#'` tag or also omitted the tag.  So there is no way to include a
blank line in the generated SQL because we want to catch cases like:


    query => [
        '*  SELECT',
        '       *',     # Oops, left off the tag on this line
        '*    , CASE ... END AS ...',
        '*  FROM ...',
        ...
    ],


You can use `"* --"` to include a nearly-blank (SQL comment) line in the
generated SQL.


### Advanced template features


- SELECT trailing-comma clean-up


When including a line of SQL that begins with the _word_ `FROM` (case
insensitive, ignoring white-space), we remove the last character of the
previous (included) line, if and only if it is a comma (`,`).


So, please put a comma after the last value in your SELECT list (if you can
follow it by a line that starts with `FROM`) in order to simplify editing
of the template.


No special provisions are made for handling trailing commas anywhere else
in SQL.


- WHERE clause leading-AND clean-up


To greatly simplify the very common case of building a `WHERE` clause from
a subset of several optional conditional expressions that should all be
separated by `AND`, we can also remove an `AND` that appears immediately
after a `WHERE`.


Specifically, if we include a line of SQL that ends with the word `WHERE`
(case insensitive, ignoring white-space) and the next (included) line of SQL
begins with the word `AND` (case insensitive, ignoring white-space), then we
will replace the `AND` with spaces.


Alternatively, you can replace your `'WHERE'` with `'WHERE TRUE'`.  You
should certainly do this if there is a chance that sometimes _all_ of the
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


- `?=key_name?`


A special form of named place-holder includes an equals sign (`=`) before
the key name.  This place-holder does special handling for `NULL` values.
To specify a `NULL` value, use `\'NULL'` as the associated value (a SCALAR
reference to the string `'NULL'`).


So, a template line like:


    &   AND affil_parent ?=parent?


will become (if the 'parent' key is defined) either:


    AND affil_parent = ?


or


    AND affil_parent IS NULL


The second case (where the place-holder is replaced by `'IS NULL'`) happens
if `$data-`{parent}> is `\'NULL'` (ignoring case and external whitespace).
For this case, the list of query parameters is not added to.


The first case (where the place-holder is replaced by `'= ?'`) happens
if `$data-`{parent}> is not a reference (but is defined).  For this case,
`$data-`{parent}> (or just 'parent') is pushed onto the list of query
parameters.


- `?!key_name?`


A similar special form of named place-holder includes an exclamation point
(`!`) before the key name.  This place-holder similarly supports `\'NULL'`
as the associated value.  But this place-holder represents "distinct from"
(the opposite meaning compared to `?=key_name?`).  Note that actually using
"is distinct from" or "is not distinct from" in your template is discouraged
for these cases as the Postgres query optimizer can be hampered by such.


So, a template line like:


    &   AND affil_parent ?!parent?


will become (if the 'parent' key is defined) either:


    AND affil_parent <> ?


or


    AND affil_parent IS NOT NULL


The second case (where the place-holder is replaced by `'IS NOT NULL'`)
happens if `$data-`{parent}> is `\'NULL'` (ignoring case and external
whitespace).  For this case, the list of query parameters is not added to.


The first case (where the place-holder is replaced by `'<> ?'`)
happens if `$data-`{parent}> is not a reference (but is defined).  For
this case, `$data-`{parent}> (or just 'parent') is pushed onto the list
of query parameters.


- `?@key_name?`


A place-holder with an at sign (like `?@key_name?`) requires that the
associated value be an ARRAY reference but otherwise behaves identically
to a plain, named placed-holder.  DBD::Pg will treat the array reference
as a Postgres array value.


There are a few gotchas with using Postgres array values and `?@key_name?`
so let's give an example of typical usage.  First, let's show the typical
case that one would end up replacing with a use of `?@key_name?`:


    push @where, 'account_id IN (' . join(',',('?')x@sub_accts) . ')';
    push @param, @sub_accts;
    # ...
        join( ' AND ', @where )
    # ...


which ends up generating SQL that includes something like:


    ... AND account_id IN (?,?,?,?,?) AND ...


where the number of `'?'`s matches the number of elements in `@sub_accts`.


The SQL we want to generate to use a Postgres array value instead would be:


    ... AND ARRAY[account_id] <@ ? AND ...


`ARRAY[account_id]` makes a Postgres array value containing a single value
(the value of account\_id).  `<@` means "is contained in".  And the `?`
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


Note how I had to put a backslash (`\`) in front of the at sign in
`?\@sub_accts?` because my SQL template string was enclosed in double
quotes.  If I hadn't done that, the query would not have worked.  Luckily,
build\_query() would almost certainly have complained because that line had
a `'&'` tag but no named place-holders.


Note that a reference to an _empty_ array would mean that


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


- `?"key_name?`


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


to only find items with a non-NULL affil\_parent if `$has_parent` is true and
vice versa.


### Special data values


The values in the `'data'` hash are usually expected to be strings (or maybe
numeric values).  But some other types of values are also handled by this
templating system.


- `undef()`


The named key being present but with an undefined value associated with it
causes the templating system to act the same as if the key were not present.


- `\$sql`


If the associated value for a named place-holder is a reference to a scalar,
then the referenced scalar is expected to contain a valid snippet of literal
SQL (similar to how AT::SQL and other helpers treat such SCALAR refs).  The
named place-holder will be replaced with the literal SQL (not with `'?'`)
and the list of query parameters will not be added to.


For `?=key_name?`, `'= '` will also be inserted just prior to the literal
SQL snippet, unless the snippet is equivalent to `NULL`, in which case it
will be preceded with `'IS '` instead.  While for `?!key_name?`, `'<` '>
will precede the snippet, except for `NULL` which will be preceded by
`'IS NOT '`.


For `?@key_name?`, a reference to a scalar is a fatal error.


For dependency markers, the value being a reference does not (currently)
matter.


- `\'NULL'`


A reference to a string of `'NULL'` (ignoring case and external whitespace)
is treated differently from a reference to some other snippet of SQL only for
the `?=key_name?` and `?!key_name?` place-holders (as documented elsewhere).


- `\@list`


DBD::Pg can use ARRAY references to represent a Postgres array value,
including in a query parameter.  So it is good to allow an array reference
as a data value.  However, it is quite hard to imagine a spot in an SQL
template where a Postgres array and a non-array value would both be
equally valid.


So we require you to declare whether or not you expect the place-holder to
take an ARRAY reference.  `?@key_name?` requires an array reference.  Other
place-holders treat an array reference as a fatal error.


- Stringifier


If a data value is a reference to a blessed object that overloads
stringification, then no special behavior is triggered.  The object may
be pushed onto the list of query parameters where it will likely later
be stringified.


In such a case, the blessed object being a reference to a SCALAR or to an
ARRAY will be ignored.  So, for example, a blessed reference to an ARRAY
that overloads stringification is a fatal error for a `?@key_name?`
place-holder.


- Other references


Other types of references are treated as fatal errors by named place-holders.
Dependency markers currently treat any kind of reference the same as a
non-reference.  But these behaviors should not be relied upon.


Future versions of this module may add additional special treatments for
different types of references, including changing how dependency markers
treat reference values.


### 'wanted' list / function


The `'wanted'` argument can be a reference to an array containing just the
custom tags whose lines should be included in the generated query.


For truly complicated cases, the `'wanted'` argument can be a CODE reference
that is called for each custom tag.  The associated line(s) will be included
in the generated query if and only if the sub returns a true value for that
tag.


A `'wanted'` function takes two arguments: a tag and the `'data'` hash-ref.


For example, here is one that includes lines for tags that are the same as any
(lower-case) `'data'` hash key having a defined value:


    wanted => sub {
        my( $tag, $data ) = @_;
        return defined $data->{ lc $tag };
    },


Here is a more complex example.  Not that this is a great example of
a case where a `'wanted'` _function_ is preferred over a simpler
`'wanted'` _list_.  But it _is_ a good example of a relatively sane
`'wanted'` function that also avoids the example being extremely complex.


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


This is also the our only example that makes use of the `'|'` tag.


## Caution


Conditional generation of SQL is a problem with many bad solutions and no
really good ones.  This library attempts to offer a solid less-bad solution
that keeps SQL near the surface and favors simplicity and readability over
enforced correctness.  If you want correctness, you will have to provide it
yourself.


Don't get too fancy with your 'wanted' subroutines.


Pay attention to your `AND`s, `OR`s, and other joining words / characters.


# EXPORTS


NONE, but please include the empty list when you `use` the module:


    use DBIx::PreQL ();


so the fact that nothing is being imported is obvious to the person reading
that code.


# SUBROUTINES


## build\_query()


build\_query is called as a class method with arguments in name/value pairs:


    ( $query, @params ) = DBIx::PreQL->build_query(
        query       => $template_string,
        data        => \%data,
        wanted      => \@wanted_tags,
        known_tags  => \@tag_list,
        keep_keys   => $boolean,
    );


Most of the prior documentation covers the details of using this method, the
only functionality provided by this module.


### Arguments:


- query


Required.  A string of several (tagged) lines that is your query template.
You can also pass a reference to an array of lines.


- data


Virtually required.  A reference to a hash whose keys can be referenced in
your query template and whose values can end up in the resulting parameter
list (or even incorporated into the generated SQL).


Technically, you don't have to provide a `'data'` argument.  But not
providing one rather severely restricts your templating options and so
is a rather unlikely scenario.


- wanted


This argument is required if you use any custom tags.  This argument is
ignored otherwise.


Either 1) a reference to an array containing the list of (custom) tags whose
lines should be included in the generated SQL.


Or 2) a reference to a subroutine that will be passed a `$tag` and the
`'data'` hash-ref and that returns a true value if lines having that `$tag`
should be included (and returns a false value if such lines should be
excluded).


- known\_tags


Optional.  A reference to an array of custom tag strings.  Used to catch
typos when composing custom tags.  Finding a custom tag not in this list is
a fatal error.  Having a tag in this list that is never found is a warning.


- keep\_keys


Optional.  A boolean value.  Unlikely to be used.


When true, place-holder names (the _keys_ to the `'data'` hash-ref) are
what get pushed onto the query parameter list.  When false (the default),
what gets pushed onto the query parameter list are the _values_ from the
`'data'` hash-ref.


Returns a string which is the generated SQL query and a list of query
parameters to be used with that query.

