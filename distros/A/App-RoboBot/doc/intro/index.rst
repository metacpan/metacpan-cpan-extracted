.. include:: /common.defs

.. _ch-intro:

Introduction
************

|RB| is a multi-protocol chat bot that uses an S-Expression syntax for user
interaction. Developed in Perl, it presents a very simplified Lisp-\ *like*
language, allowing for on-the-fly customization of the bot's features and
behavior.

.. _intro-features:

Features
========

The notable features of |RB| include:

Programmability
    Using an S-Expression syntax, |RB| can be programmed on-the-fly by users on
    your chat servers to perform a dizzying variety of actions.

Multi-Protocol
    Support for multiple chat protocols is baked in. |RB| currently comes with
    IRC, Slack, and Mattermost support, but additional protocols can be added
    quite easily.

Multi-Network
    There are no built-in limits to the number of networks and channels to
    which an instance of the bot may connect at once. Nor do all of those
    connections need to be on the same protocol. Additionally, features may
    be disabled or enabled on a per-network basis, all within the same bot
    instance.

Access Control
    Rudimentary access control to built in functions and macros is available.
    While only as good as your chat network's ability to identify and restrict
    user handles, the control lists permit you to keep less well-mannered users
    away from potentially disruptive functionality.


.. _intro-contribute:

Contribute
==========

|RB| is open-source, and the project source is currently hosted on GitHub at
https://github.com/jsime/robobot.

Please open issues if you encounter bugs or would like to see additional
features. Better yet, submit a pull request!

There are no mailing lists or official IRC channels for the project at this
time.

