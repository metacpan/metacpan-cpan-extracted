# NAME

App::wsgetmail - Fetch mail from the cloud using webservices

# SYNOPSIS

Run:

    wsgetmail [options] --config=wsgetmail.json

where `wsgetmail.json` looks like:

    {
    "client_id": "abcd1234-xxxx-xxxx-xxxx-1234abcdef99",
    "tenant_id": "abcd1234-xxxx-xxxx-xxxx-123abcde1234",
    "secret": "abcde1fghij2klmno3pqrst4uvwxy5~0",
    "global_access": 1,
    "username": "rt-comment@example.com",
    "folder": "Inbox",
    "command": "/opt/rt5/bin/rt-mailgate",
    "command_args": "--url=http://rt.example.com/ --queue=General --action=comment",
    "command_timeout": 30,
    "action_on_fetched": "mark_as_read"
    }

Using App::wsgetmail as a library looks like:

    my $getmail = App::wsgetmail->new({config => {
      # The config hashref takes all the same keys and values as the
      # command line tool configuration JSON.
    }});
    while (my $message = $getmail->get_next_message()) {
        $getmail->process_message($message)
          or warn "could not process $message->id";
    }

# DESCRIPTION

wsgetmail retrieves mail from a folder available through a web services API
and delivers it to another system. Currently, it only knows how to retrieve
mail from the Microsoft Graph API, and deliver it by running another command
on the local system.

# INSTALLATION

    perl Makefile.PL
    make
    make test
    sudo make install

`wsgetmail` will be installed under `/usr/local/bin` if you're using the
system Perl, or in the same directory as `perl` if you built your own.

# ATTRIBUTES

## config

A hash ref that is passed to construct the `mda` and `client` (see below).

## mda

An instance of [App::wsgetmail::MDA](https://metacpan.org/pod/App::wsgetmail::MDA) created from our `config` object.

## client\_class

The name of the App::wsgetmail package used to construct the
`client`. Default `MS365`.

## client

An instance of the `client_class` created from our `config` object.

# METHODS

## process\_message($message)

Given a Message object, retrieves the full message content, delivers it
using the `mda`, and then executes the configured post-fetch
action. Returns a boolean indicating success.

## post\_fetch\_action($message)

Given a Message object, executes the configured post-fetch action. Returns a
boolean indicating success.

# CONFIGURATION

## Configuring Microsoft 365 Client Access

To use wsgetmail, first you need to set up the app in Microsoft 365.
Two authentication methods are supported:

- Client Credentials

    This method uses shared secrets and is preferred by Microsoft.
    (See [Client credentials](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#client-credentials))

- Username/password

    This method is more like previous connections via IMAP. It is currently
    supported by Microsoft, but not recommended. (See [Username/password](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-authentication-flows#usernamepassword))

This section walks you through each piece of configuration wsgetmail needs,
and how to obtain it.

- tenant\_id

    wsgetmail authenticates to an Azure Active Directory (AD) tenant. This
    tenant is identified by an identifier that looks like a UUID/GUID: it should
    be mostly alphanumeric, with dividing dashes in the same places as shown in
    the example configuration above. Microsoft documents how to find your tenant
    ID, and create a tenant if needed, in the ["Set up a tenant"
    quickstart](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant). Save
    this as the `tenant_id` string in your wsgetmail configuration file.

- client\_id

    You need to register wsgetmail as an application in your Azure Active
    Directory tenant. Microsoft documents how to do this in the ["Register an
    application with the Microsoft identity platform"
    quickstart](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#register-an-application),
    under the section "Register an application." When asked who can use this
    application, you can leave that at the default "Accounts in this
    organizational directory only (Single tenant)."

    After you successfully register the wsgetmail application, its information
    page in your Azure account will display an "Application (client) ID" in the
    same UUID/GUID format as your tenant ID. Save this as the `client_id`
    string in your configuration file.

    After that is done, you need to grant wsgetmail permission to access the
    Microsoft Graph mail APIs. Microsoft documents how to do this in the
    ["Configure a client application to access a web API"
    quickstart](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-access-web-apis#application-permission-to-microsoft-graph),
    under the section "Add permissions to access Microsoft Graph." When selecting
    the type of permissions, select "Application permissions." When prompted to
    select permissions, select all of the following:

    - Mail.Read
    - Mail.Read.Shared
    - Mail.ReadWrite
    - Mail.ReadWrite.Shared
    - openid
    - User.Read

### Configuring client secret authentication

We recommend you deploy wsgetmail by configuring it with a client
secret. Client secrets can be granted limited access to only the mailboxes
you choose. You can adjust or revoke wsgetmail's access without interfering
with other applications.

Microsoft documents how to create a client secret in the ["Register an
application with the Microsoft identity platform"
quickstart](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#add-a-client-secret),
under the section "Add a client secret." Take care to record the secret
token when it appears; it will never be displayed again. It should look like
a completely random string, not a UUID/GUID.

- global\_access

    Set this to `1` in your wsgetmail configuration file.

- secret

    Set this to the secret token string you recorded earlier in your wsgetmail
    configuration file.

- username

    wsgetmail will fetch mail from this user's account. Set this to an email
    address string in your wsgetmail configuration file.

### Configuring user+password authentication

If you do not want to use a client secret, you can also configure wsgetmail
to authenticate with a traditional username+password combination. As noted
above, this method is not recommended by Microsoft. It also does not work
for systems with federated authentication enabled.

- global\_access

    Set this to `0` in your wsgetmail configuration file.

- username

    wsgetmail will authenticate as this user. Set this to an email address
    string in your wsgetmail configuration file.

- user\_password

    Set this to the password string for `username` in your wsgetmail
    configuration file.

## Configuring the mail delivery command

Now that you've configured wsgetmail to access a mail account, all that's
left is configuring delivery. Set the following in your wsgetmail
configuration file.

- folder

    Set this to the name string of a mail folder to read.

- command

    Set this to an executable command. You can specify an absolute path,
    or a plain command name which will be found from `$PATH`. For each
    email wsgetmail retrieves, it will run this command and pass the
    message data to it via standard input.

- command\_args

    Set this to a string with additional arguments to pass to `command`.
    These arguments follow shell quoting rules: you can escape characters
    with a backslash, and denote a single string argument with single or
    double quotes.

- command\_timeout

    Set this to the number of seconds the `command` has to return before
    timeout is reached.  The default value is 30.

- action\_on\_fetched

    Set this to a literal string `"mark_as_read"` or `"delete"`.
    For each email wsgetmail retrieves, after the configured delivery
    command succeeds, it will take this action on the message.

    If you set this to `"mark_as_read"`, wsgetmail will only retrieve and
    deliver messages that are marked unread in the configured folder, so it does
    not try to deliver the same email multiple times.

# TESTING AND DEPLOYMENT

After you write your wsgetmail configuration file, you can test it by running:

    wsgetmail --debug --dry-run --config=wsgetmail.json

This will read and deliver messages, but will not mark them as read or
delete them. If there are any problems, those will be reported in the error
output. You can update your configuration file and try again until wsgetmail
runs successfully.

Once your configuration is stable, you can configure wsgetmail to run
periodically through cron or a systemd service on a timer.

# LIMITATIONS

## Fetching from Multiple Folders

wsgetmail can only read from a single folder each time it runs. If you need
to read multiple folders (possibly spanning different accounts), then you
need to run it multiple times with different configuration.

If you only need to change a couple small configuration settings like the
folder name, you can use the `--options` argument to override those from a
base configuration file. For example:

    wsgetmail --config=wsgetmail.json --options='{"folder": "Inbox"}'
    wsgetmail --config=wsgetmail.json --options='{"folder": "Other Folder"}'

NOTE: Setting `secret` or `user_password` with `--options` is not secure
and may expose your credentials to other users on the local system. If you
need to set these options, or just change a lot of settings in your
configuration, just run wsgetmail with different configurations:

    wsgetmail --config=account01.json
    wsgetmail --config=account02.json

## Office 365 API Limits

Microsoft applies some limits to the amount of API requests allowed as
documented in their [Microsoft Graph throttling guidance](https://docs.microsoft.com/en-us/graph/throttling).
If you reach a limit, requests to the API will start failing for a period
of time.

# SEE ALSO

- [wsgetmail](https://metacpan.org/pod/wsgetmail)
- [App::wsgetmail::MDA](https://metacpan.org/pod/App::wsgetmail::MDA)
- [App::wsgetmail::MS365](https://metacpan.org/pod/App::wsgetmail::MS365)
- [App::wsgetmail::MS365::Message](https://metacpan.org/pod/App::wsgetmail::MS365::Message)

# AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2015-2020 by Best Practical Solutions, LLC.

This is free software, licensed under:

The GNU General Public License, Version 2, June 1991
