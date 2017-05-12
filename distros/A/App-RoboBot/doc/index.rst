.. include:: /common.defs

RoboBot
=======

Welcome to |RB|, the extensible multi-protocol bot that communicates with a
pronounced lisp.

.. figure:: /_static/robobot-whoknows-sample.png
   :align: center
   :alt: sample screenshot of robobot interaction

   *Using RoboBot to find coworkers who might be able to answer a question.*

In the following pages you will find the software's operation, design, and
rough edges discussed in (hopefully thorough) detail. This guide is broken down
into the following top-level sections:

:ref:`ch-intro`
    Overview of the bot, its most notable features, basic interactions, and how
    to help contribute to the project (or receive help).

:ref:`ch-install`
    Instructions on installing |A-RB| and all of its dependencies.

:ref:`ch-upgrade`
    Instructions and advice for upgrading between releases of |RB|..

:ref:`ch-config`
    Detailed setup and configuration instructions for those wishing to operate
    an instance of the bot.

:ref:`ch-lang`
    Coverage of all |RB|'s syntax and other core language features.

:ref:`ch-modules`
    Listing and documentation for all bundled modules, which form the meat of
    the bot's functionality out of the box (before users start macroing their
    own features).

:ref:`ch-cookbook`
    Provides a collection of examples of using built-in |RB| features via
    custom macros to dynamically extend the functionality of your bot instance.

:ref:`genindex`
    Documentation index, including references to complete listing of all plugin
    functions and other notable topics.

If you run into any problems, or wish to contribute to the software, please
don't hesitate to check out the project at |GH|.


.. toctree::
   :hidden:

   intro/index
   install/index
   upgrade/index
   config/index
   lang/index
   modules/index
   cookbook/index

