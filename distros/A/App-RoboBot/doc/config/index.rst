.. include:: ../common.defs

.. _ch-config:

Configuration
*************

Configuration of |RB| is done through a single file at this time, and the path
to that file must be provided to the ``robobot`` command when running an
instance of the bot.

The configuration file consists of several sections and has a format similar to
Apache HTTPD configuration files. Each of the sections is described below. A
sample configuration file is shipped with the |A-RB| distribution and may be
found in the distribution's ``share/`` directory, the location of which is
dependent on your |CPANM| setup.

Globals
=======

|RB| includes a global configuration section for settings which affect its
general operation. Currently, the only necessary setting is a default nick to
be used by the bot for any networks definitions which do not supply their own.
If no global nick is defined in your configuration, it will default to
``robobot``.

Example
-------

.. code-block:: aconf

    <global>
        nick    mybot
    </global>

.. _config-database:

Database
========

Every instance of |RB| must have a valid connection to a properly configured
|PG| database. Failure to open a connection at startup will trigger a fatal
error and |RB| will refuse to run. Only one database section is permitted. At
this time, only |PG| is supported.

Before running |RB| for the first time, you will need to install and configure
|PG| and modify its ``pg_hba.conf`` to allow access from the host on which you
will be running |RB|. A user role and empty database owned by that user must be
created, but |RB| will handle everything else (creating and populating the
database schema, as well as always keeping the schema up to date with |RB|
upgrades).

Your configuration file should contain a ``<database>`` section with the
appropriate connection and authentication details. You may opt to include your
database password in your |RB| configuration file, or to place it separately in
a ``~/.pgpass`` file for the user under which your |RB| process will run (in
which case you should omit the ``pass`` setting shown below). The choice is
yours, though you should always ensure that other users on the system are not
able to read any file in which the password is stored.

Example
-------

.. code-block:: aconf

    <database>
        <primary>
            driver      Pg
            host        localhost
            port        5432
            database    robobot
            user        yourdbuser
            pass        abc123nobodycancrackme
            schemas     robobot
            schemas     public
        </primary>
    </database>

Please note that, at this time, the two ``schemas`` lines are required and
should not be set to anything else. Future releases of |RB| may hide this
requirement behind the scenes to reduce the possibility of misconfiguration.

Networks
========

Each network to which you want your instance of |RB| to connect will need its
own ``<network NAME>`` configuration section. The contents of these sections
will depend largely on the protocol being used. Each supported protocol is
explained below under :ref:`config-network-protocols`.

In addition to configuring the details of each network's protocol, you may also
disable individual plugins on a per-network basis. This is useful for, among
other things, reducing redundant features. For example, both Slack and
Mattermost automatically fetch website snippets when users mention URLs, so
there's no need to have |RB| doing the same and doubling up the page titles
and such. Configuring these plugin blacklists is shown in
:ref:`config-network-plugin-disable`.

Common Settings
---------------

Every network configuration includes three common elements:

Network Name
    You must provide a unique name to each network you configure. These names
    may contain letters, numbers, and dashes. They are not case-sensitive. The
    network name is part of the section opening tag.

Network Type
    It is required to specify the type of network being configured, using the
    ``type`` setting. Valid values are: ``irc``, ``slack``, and ``mattermost``.

Enabled
    You may include network configuration sections for networks to which you
    don't currently want |RB| to connect. By setting the value of ``enabled``
    to ``0``, |RB| will load and validate the network's configuration, but will
    not actually connect to the service.

The base minimum settings would result in a configuration section like this:

.. code-block:: aconf

    <network my-network-name>
        type    irc
        enabled 0
    </network>

.. _config-network-protocols:

Protocol Configurations
-----------------------

IRC
~~~

IRC networks will connect to any local or remote IRC service over TCP, and
support SSL encryption at your discretion. At a bare minimum, you must supply
a ``host``, a ``port`` and at least one ``channel``. Technically, channels are
optional, but without them nobody will be able to communicate with the bot
instance except by ``/msg`` commands, and some plugins require a real channel
context. Channel names should omit the ``#`` character.

In addition, if you wish to use an encrypted connection you may set ``ssl`` to
a true value.

An example IRC network configuration with SSL and two channels would look like:

.. code-block:: aconf

    <network my-irc-network>
        type    irc
        enabled 1

        host    irc.mydomain.tld
        port    6689
        ssl     1

        channel awesomechat
        channel boringchat
    </network>

Slack
~~~~~

|Slack| network configuration is a bit simpler than IRC, as you need only
specify the username and |Slack| integration token used for your |Slack| team.
Channels will be joined automatically, and users in your team may invite your
bot to channels at will.

To obtain an appropriate token for your |Slack| team, go to *Apps &
integrations* then *Manage* followed by *Custom Integrations*. In the *Bots*
section, click on *Add Configuration* and choose a username for your |RB|
instance. Your new bot configuration will have an API Token generated for it.
While you're at that screen, you may change things like the icon, description,
and display name.

The resulting network configuration block, now that you have your token, will
look like:

.. code-block:: aconf

    <network my-slack-team>
        type    slack
        enabled 1

        username    mybotuser
        token       abcd-0123456789-sd8f79sd8fsd9dsfsdf
    </network>

Mattermost
~~~~~~~~~~

|Mattermost| network configuration is similar to |Slack| in that you don't
specify channels. Your |RB| instance will automatically join the default
channel, and users may invite the bot to any channels beyond that.

The authentication details differe from |Slack|, however, largely because the
|Mattermost| service is self-hosted and as such you will need to tell |RB|
where it is running.

At this time, |RB| connects to |Mattermost| as a regular user account. So, to
obtain the authentication details, you will need to create a new user account
like any other. This means you will need to use an email address. You will also
need to know the |Mattermost| team's shortname (the version of the team name
which appears in URLs, which may not be the same as the potentially longer
display name).

Once you have created the account, your network configuration section will look
like:

.. code-block:: aconf

    <network my-mattermost>
        type    mattermost
        enabled 1

        server      https://mattermost.mydomain.tld/
        team        myteam
        email       robobot@mydomain.tld
        password    supersekreet
    </network>

The ``server`` setting is simply the base URL you use when logging into the web
interface of your |Mattermost| instance.

.. _config-network-plugin-disable:

Disabling Plugins Per-Network
-----------------------------

Each network may optionally disable individual plugins, and the set of disabled
plugins may differ for each network without impacting the others. To do this,
include a ``disabled_plugins`` section within the network, listing each plugin
you wish to disable and give it a true value. The name of the plugin used here
comes from its ``name`` attribute, which matches its namespace except using
double colons instead of a period. (Future version of |RB| may simplify this.
Sorry.)

For example, to disable the intentionally-obnoxious spell checker, and prevent
|RB| from automatically displaying the titles of web pages linked, you would do
the following:

.. code-block:: aconf

    <network my-network>
        type    irc
        enabled 1

        host irc.mydomain.tld
        port 6667

        <disabled_plugins>
            fun::spellcheck     true
            net::urls           true
        </disabled_plugins>
    </network>

Plugins
=======

Some plugins require additional configuration before they will operate. These
generally include the various API plugins which contact external services,
particularly those that require authorization tokens (e.g. the Azure Markeplace
Translate API plugin, :ref:`module-api-translate`).

Each of the plugins requiring these configurations will have its own ``<plugin NAME>``
section in your configuration file. The contents of these sections varies by
the plugin and you should consult their specific documentation for further
details.
