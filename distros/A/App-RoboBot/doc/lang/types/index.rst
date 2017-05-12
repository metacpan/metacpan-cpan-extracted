.. include:: ../../common.defs

Types
*****

|RB| supports the concept of distinct data types, beyond just free-form strings
and various functions may expect, or only operate on, a given type. There is no
strong type system in |RB|, certainly not one that allows for type signatures
on functions and macros, so all type checking is loosely performed at run-time.

It is entirely possible to write a macro, for instance, that is provably wrong.
But the proof won't be provided until the macro blows up when you try to use it.
Perhaps future versions of |RB| will formalize this.

Functions
=========

Functions are provided by plugins installed with your instance of |RB| and not
explicitly disabled in your configuration file. Functions may not be modified
by users, nor may new ones be created without writing a plugin to export them.

Functions are invoked by using them as the leading atom of a list (thus making
that list an expression), as so::

    (my-cool-function "foo")
    "I just did something with foo!"

Which invokes the ``my-cool-function`` function, providing it with a single
string argument of ``foo``. Some functions take functions as their arguments

Macros
======

Macros bear striking resemblance in their operation to functions, with the most
distinguishing feature being that macros are user-defined by anyone on your
connected chat networks with access to the :ref:`function-core-macro-defmacro`
function. They exist within the :ref:`lang-scope-network`, and may be updated
and invoked at will using the same, fundamental S-expression syntax used
everywhere else. For example::

    (defmacro my-cool-macro [input-string]
        '(format "I just did something with %s!" input-string))
    (my-cool-macro "foo")
    "I just did something with foo!"

Numerics
========

Strings
=======

.. _types-symbol:

Symbols
=======



.. _types-vector:

Vectors
=======

Vectors are lists of items, enclosed in square brackets::

    [a b c]

The preceding vector contains 3 items: ``a``, ``b``, and ``c``. Vectors may
contain any other type, even other vectors, as so::

    [a b [1 2 3] c]

There is no hard limit on nesting, nor do the types of every vector entry need
to match.

.. _types-set:

Sets
====

Sets, like :ref:`vectors <types-vector>`, are lists of items - except inside
vertical pipes.  Unlike a vector, a set will not contain any duplicate entries.
Constructing a set with::

    |1 2 3 3 3|

Will result in the set::

    |1 2 3|

Note that, unless quoted, entries are evaluated during assignment. So, creating
a set with a few numbers, for example, and an expression which returns one of
those same numbers, will not result in duplicate values, nor will the expression
itself be in the set (again, unless it was quoted). Thus::

    |1 2 3 (+ 1 2)|

Still results in the set::

    |1 2 3|

.. _types-map:

Maps
====

Lists of key-value pairs -- somewhat similar to dictionaries, hashes, and
associative arrays in other languages -- are supported in |RB| as maps. The map
keys are :ref:`symbols <types-symbol>` and the values may be of any type,
including nested structures that are evaluated according to all the normal
rules.

Maps are enclosed in curly braces::

    { :key-1 "value" :key-2 "another value" }

As mentioned, nested structures for the values are acceptable::

    { :some-key { :another-key (+ 1 2) } }

