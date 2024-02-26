# NAME

Data::Transfigure - performs rule-based data transfigurations of arbitrary structures

# SYNOPSIS

    use Data::Transfigure;

    my $d = Data::Transfigure->std();
    $d->add_transfigurators(qw(
      Data::Transfigure::Type::DateTime::Duration
      Data::Transfigure::HashKeys::CamelCase
    ), Data::Transfigure::Type->new(
      type    => 'Activity::Run'.
      handler => sub ($data) {
        {
          start    => $data->start_time, # DateTime
          time     => $data->time,       # DateTime::Duration
          distance => $data->distance,   # number
          pace     => $data->pace,       # DateTime::Duration
        }
      }
    ));

    my $list = [
      { user_id => 3, run  => Activity::Run->new(...) },
      { user_id => 4, ride => Activity::Ride->new(...) },
    ];

    $d->transfigure($list); # [
                          #   {
                          #     userID => 3
                          #     run    => {
                          #                 start    => "2023-05-15T074:11:14",
                          #                 time     => "PT30M5S",
                          #                 distance => "5",
                          #                 pace     => "PT9M30S",
                          #               }
                          #   },
                          #   {
                          #     userID => 4,
                          #     ride   => "Activity::Ride=HASH(0x2bbd7d16f640)",
                          #   },
                          # ]

# DESCRIPTION

`Data::Transfigure` allows you to write reusable rules ('transfigurators') to modify
parts (or all) of a data structure. There are many possible applications of this,
but it was primarily written to handle converting object graphs of ORM objects
into a structure that could be converted to JSON and delivered as an API endpoint
response. One of the challenges of such a system is being able to reuse code
because many different controllers could need to convert the an object type to
the same structure, but then other controllers might need to convert that same
type to a different structure.

A number of transfigurator roles and classes are included with this distribution:

- [Data::Transfigure::Node](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ANode)
the root role which all transfigurators must implement
- [Data::Transfigure::Default](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ADefault)
a low priority transfigurator that only applies when no other transfigurators do
- [Data::Transfigure::Default::ToString](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ADefault%3A%3AToString)
a transfigurator that stringifies any value that is not otherwise transfigured
- [Data::Transfigure::Type](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AType)
a transfigurator that matches against one or more data types
- [Data::Transfigure::Type::DateTime](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AType%3A%3ADateTime)
transfigures DateTime objects to [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) 
format.
- [Data::Transfigure::Type::DateTime::Duration](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AType%3A%3ADateTime%3A%3ADuration)
transfigures [DateTime::Duration](https://metacpan.org/pod/DateTime%3A%3ADuration) objects to 
[ISO8601](https://en.wikipedia.org/wiki/ISO_8601#Durations) (duration!) format
- [Data::Transfigure::Type::DBIx](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AType%3A%3ADBIx)
transfigures [DBIx::Class::Row](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ARow) instances into hashrefs of colname->value 
pairs. Does not recurse across relationships
- [Data::Transfigure::Type::DBIx::Recursive](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AType%3A%3ADBIx%3A%3ARecursive)
transfigures [DBIx::Class::Row](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ARow) instances into hashrefs of colname->value pairs,
recursing down to\_one-type relationships
- [Data::Transfigure::Value](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AValue)
a transfigurator that matches against data values (exactly, by regex, or by coderef 
callback)
- [Data::Transfigure::Position](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3APosition)
a compound transfigurator that specifies one or more locations within the data 
structure to apply to, in addition to whatever other criteria its transfigurator 
specifies
- [Data::Transfigure::Tree](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ATree)
a transfigurator that is applied to the entire data structure after all 
node transfigurations have been completed
- [Data::Transfigure::HashKeys::CamelCase](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AHashKeys%3A%3ACamelCase)
a transfigurator that converts all hash keys in the data structure to 
lowerCamelCase
- [Data::Transfigure::HashKeys::SnakeCase](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AHashKeys%3A%3ASnakeCase)
a transfigurator that converts all hash keys in the data structure to 
snake\_case
- [Data::Transfigure::HashKeys::CapitalizedIDSuffix](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3AHashKeys%3A%3ACapitalizedIDSuffix)
a transfigurator that converts "Id" at the end of hash keys (as results from 
lowerCamelCase conversion) to "ID"

# CONSTRUCTORS

## Data::Transfigure->new()

Constructs a new default instance that pre-adds 
[Data::Transfigure::Default::ToString](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ADefault%3A%3AToString) to stringify values that are not otherwise
transfigured by user-provided transfigurators. Preserves (does not transfigure to 
empty string) undefined values.

## Data::Transfigure->bare()

Returns a "bare-bones" instance that has no builtin data transfigurators.

## Data::Transfigure->dbix()

Adds [Data::Transfigure::DBIx::Recursive](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ADBIx%3A%3ARecursive) to to handle `DBIx::Class` result rows

# METHODS

## add\_transfigurators( @list )

Registers one or more data transfigurators with the `Data::Transfigure` instance.

    $t->add_transfigurators(Data::Transfigure::Type->new(
      type    => 'DateTime',
      handler => sub ($data) {
        $data->strftime('%F')
      }
    ));

Each element of `@list` must implement the [Data::Transfigure::Node](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3ANode) role, though
these can either be strings containing class names or object instances.

`Data::Transfigure` will automatically load class names passed in this list and 
construct an object instance from that class. This will fail if the class's `new`
constructor does not exist or has required parameters.

    $t->add_transfigurators(qw(Data::Transfigure::Type::DateTime Data::Transfigure::Type::DBIx));

ArrayRefs passed in this list will be expanded and their contents will be treated
the same as any item passed directly to this method.

    my $default = Data::Transfigure::Type::Default->new(
      handler => sub ($data) {
        "[$data]"
      }
    );
    my $bundle = [q(Data::Transfigure::Type::DateTime), $default];
    $t->add_transfigurators($bundle);

When transfiguring data, only one transfigurator will be applied to each data element,
prioritizing the most-specific types of matches. Among transfigurators that have 
equal match types, those added later have priority over those added earlier.

## add\_transfigurator\_at( $position => $transfigurator )

`add_transfigurator_at` is a convenience method for creating and adding a 
positional transfigurator (one that applies to a specific data-path within the given
structure) in a single step.

See [Data::Transfigure::Position](https://metacpan.org/pod/Data%3A%3ATransfigure%3A%3APosition) for more on positional transfigurators.

## transfigure( $data )

Transfigures the data according to the transfigurators added to the instance and 
returns it. The data structure passed to the method is unmodified.

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
