===============================================================================
AnyEvent::Blackboard
===============================================================================

AnyEvent::Blackboard is a data-driven workflow manager for asynchronous
applications.  It's designed to be used to control the ordering of asynchronous
actions which have data-dependencies, by allowing components to subscribe to
the publication of a named values on a per-request basis.

AnyEvent is used soley for the management of value timeouts, where asynchronous
actions are intended to fulfill parts of the request under tight time
constraints, where further action may take place in the absence of a value
being provided.

Development
-------------------------------------------------------------------------------
AnyEvent::Blackboard uses Module::Build for its build scripts.  It includes a
file in ``lib/`` called ``all.PL`` which imports the module, so that the
command ``./Build build`` will at minimum compile the module with ``perl``.

=========================== ===================================================
Filename                    Description 
=========================== ===================================================
lib/all.PL                  A build script which includes all modules.
lib/AnyEvent/Blackboard.pm  The AnyEvent::Blackboard module.
t/                          Tests.
=========================== ===================================================

Please add a unit test or subtest for any additional functionality.

License
-------------------------------------------------------------------------------
Copyright © 2012, Say Media.

Distributed under the Artistic License v2.0, see LICENSE.
