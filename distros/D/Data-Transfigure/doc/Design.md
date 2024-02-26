# Overview

Data::Transfigure is a perl module for applying simple, reusable, context-aware
transfigurations to arbitrarily complex data structures.

# Context

This module is designed to be as general as possible to facilitate any sort of
data transfiguration context. While users are free to enhance its abilities by
providing their own transfigurators, it does bundle a small number of them to
address specific scenarios as an example/convenience.

# Goals

To accept a data structure (which could be as simple as a single element),
process it, and return a new data structure in a desired format.

Also, to permit the use of modules ("transfigurators") to perform specific
transfiguration tasks in a way that is compartmentalized, reusable, and largely
declarative.

Further, to allow transfigurators to override previously-defined and less-specific
transfigurators so as to facilitate greater code reuse, e.g., by having a standard
set of transfigurators "app-wide" and then overriding one or more specific
transfigurators when needed.

And finally, to facilitate extension of transfigurators through standard OOP
principles to customize and modify behaviors in a code-minimal manner.

# Non-Goals

There is no goal to have comprehensive or all-encompassing coverage of even
simple transfigurator types bundled into this module.

# Implementation

Object::Pad was selected as the OOP paradigm for this module for its similarity
with perlclass, but at this time being more featureful in ways that were needed
to implement necessary inheritence/composition (namely that perlclass does not
(yet?) expose the functionality for a subclass to satisfy parameter requirements
of its parent.)

Data::Transfigure is the main module of this package, providing the functionality
for registering transfigurators and transfiguring data structures.

Data::Transfigure::Node provides a role which must be composed by any transfigurator
in order to be registerable with Data::Transfigure.

Likewise, Data::Transfigure::Tree provides a role to be composed by transfigurators
used for postprocessing. These are applied after all node transfigurations, and
they receive the entire data structure rather than just a single node at a time.

The other classes included with this package compose Data::Transfigure::Node or
Data::Transfigure::Tree to provide convenient bases to instantiate and/or
subclass.

transfiguration works by iterating through all registered "general"
(meaning not the 3 cases listed above) transfigurators and determining their
`applies_to` value for a particular node/position in the data graph. `applies_to`
returns a constant from `Data::Transfigure::Constants`. Those that return
`$NO_MATCH` are ignored, and the remainder are sorted by match value
(higher being better) and then by order of being registered, so that later
additions can override previous ones. The best match is then selected, and used
to transfigure that node via the transfigurator's `transfigure` method.

# Implementation Details

`Data::Transfigure::Type::DBIx::Recursive` is a substantial improvment over the
plain `::DBIx` transfigurator, but still has a significant limitation in that it
can only traverse `to_one`-type data links. This is due to the fact that
`to_many` links are not distinguished between parent and child relationships, so
following them rapidly leads to infinite loops that would require substantially
more domain-specific coding, outside of the transfigurator itself, to handle.
