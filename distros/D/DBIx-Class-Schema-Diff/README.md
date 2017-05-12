[![Coverage Status](https://coveralls.io/repos/vanstyn/DBIx-Class-Schema-Diff/badge.png?branch=master)](https://coveralls.io/r/vanstyn/DBIx-Class-Schema-Diff?branch=master)

## NAME

DBIx::Class::Schema::Diff - Identify differences between two DBIx::Class schemas

## SYNOPSIS

    use DBIx::Class::Schema::Diff;

    # Create new diff object using schema class names:
    my $D = DBIx::Class::Schema::Diff->new(
      old_schema => 'My::Schema1',
      new_schema => 'My::Schema2'
    );
    
    # Create new diff object using schema objects:
    $D = DBIx::Class::Schema::Diff->new(
      old_schema => $schema1,
      new_schema => $schema2
    );
    
    # Dump current schema data to a json file for later use:
    $D->old_schema->dump_json_file('/tmp/my_schema1_data.json');
    
    # Or
    DBIx::Class::Schema::Diff::SchemaData->new(
      schema => 'My::Schema1'
    )->dump_json_file('/tmp/my_schema1_data.json');
    
    # Create new diff object using previously saved 
    # schema data + current schema class:
    $D = DBIx::Class::Schema::Diff->new(
      old_schema => '/tmp/my_schema1_data.json',
      new_schema => 'My::Schema1'
    );
    

Filtering the diff:

    # Get all differences (hash structure):
    my $hash = $D->diff;
    
    # Only column differences:
    $hash = $D->filter('columns')->diff;
    
    # Only things named 'Artist' or 'CD':
    $hash = $D->filter(qw/Artist CD/)->diff;
    
    # Things named 'Artist', *columns* named 'CD' and *relationships* named 'columns':
    $hash = $D->filter(qw(Artist columns/CD relationships/columns))->diff;
    
    # Sources named 'Artist', excluding column changes:
    $hash = $D->filter('Artist:')->filter_out('columns')->diff;
    
    if( $D->filter('Artist:columns/name.size')->diff ) {
     # Do something only if there has been a change in 'size' (i.e. in column_info)
     # to the 'name' column in the 'Artist' source
     # ...
    }
    
    # Names of all sources which exist in new_schema but not in old_schema:
    my @sources = keys %{ 
      $D->filter({ source_events => 'added' })->diff || {}
    };
    
    # All changes to existing unique_constraints (ignoring added or deleted)
    # excluding those named or within sources named Album or Genre:
    $hash = $D->filter_out({ events => [qw(added deleted)] })
              ->filter_out('Album','Genre')
              ->filter('constraints')
              ->diff;
    
    # All changes to relationship attrs except for 'cascade_delete' in 
    # relationships named 'artists':
    $hash = $D->filter_out('relationships/artists.attrs.cascade_delete')
              ->filter('relationships/*.attrs')
              ->diff;

## DESCRIPTION

General-purpose schema differ for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) to identify changes between two DBIC Schemas. 
Currently tracks added/deleted/changed events and deep diffing across 5 named types of source data:

- columns
- relationships
- constraints
- table\_name
- isa

The changes which are detected are stored in a HashRef which can be accessed by calling 
[diff](https://metacpan.org/pod/DBIx::Class::Schema::Diff#diff). This data packet, which has a format that is specific to 
this module, can either be inspected directly, or _filtered_ to be able to check for specific 
changes as boolean test(s), making it unnecessary to know the internal diff structure for many 
use-cases (since if there are no changes, or no changes left after being filtered, `diff` returns 
false/undef - see the [FILTERING](https://metacpan.org/pod/DBIx::Class::Schema::Diff#FILTERING) section for more info).

This tool attempts to be simple and flexible with a straightforward, "DWIM" API. It is meant
to be used programmatically in dynamic scenarios where schema changes are occurring but are not well
suited for [DBIx::Class::Migration](https://metacpan.org/pod/DBIx::Class::Migration) or [DBIx::Class::DeploymentHandler](https://metacpan.org/pod/DBIx::Class::DeploymentHandler) for whatever reasons, or
some other event/action needs to take place based on certain types of changes (note that this tool 
is NOT meant to be a replacement for Migrations/DH). 

It is also useful as a general debugging/development tool, and was designed with this in mind to 
be "handy" and not need a lot of setup/RTFM to use.

This tool is different from [SQL::Translator::Diff](https://metacpan.org/pod/SQL::Translator::Diff) in that it compares DBIC schemas at the 
_class/code_ level, not the underlying DDL, nor does it attempt to modify one schema to match
the other (although, it could certainly be used to write a tool that did).

## METHODS

### new

Create a new DBIx::Class::Schema::Diff instance. The following build options are supported:

- old\_schema

    The "old" (or left-side) schema to be compared. 

    Can be supplied as a [DBIx::Class::Schema](https://metacpan.org/pod/DBIx::Class::Schema) class name, connected schema object instance, 
    or previously saved [SchemaData](https://metacpan.org/pod/DBIx::Class::Schema::Diff::SchemaData) which can be 
    supplied as an object, HashRef, or a path to a file containing serialized JSON data (as 
    produced by [DBIx::Class::Schema::Diff::SchemaData#dump\_json\_file](https://metacpan.org/pod/DBIx::Class::Schema::Diff::SchemaData#dump_json_file))

    See the SYNOPSIS and [DBIx::Class::Schema::Diff::SchemaData](https://metacpan.org/pod/DBIx::Class::Schema::Diff::SchemaData) for more info.

- new\_schema

    The "new" (or right-side) schema to be compared. Accepts the same dynamic type options 
    as `old_schema`.

### diff

Returns the differences between the two schemas as a HashRef structure, or `undef` if there are 
none.

The HashRef is divided first by source name, then by type, with the special `_event` key 
identifying the kind of modification (added, deleted or changed) at both the source and the type 
level. For 'changed' events within types, a deeper, type-specific diff HashRef is provided (with 
column\_info/relationship\_info diffs generated using [Hash::Diff](https://metacpan.org/pod/Hash::Diff)).

Here is an example of what a diff packet (with a sampling of lots of different kinds of changes) 
might look like:

    # Example diff with sample of all 3 kinds of events and all 5 types:
    {
      Address => {
        _event => "changed",
        isa => [
          "-Some::Removed::Component",
          "+Test::DummyClass"
        ],
        relationships => {
          customers2 => {
            _event => "added"
          },
          staffs => {
            _event => "changed",
            diff => {
              attrs => {
                cascade_delete => 1
              }
            }
          }
        }
      },
      City => {
        _event => "changed",
        table_name => "city1"
      },
      FilmCategory => {
        _event => "changed",
        columns => {
          last_update => {
            _event => "changed",
            diff => {
              is_nullable => 1
            }
          }
        }
      },
      FooBar => {
        _event => "added"
      },
      FooBaz => {
        _event => "deleted"
      },
      Store => {
        _event => "changed",
        constraints => {
          idx_unique_store_manager => {
            _event => "added"
          }
        }
      }
    }

### filter

Accepts filter argument(s) to restrict the differences to consider and returns a new `Schema::Diff` 
instance, making it chainable (much like [ResultSets](https://metacpan.org/pod/DBIx::Class::ResultSet#search_rs)).

See [FILTERING](https://metacpan.org/pod/DBIx::Class::Schema::Diff#FILTERING) for filter argument syntax.

### filter\_out

Works like `filter()` but the arguments exclude differences rather than restrict/limit to them.

See [FILTERING](https://metacpan.org/pod/DBIx::Class::Schema::Diff#FILTERING) for filter argument syntax.

## FILTERING

The [filter](https://metacpan.org/pod/DBIx::Class::Schema::Diff#filter) (and inverse 
[filter\_out](https://metacpan.org/pod/DBIx::Class::Schema::Diff#filter_out)) method is analogous to ResultSet's 
[search\_rs](https://metacpan.org/pod/DBIx::Class::ResultSet#search_rs) in that it is chainable (i.e. returns a new object 
instance) and each call further restricts the data considered. But, instead of building up an SQL 
query, it filters the data in the HashRef returned by [diff](https://metacpan.org/pod/DBIx::Class::Schema::Diff#diff). 

The filter argument(s) define an expression which matches specific parts of the `diff` packet. In 
the case of `filter()`, all data that **does not** match the expression is removed from the diff 
HashRef (of the returned, new object), while in the case of `filter_out()`, all data that **does** 
match the expression is removed.

The filter expression is designed to be simple and declarative. It can be supplied as a list of 
strings which match schema data either broadly or narrowly. A filter string argument follows this 
general pattern:

    '<source>:<type>/<id>'

Where `source` is the name of a specific source in the schema (either side), `type` is the 
_type_ of data, which is currently one of five (5) supported, predefined types: _'columns'_, 
_'relationships'_, _'constraints'_, _'isa'_ and _'table\_name'_, and `id` is the name of an 
item, specific to that type, if applicable. 

For instance, this expression would match only the _column_ named 'timestamp' in the source 
named 'Artist':

    'Artist:columns/timestamp'

Not all types have sub-items (only _columns_, _relationships_ and _constraints_). The _isa_ and 
_table\_name_ types are source-global. So, for example, to see changes to _isa_ (i.e. differences 
in inheritance and/or loaded components in the result class) you could use the following:

    'Artist:isa'

On the other hand, not only are there multiple _columns_ and _relationships_ within each source, 
but each can have specific changes to their attributes (column\_info/relationship\_info) which can 
also be targeted selectively. For instance, to match only changes in `size` of a specific column:

    'Artist:columns/timestamp.size'

Attributes with sub hashes can be matched as well. For example, to match only changes in `list` 
_within_ `extra` (which is where DBIC puts the list of possible values for enum columns):

    'Artist:columns/my_enum.extra.list'

The structure is specific to the type. The dot-separated path applies to the data returned by [column\_info](https://metacpan.org/pod/DBIx::Class::ResultSource#column_info) for columns and
[relationship\_info](https://metacpan.org/pod/DBIx::Class::ResultSource#relationship_info) for relationships. For instance, 
the following matches changes to `cascade_delete` of a specific relationship named 'some\_rel' 
in the 'Artist' source:

    'Artist:relationships/some_rel.attrs.cascade_delete'

Filter arguments can also match _broadly_ using the wildcard asterisk character (`*`). For 
instance, to match _'isa'_ changes in any source:

    '*:isa'

The system also accepts ambiguous/partial match strings and tries to "DWIM". So, the above can also 
be written simply as:

    'isa'

This is possible because 'isa' is understood/known as a _type_ keyword. Additionally, the system 
knows the names of all the sources in advance, so the following filter string argument would match 
everything in the 'Artist' source:

    'Artist'

Sub-item names are automatically resolved, too. The following would match any column, relationship, 
or constraint named `'code'` in any source:

    'code'

When you have schemas with overlapping names, such as a column named 'isa', you simply need to 
supply more specific match strings, as ambiguous names are resolved with left-precedence. So, to 
match any column, relationship, or constraint named 'isa', you could use the following:

    # Matches column, relationship, or constraints named 'isa':
    '*:*/isa'

Different delimiter characters are used for the source level (`':'`) and the type level (`'/'`) 
so you can do things like match any column/relationship/constraint of a specific source, such as:

    Artist:code

The above is equivalent to:

    Artist:*/code

You can also supply a delimiter character to match a specific level explicitly. So, if you wanted to
match all changes to a _source_ named 'isa':

    # Matches a source (poorly) named 'isa'
    'isa:'

The same works at the type level. The following are all equivalent

    # Each of the following 3 filter strings are equivalent:
    'columns/'
    '*:columns/*'
    'columns'

Internally, [Hash::Layout](https://metacpan.org/pod/Hash::Layout) is used to process the filter arguments.

### event filtering

Besides matching specific parts of the schema, you can also filter by _event_, which is either 
_'added'_, _'deleted'_ or _'changed'_ at both the source and type level (i.e. the event of a 
new column is 'added' at the type level, but 'changed' at the source level).

Filtering by event requires passing a HashRef argument to filter/filter\_out, with the special
`'events'` key matching 'type' events, and `'source_events'` matching 'source' events. Both accept
either a string (when specifying only one event) or an ArrayRef:

    # Limit type (i.e. columns, relationships, etc) events to 'added'
    $D = $D->filter({ events => 'added' });
    
    # Exclude added and deleted sources:
    $D = $D->filter_out({ source_events => ['added','deleted'] });
    
    # Also excludes added and deleted sources:
    $D = $D->filter({ source_events => ['changed'] });

## EXAMPLES

For examples, see the [SYNOPSIS](https://metacpan.org/pod/DBIx::Class::Schema::Diff#SYNOPSIS) and also the unit tests in `t/`
which has lots of working examples.

## BUGS/LIMITATIONS

I'm not aware of any bugs at this point (although I'm sure there are some), but there are 
several things to be aware of in general when using this tool that are worth mentioning:

- Firstly, the diff packet is _informational_ only; it does not contain the information needed to
"patch" anything, or see the previous and new values. It assumes you already/still have access to the
old and new schemas to look up this info yourself. Its main purpose is simply to _flag_ which 
items are changed.
- Also, there is no deeper "diff" for 'added' and 'deleted' events because it is redundant. For an 
added source, for example, you already know that every column, relationship, etc., that it contains 
is also "added" (depending on your definition of "added"), so these are not included in the diff 
for the purpose of reducing clutter. But, one side effect of this that you have to keep in mind is 
that when filtering for all changes to 'columns', for example, this will not include columns in 
added sources. This is just a design decision made early on (and it can't be both ways). It just 
means if you want to check for the expanded definition of 'modified' columns, which include 
added/deleted via a source, you must also test for added/deleted sources.

    In a later version, an additional layer of sugar methods could be added to provide convenient access
    to some of these concepts.

- Filter string arguments are _NOT_ glob patterns, so you can't do things like `'Arti*'` to match
sub-strings (this may be a worthwhile feature to add in a later version). The wildcard `*` applies
to whole items only.
- Also, the special `*` character can only be used in place of the predefined first 3 levels 
(`'*:*/*'`) and not within deeper column\_info/relationship\_info sub-hashes (so you can't match 
`'Artist:columns/foo.*.list'`). We're really splitting hairs at this point, but it is still worth 
noting. (Internally, [Hash::Layout](https://metacpan.org/pod/Hash::Layout) is used to process the filter arguments, so these limitations
have to do with the design of that package which provides more-useful flexibility in other areas)
- In many practical cases, differences in loaded components will produce many more changes than just
'isa'. It depends on whether or not the components in question change the column/relationship infos. 
One common example is [InflateColumn::DateTime](https://metacpan.org/pod/DBIx::Class::InflateColumn::DateTime) which sets 
inflator/deflators on all date columns. This is more of a feature than it is a limitation, but it 
is something to keep in mind. If one side loads a component(s) like this but the other doesn't, 
you'll have lots of differences to contend with that you might not actually care about. And, in 
order to filter out these differences, you have to filter out a lot more than 'isa', which is 
trivial. This is more about how DBIC works than anything else.

    One thing that I did to overcome this when there were lots of different loaded components that I
    couldn't do anything about was to deploy both sides to a temp SQLite file, then create new schemas
    (in memory) from those files with [Schema::Loader](https://metacpan.org/pod/DBIx::Class::Schema::Loader), using the same 
    options (and thus the same loaded components), and then run the diff on the two _new_ schemas. 
    This type of approach may not work or be appropriate in all scenarios; it obviously depends on 
    what exactly you are trying to accomplish.

## SEE ALSO

- [DBIx::Class](https://metacpan.org/pod/DBIx::Class)
- [SQL::Translator::Diff](https://metacpan.org/pod/SQL::Translator::Diff)
- [DBIx::Class::Migration](https://metacpan.org/pod/DBIx::Class::Migration)
- [DBIx::Class::DeploymentHandler](https://metacpan.org/pod/DBIx::Class::DeploymentHandler)

## AUTHOR

Henry Van Styn <vanstyn@cpan.org>

## COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
