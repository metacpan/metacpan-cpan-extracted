App::ZFSCurses
==============

a curses UI to display and/or change ZFS datasets properties.

Quickstart
----------

App::ZFSCurses is available on `CPAN <https://metacpan.org/>`_ and can be
installed using `cpanm <https://metacpan.org/pod/App::cpanminus>`_.

.. code-block:: console

    $ cpanm App::ZFSCurses

Once installed, start App::ZFSCurses with the following command:

.. code-block:: console

    $ zfscurses

Needless to say you must use the ZFS filesystem for zfscurses to work. In case
you don't, a warning will show up and the application will automatically exit.

Backend
-------

App::ZFScurses leverages the `zfs` command to do the heavy lifting and
to present information in a comprehensive way to the user. Precisely, two
subcommands are heavily used:

- `zfs list -t filesystem`
- `zfs get all dataset`

Navigation
----------

App::ZFSCurses is built with `Curses::UI
<https://metacpan.org/pod/Curses::UI>`_. To navigate around the UI, use the
following keystrokes:

- **Up/Down** → move the cursor up or down.
- **Enter/Space** → validate selection.
- **Tab** → change focus around.
- **Ctrl+q** → quit the UI.
- **F1** → when browsing a dataset properties, F1 will show a help message about the
  selected property. You must first select a property using Enter/Space.

Screenshots
-----------

What does it look like in practice? See the `project's wiki
<https://gitlab.com/monsieurp/App-ZFSCurses/-/wikis>`_.

License
-------

3-clause BSD.
