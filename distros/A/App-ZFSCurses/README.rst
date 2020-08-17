App::ZFSCurses
==============

a curses UI to display and/or change a ZFS dataset/snapshot properties.

Quickstart
----------

App::ZFSCurses is available on `CPAN <https://metacpan.org/>`_ and can be
installed using `cpanm <https://metacpan.org/pod/App::cpanminus>`_.

.. code-block:: console

    $ cpanm App::ZFSCurses

``zfscurses`` can be run in two different "views":

.. code-block:: console

    $ zfscurses datasets

to display the list of ZFS datasets found on the system.

.. code-block:: console

    $ zfscurses snapshots

to display the list of ZFS snapshots found on the system.

Make sure to run ``zfscurses --help`` to display the help. A manual page can be
shown using ``zfscurses --man``.

Needless to say you must use the ZFS filesystem for ``zfscurses`` to work. In case
you don't, a warning will show up and the application will automatically exit.

Backend
-------

App::ZFScurses leverages the ``zfs`` command to do the heavy lifting and
to present information in a comprehensive way to the user.

Navigation
----------

App::ZFSCurses is built with `Curses::UI
<https://metacpan.org/pod/Curses::UI>`_. To navigate around the UI, use the
following keystrokes:

- **Up/Down** → move the cursor up or down.
- **Enter/Space** → validate selection.
- **Tab** → change focus around.
- **Ctrl+q** → quit the UI.
- **F1** → when browsing a dataset/snapshot properties, F1 will show a help
  message about the selected property. You must first select a property using
  Enter/Space.

Listboxes showing the different datasets/snapshots/properties are searchable:

- **/** → search forward in the list.
- **?** → search backward in the list.

Mouse
-----

Mouse support is enabled. You can click on any UI component (textbox, list) as
well as buttons.

Screenshots
-----------

What does it look like in practice? See the `project's wiki
<https://gitlab.com/monsieurp/App-ZFSCurses/-/wikis>`_.

License
-------

3-clause BSD.
