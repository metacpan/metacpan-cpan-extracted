.. include:: /common.defs

.. _lang-scopes:

Scopes
******

|RB| presents multiple :index:`scopes <scope>` in which statements, and their
components, are evaluated.

.. _lang-scope-global:

Global Scope
============

The :index:`global scope` encompasses the entirety of any bot instance which
connects to the same |PG| database and uses the same |RB| configuration. All
functions provided by plugins exist within this scope (though your network
configurations may disable the use of individual plugins).

Users, through their interaction with a bot instance, are not able to define
anything which exists in the global scope.

.. _lang-scope-network:

Network Scope
=============

The :index:`network scope` covers all objects and data which are accessible to
any user interacting with a bot instance, as long as they are connected to the
same network. Most plugins which maintain persistent data, such as :ref:`module-fun-thinge`
for storing and retrieving arbitrarily categorized snippets of information, use
the network scope.

Thus, if you have a single |RB| instance which connects to both an IRC network
and a |Slack| network, user Jane may use :ref:`function-fun-thinge-thinge-add`
to save a cat picture in IRC, but user Bob who talks to the same |RB| instance
over |Slack| will not be able to access that picture.

.. _lang-scope-channel:

Channel Scope
=============

The :index:`channel scope` restricts access to data or operations to an
individual channel on a specific network. The use of this scope is fairly
uncommon, with the most significant examples being the :ref:`module-bot-alarm`
and :ref:`module-bot-autoreply` plugins.

.. _lang-scope-statement:

Statement Scope
===============

.. _lang-scope-lexical:

Lexical Scope
=============

|RB| provides a :ref:`function-core-let` form which permits users to
temporarily define and bind a value to a reusable name, but only for the
expressions provided to the body of the ``(let)``. Names created in this manner
are said to exist in a :index:`lexical scope` because they exist only until the
end of the enclosing form and then are destroyed, becoming unavailable for use
outside that scope.
