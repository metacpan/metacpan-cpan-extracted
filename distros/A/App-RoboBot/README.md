# RoboBot

Pluggable chatbot written in Perl and using an S-Expression syntax for user
interaction. It currently includes native support for IRC, Slack, and Mattermost.

The official documentation site is https://robobot.automatomatromaton.com/ but
is still a work in progress.

## Installation

RoboBot is available through CPAN. You will need a modern Perl (5.20+) and a
working instance of PostgreSQL (9.4+), as well as a few system libraries for
its various dependencies, to install and run this program.

To get started, install RoboBot itself (this will also install all Perl
dependencies and may take quite a while on a fresh system):

```
cpanm App::RoboBot
```

Once RoboBot is installed, refer to the `robobot.conf.sample` configuration
example to get started configuring your bot instance for database access and
connecting to your preferred chat services. Note that you must create the
empty database in PostgreSQL, but RoboBot will take care of setting up the
entire schema for you once it is able to connect.

Once configured, you can run RoboBot with the following command:

```
robobot -c <path to your robobot.conf> -m
```

Note that the `-m` argument is required the first time you run the program
against a newly created database, as it enables the running of database
migrations. Since your DB will be empty, these migrations must be run for the
bot to work. On subsequent runs you can omit this flag if you don't want
unplanned upgrades to occur.

## Installing Development Versions

You will need a modern Perl (5.20+) and CPAN-Minus (`cpanm`). You'll also need
a GCC toolchain and a handful of libraries (libaspell, libssl, libxml2,
libcurl, and libev). Lastly (as if! there's always more!) you will need a
PostgreSQL server up and running (9.4+ recommended), with a blank database
created and configured to allow access from wherever you will be running
RoboBot.

Once those basic requirements are out of the way, follow these basic steps:

- Install Dist::Zilla via CPAN: `cpanm Dist::Zilla`.

- Clone this repository and cd to its base directory (where the dist.ini file
  is located): `git clone https://github.com/jsime/robobot.git && cd robobot`.

- Use Dist::Zilla to install a few of its plugins: `dzil authordeps | cpanm`.

- Install all of RoboBot's CPAN dependencies: `dzil listdeps | cpanm`. This
  will take a long time on a fresh system.

- Create a RoboBot configuration file to define what networks you wish it to
  connect to, how to access its database, etc. This distribution ships with a
  sample configuration, `robobot.conf.sample`, which you will find installed
  on your system as well as in the share/ directory of this repository.

- At this point, you can run RoboBot in-place from your Git clone  without
  having to fully install it: `dzil run bin/robobot -c <config file path> -m`.
  This is currently recommended, just in case there are any further significant
  changes to the distribution before its formal release, just so you don't have
  an outdated, pre-release version cluttering up your system.

## Main Features

### S-Expression Syntax

The command syntax for RoboBot is based on S-Expressions, familiar to anyone
with basic knowledge of Lisp style languages. RoboBot's syntax should not be
confused for an actual Lisp, however, as it does not implement many of the more
advanced features of a real Lisp - only a thin and cheap imitation of their
visual style.

Every expression is a list of symbols, strings, and/or numbers. That list may
contain any number of elements, from *0* to *n*. If the first element of the list
is a symbol that matches a function name, it is considered a function expression,
and the remainder of the list will be supplied to that function as its arguments.

List elements may themselves be expressions, permitting the nesting of function
calls. As a simple example, we can express the mathematical operations of "Add
the numbers two and three together, then multiply their sum by five" by writing
the following:

```
(* (+ 2 3) 5)
```

This syntax applies to all interactions with RoboBot, except in cases where a
plugin hooks into the pre-evaluation phase and parses text from the raw incoming
messages itself (see the *Karma* plugin for an example of parsing meaning from
the raw messages directly).

### Multi-Network

RoboBot can be configured to connect to many chat networks simultaneously, all
managed by the same parent process. The event loop is managed through AnyEvent
to provide a portable interface for possibly embedding RoboBot into other code
which uses any of the common Perl event libraries. Internally, RoboBot
constructs a new RoboBot::Network object (actually, a sub-class specific to the
protocol used by the individual networks) for each connection made. Aside from
memory and the volume of incoming messages, there is no real limit on the
number of networks a single instance of RoboBot may listen on.

### Multi-Protocol

RoboBot is not strictly limited to IRC. Any text-based chat protocol can be
supported via the network plugin interface. Out of the box, RoboBot supports
standard IRC networks (with or without SSL), the Slack RTM API, and Mattermost
WebSockets/Web Services APIs. A single instance of RoboBot may mix and match
connections to as many different chat protocols as you wish.

Other chat protocols, such as the various instant messaging platforms, could be
added fairly easily, providing there is already a CPAN module (compatible with
AnyEvent) or you are willing to write one. Network plugins need only implement
a handful of methods (connect, disconnect, join\_channel, and send) as well as
register any callbacks required to deal with messages coming in over the wire.
Any functionality beyond that is generally optional, though some protocols may
require some additional support (e.g. Slack support requires ID<->name mappings
via Slack API calls for both channels and participants).

### Plugins

The bulk of RoboBot's functionality is implemented through a generic plugin
interface, allowing developers to export functions for direct use by channel
members, or to hook into message and response parsing phases before and after
expression evaluation.

RoboBot itself handles all the work of parsing input, passing arguments between
functions, enforcing access restrictions, and properly formatting and limiting
its output back to channels or individual recipients. Plugin authors need only
focus on the implementation details of their specific functions.

Refer to the section *Developing Plugins* below for more details.

### Macros

RoboBot provides a basic evaluation-phase macro system, which permits any
authorized users to extend the functionality of RoboBot directly from channels
without having to author a plugin. Macros can invoke functions or other macros.
Macros can even define other macros.

```
(defmacro add-one [n] '(+ n 1))
(add-one 5)
6
```

### Message Variables

The Variables plugin provides functions for setting and unsetting variables in
the context of a single message. These variables may then be reused anywhere else
in the message, though they will be discarded at the end and no longer accessible
(or defined) for subsequent messages.

Currently, you may not store a function in a variable (only the result of the
function), though support for functions as variables is planned for a future
release.

### Programmability

Combining the features already mentioned, RoboBot provides what amounts to a full
(though fairly simplified) programming environment within each message sent to
it. Variable state is reset with every message (unless a plugin were written to
provide a state-preserving feature), so programs are effectively limited to the
size of your chat server's message limit (typically a few hundred characters on
IRC, or about 16 kilobytes on Slack; other networks will vary).

But between the built-in functions, and the writing of macros by users, it is in
theory possible to develop non-trivial functionality entirely within the context
of a chat message.

### Access Control

RoboBot provides basic access control functionality, allowing you to define who
is permitted to call individual functions. It is recommended that sensitive
functions (such as those granting operator status, changing topics, and particularly
those allowing modification of the access control lists) be restricted to only
trusted users.

Access is granted/revoked by chat nickname, which means the controls are only as
good as your chat server's ability to authenticate/identify nicks. This should by
no means be considered a very strong access control mechanism.

### Legacy Bang Syntax

Admittedly, the S-Expression syntax can be a bit of a hurdle for new users. To
ease the introduction of RoboBot's functionality, a simplified alternate syntax
is supported. Functions and macros may be invoked without the parenthetical
expressions by simply prefacing the function or macro name with an exclamation
mark. Arguments follow as they normally would in the list context, separated by
whitespace (single multi-word arguments can still be double-quoted).

```
!roll 20 2
```

Is equivalent to:

```
(roll 20 2)
```

This simplified syntax does not currently support passing return values to other
functions or macros, however. For that, and more complicated usage, the full
S-Expression syntax is required.

## Developing Plugins

Nearly all functionality of RoboBot is provided through the plugin interface. The
actual core of the bot attempts to concern itself with as little as possible
beyond parsing incoming messages, enforcing access controls to functions, and
delivering responses back to channels or private messages.

Individual functions should all be provided by a plugin. Each plugin is required
to extend the RoboBot::Plugin class, which provides default metadata and handles
common functionality such as usage/help information, as well as argument
evaluation, variable interpolation, and so on.

RoboBot uses Moose for its object system, and all plugins should follow the
conventions used by RoboBot as well as the Moose Best Practices.

### Plugin Metadata

The base RoboBot::Plugin class defines the following common metadata which every
plugin is expected to override as necessary. This should be done at the
beginning of your plugin by declaring:

```
has '+<attribute>' => ( ... );
```

#### name

The short name of the plugin. While this will almost always correspond to the
plugin's class name, it does not have to. Do not include 'RoboBot::Plugin::' in
the name. Because the plugin name is also used as the namespace for disambiguating
function calls when multiple plugins export functions with the same name, it is
also recommended to avoid characters not allowed in symbol names (e.g. whitespace,
non-printable or control characters, and parentheses).

#### description

A brief description, generally no more than a sentence or two, explaining the
purpose and general utility of the plugin. This is displayed in the `(help)`
output.

#### commands

The list of exported functions from this plugin. The attribute is required to
be a hash reference, with the keys being the function name as it will be exported
by RoboBot in chat sessions. Function names may contain almost any characters
other than whitespace, control characters (or otherwise non-printables), and
parentheses. Letters, numbers, and most punctuation or grammatical symbols are
acceptable.

While it is possible to export functions that are named solely with integers
(e.g. "123"), that is not advisable as it will produce unexpected side effects
should a value of the same series of numbers be returned from another function.

The structure of each value in the commands hash reference should also be a
hash reference with the following keys:

- *method*: The name of the instance method defined within the plugin which will
  be executed when the function is called. Required.

- *description*: A brief description of the purpose of the function. This is
  displayed in the (help) output for the function. Optional.

- *preprocess_args*: A boolean (0 or 1) indicating whether RoboBot should handle
  evaluation of the function's arguments, before passing them to the function.
  This will automatically process any lists and call any functions as necessary.
  If set to false, the plugin will be responsible for calling RoboBot's
  process_list() method on its own arguments. Optional; defaults to true.

- *usage*: A string which describes the expected arguments to the function. Used
  by (help) to display usage information for the function. Optional.

- *example*: A string which shows an example use of the function with sample
  arguments (instead of the datatype style placeholders expected in *usage*).
  Optional.

- *result*: A string showing sample output from the function, assuming the input
  of arguments shown in *example* above. Optional.

#### before_hook

Defines the name of the method, if any, to be called during the pre-evaluation
phase of message processing.

#### after_hook

Defines the name of the method, if any, to be called during the post-evaluation
(but pre-response) phase of message processing.

### Message and Response Hooks

In addition to exporting functions which may be called directly by users, plugins
may hook themselves into the message processing pipeline. Two distinct hooks are
provided: the `before_hook` which is executed after the Message object has been
constructed but before the expressions contained within are evaluated, and the
`after_hook` which is executed after any expressions are evaluated, but before
the Response object is delivered to its recipient(s).

Methods which are hooked into either of these locations receive as their sole
argument a RoboBot::Message object, with which they may do whatever they please.

Currently there is no mechanism for specifying the order in which plugins' hooked
methods will be called, so it must be assumed that it is a random order.

Additionally, the hooks are executed on every Message, whether it contained an
expression or not. This permits plugins to log or act on every incoming message
that may interest them (see the Markov or Logging plugins for examples of why
this is useful).

### Exporting Functions

Functions are exported for use in chat by overriding the RoboBot::Plugin attribute
`commands` as detailed in the section above. Name collisions are tolerated,
though the last plugin to be loaded (which must be assumed to be a randomized
order) will take precedence. All functions are also accessible by prefixing
the plugin's namespace to the function name.

The call `(list/last)` is the same as `(last)`, assuming that the List plugin is
the only one exporting a function called last. Of course, in the stock RoboBot,
this is not actually true. There's also a Logging plugin which provides a
`(last)` function. Because of this naming conflict, using the namespace prefix
is the only way to guarantee you will always invoke the right one:

```
(logging/last)
(list/last)
```

## Copyright and License

Copyright 2015, Jon Sime.

This program is free software; you can redistribute it and/or modify it under
the terms of the the Artistic License (2.0). You may obtain a copy of the full
license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License. By using, modifying or distributing the
Package, you accept this license. Do not use, modify, or distribute the Package,
if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by
someone other than you, you are nevertheless required to ensure that your
Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make, have made, use, offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder
that are necessarily infringed by the Package. If you institute patent
litigation (including a cross-claim or counterclaim) against any party alleging
that the Package constitutes direct or contributory patent infringement, then
this Artistic License to you shall terminate on the date that such litigation is
filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW.
UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY
OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

