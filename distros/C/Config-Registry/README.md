# NAME

Config::Registry - Settings bundler.

# SYNOPSIS

## Create a Schema Class

```perl
package Org::Style;
use strictures 2;

use Types::Standard qw( Str );

use Moo;
use namespace::clean;

extends 'Config::Registry';

__PACKAGE__->schema({
  border_color => Str,
});

1;
```

## Create a Document Class

```perl
package MyApp::Style;
use strictures 2;

use Moo;
use namespace::clean;

extends 'Org::Style';

__PACKAGE__->document({
  border_color => '#333',
});

__PACKAGE__->publish();

1;
```

## Use a Document Class

```perl
use MyApp::Style;

my $style = MyApp::Style->fetch();

print '<table style="border-color:' . $style->border_color() . '">';
```

# SYNOPSIS

This module provides a framework for a pattern we've seen emerge in
ZipRecruiter code as we've been working to separate our monolithic
application into smaller and more manageable code bases.

The concept is pretty straightforward.  A registry consists of a
schema class and one or more document classes.  The schema is used to
validate the documents, and the documents are used to configure the
features of an application.

# SCHEMAS

```perl
__PACKAGE__->schema({
  border_color => Str,
});
```

The schema is a hash ref of attribute name and [Type::Tiny](https://metacpan.org/pod/Type::Tiny) pairs.
These pairs get turned into required [Moo](https://metacpan.org/pod/Moo) attributes when
["publish"](#publish) is called.

Top-level schema keys may have a hash ref, rather than a type, as
their value.  This hash ref will be used directly to construct the
[Moo](https://metacpan.org/pod/Moo) attribute.  The `required` option defaults on, and the `is`
option default to `ro`.  You can of course override these in the
hash ref.

For example, the above code could be written as:

```perl
__PACKAGE__->schema({
  border_color => { isa => Str },
});
```

The attribute can be made optional by passing an options hash ref:

```perl
__PACKAGE__->schema({
  border_color => { isa => Str, required => 0 },
});
```

Non-top level keys can be made optional using [Type::Standard](https://metacpan.org/pod/Type::Standard)'s
`Optional` type modifier:

```perl
__PACKAGE__->schema({
  border_colors => Dict[
    top    => Optional[ Str ],
    right  => Optional[ Str ],
    bottom => Optional[ Str ],
    left   => Optional[ Str ],
  ],
});
```

See ["Create a Schema Role"](#create-a-schema-role) for a complete example.

# DOCUMENTS

```perl
__PACKAGE__->document({
  border_color => '#333',
});
```

A document is a hash ref of attribute name value pairs.

A document is used as the default arguments when `new` is called
on the registry class.

See ["Create a Document Class"](#create-a-document-class) for a complete example.

# PACKAGE METHODS

## schema

```
__PACKAGE__->schema( \%schema );
```

Sets the schema hash ref.  If a schema hash ref has already been
set then ["merge"](#merge) will be used to combine the passed in schema with
the existing schema.

See ["SCHEMAS"](#schemas) for more information about the schema hash ref
itself.

## document

```
__PACKAGE__->document( \%doc );
```

Sets the document hash ref.  If a document hash ref has already been
set then ["merge"](#merge) will be used to combine the passed in document with
the existing document.

See ["DOCUMENTS"](#documents) for more information about the document hash ref
itself.

## publish

```
__PACKAGE__->publish();
```

Turns the ["schema"](#schema) hash ref into [Moo](https://metacpan.org/pod/Moo) attributes and enables the
registry class to be instantiated.

## merge

```perl
my $new_schema = $class->merge( $schema, $extra_schema );
```

This utility method does a `RIGHT_PRECEDENT` [Hash::Merge](https://metacpan.org/pod/Hash::Merge) and is
made available for those jobs that require a bit more customization
when building the schema and/or documents.

## render

```perl
my $document = $class->render( $raw_document );
```

Like ["merge"](#merge), this method is made available as a spot for subclasses
to customize behavior.  The default render method just returns what is
passed to it.  As an example, this method could be customized to pass
the schema and document data structures through [Data::Xslate](https://metacpan.org/pod/Data::Xslate).

# SUPPORT

Please submit bugs and feature requests to the
Config-Registry GitHub issue tracker:

[https://github.com/bluefeet/Config-Registry/issues](https://github.com/bluefeet/Config-Registry/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/) for
encouraging their employees to contribute back to the open source
ecosystem.  Without their dedication to quality software development
this distribution would not exist.

# AUTHOR

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# COPYRIGHT AND LICENSE

Copyright (C) 2020 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
