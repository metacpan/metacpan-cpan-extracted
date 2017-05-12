.. include:: ../common.defs

.. _ch-cookbook:

Macro Cookbook
**************

This section provides examples for how to extend |RB| functionality on the fly
through the use of macros. Some of these examples are from real-world usage and
others are contrived examples. But all will hopefully contribute to aiming |RB|
users in the right direction when they choose to add their own functionality.

Thinge Macros
=============

The :ref:`module-fun-thinge` plugin makes it easy for users to store little
snippets of information -- URLs, quotes, jokes, and just about anything else
that will fit into a chat message -- and recall them later. New categories can
be added at any time. But the default behavior requires everyone to do a little
more typing than perhaps they really need to.

A pattern used by one instance of |RB| establishes the use of a macro-defining
macro. A master macro is used which takes the name of a new type of thinge that
users might want to start saving/retrieving, and that macro creates another
macro tailor-made for that new type of thinge.

Make-Thinge Macro
-----------------

This master macro is created which takes a single argument: the name of a type
of thinge for which to create a new convenience macro:

.. code-block:: clojure

    (defmacro make-thinge [ttype]
      '(defmacro ttype [&optional subcmd &rest vargs]
        '(cond
          (any (lower subcmd) ["add" "save"])
            (thinge-add ttype (join " " vargs))
          (any (lower subcmd) ["delete" "remove" "rm" "del"])
            (thinge-delete ttype vargs)
          (any (lower subcmd) ["find"])
            (thinge-find ttype vargs)
          (any (lower subcmd) ["tag"])
            (thinge-tag ttype vargs)
          (any (lower subcmd) ["untag"])
            (thinge-untag ttype vargs)
            (thinge ttype subcmd))))

Making Things with Make-Thinge
------------------------------

Now when a user decides they want to start saving links to cat pictures
(because Internet), they can do the following::

    (make-thinge catte)

This creates a new macro called ``(catte)`` which takes a variable list of
arguments and defines severale sub commands: ``add``, ``delete``, ``tag``,
``find``, and various aliases for them in case users sometimes forget which is
the right word.

Once created, the two commands become functionally identical, but the new macro
version is shorter is hopefully easier to remember and user::

    (thinge-add catte https://mysite.tld/my-beautiful-catte.png)
    (catte add https://mysite.tld/my-beautiful-catte.png)

Okay, perhaps not a life-changing improvement, but at least it's a demonstration
of macro-defining macros.


