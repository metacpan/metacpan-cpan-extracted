.. include:: ../common.defs

.. _ch-lang:

Language
********

|RB| uses an S-expression based, Lisp-like (heavy emphasis on the "like")
language for interaction. S-expressions are nested, list-based statements in
which an operator and a variable number of operands (both sometimes referred to
as *atoms*) are enclosed in parentheses to delimit a single statement. Operands
may themselves be S-expressions.

This basic form is extended in |RB| to support explicit definition of a handful
of simple data structures, which are explained in the following sections. |RB|
uses the common prefix notation style, in which expressions (those lists which
contain a function or macro to execute) always begin with the function/macro
followed by its arguments as the operands.

.. toctree::

   expr/index
   types/index
   scopes/index
