.. include:: ../../common.defs

.. _lang-expressions:

Expressions
***********

:index:`Expressions <expression>` are the basis of the |RB| language; one or
more parentheses enclosed lists, which may be nested, of elements which form a
statement to be evaluated. In |RB| parlance, an expression is a specific style
of a list: one whose initial element is a function or macro.

The difference, then, between a plain list and an expression is that a list
returns its contents as presented, whereas an expression invokes the function
or macro named by its first element and passed the remainder of its contents
(after any evaluations necessary for unquoted nested expressions) as arguments.

For example, the following is an expression consisting of three elements::

    (+ 1 2)

The first element is the function :ref:`function-core-math-num-plus`. The second
and third elements are the integers one and two, respectively. We could express
the same as::

    (+ 1 (+ 1 1))

Which replaces the third element in our earlier example with a nested expression
that happens to, when evaluated, return the value ``2``. Note that except for a
limited set of special forms, nested expressions are evaluated as they are
encountered. Quoting an expression does not currently lead to the consistent
behavior that users familiar with Lisp languages would expect (preventing the
expression or list from being evaluated until explicitly unquoted/eval'ed).
Future versions of |RB| are intended to correct this and bring even more
consistency to the language.

The next example, while it looks similar to the expressions above, is not an
expression but simply a list -- as the first element is not a function or macro
name::

    (1 2)

It is, however, still a valid syntactical structure which may be fed to |RB|.
But because there is no function or macro to evaluate, the list will return
itself rather than some computed value or function result.
