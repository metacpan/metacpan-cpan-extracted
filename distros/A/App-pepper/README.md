# NAME

Pepper - A command-line EPP client.

# DESCRIPTION

Pepper is a command-line client for the EPP protocol. It's written in Perl and uses the [Net::EPP](https://metacpan.org/pod/Net%3A%3AEPP) module.

# USAGE

        pepper [OPTIONS]

Available command-line options:

- `--help` - show help and exit.
- `--host=HOST` - sets the host to connect to.
- `--port=PORT` - sets the port. Defaults to 700.
- `--timeout=TIMEOUT` - sets the timeout. Defaults to 3.
- `--user=USER` - sets the client ID.
- `--pass=PASS` - sets the client password.
- `--newpw=PASS` - specify a new password to replace the current password.
- `--login-security` - force the use of the Login Security extension (RFC 8807).
- `--cert=FILE` - specify the client certificate to use to connect.
- `--key=FILE` - specify the private key for the client certificate.
- `--exec=COMMAND` - specify a command to execute. If not provided, pepper goes into interactive mode.
- `--insecure` - disable SSL certificate checks.
- `--lang=LANG` - set the language when logging in.
- `--debug` - debug mode, makes `Net::EPP::Simple` verbose.

# USAGE MODES

Pepper supports two usage modes:

- 1 Interactive mode: this is the default mode. Pepper will provide a command prompt (with history and line editing capabilities) allowing you to input commands manually.
- 2 Script mode: if Pepper's `STDIN` is fed a stream of text (ie it's not attached to a terminal) then commands will be read from `STDIN` and executed sequentially. Pepper will exit once EOF is reached.

# SYNTAX

Once running in interactive mode, Pepper provides a simple command-line interface. The available commands are listed below.

## Getting Help

Use `help COMMAND` at any time to get information about that command. Where a command supports different object types (ie domain, host, contact), use `help command-type`, ie `help create-domain`.

## Connection Management

- `host HOST` - sets the host to connect to.
- `port PORT` - sets the port. Defaults to 700.
- `ssl on|off` - enable/disable SSL (default is on)
- `key FILE` - sets the private key
- `cert FILE` - sets the client certificate.
- `timeout TIMEOUT` - sets the timeout
- `connect` - connect to the server.
- `hello` - gets the greeting from server.
- `exit` - quit the program (logging out if necessary)

## Session Management

- `id USER` - sets the client ID.
- `pw PASS` - sets the client password.
- `login` - log in.
- `logout` - log out.
- `poll req` - requests the most recent poll message.
- `poll ack ID` - acknowledge the poll message with ID `ID`.

## Query Commands

### Availability Checks

        check TYPE OBJECT

This checks the availability of an object. `TYPE` is one of `domain`, `host`, `contact`, `claims` or `fee`. See ["Claims and fee Checks"](#claims-and-fee-checks) for more information about the latter two.

### Object Information

        info TYPE OBJECT [PARAMS]

Get object information. `TYPE` is one of `domain`, `host`, `contact`. For domain objects, `PARAMS` can be `AUTHINFO [HOSTS]`, where `AUTHINFO` is the domain's authInfo code, and the optional `HOSTS` is the value of the "hosts" attribute (ie `all`, which is the default, or `del`, `sub`, or `none`). If you want to set `HOSTS` but don't know the authInfo, use an empty quoted string (ie `""`) as `AUTHINFO`.

For contact objects, `PARAMS` can be the contact's authInfo.

## Transform Commands

- `create domain PARAMS` - create a domain object. See ["Creating Domain Objects"](#creating-domain-objects) for more information.
- `create host PARAMS` - create a host object. See ["Creating Host Objects"](#creating-host-objects) for more information.
- `clone TYPE OLD NEW` - clone a domain or contact object `OLD` into a new object identified by `NEW`. `TYPE` is one of `domain` or `contact`.
- `update TYPE OBJECT CHANGES` - update an object. `TYPE` is one of `domain`, `host`, or `contact`. See ["Object Updates"](#object-updates) for further information.
- `renew DOMAIN PERIOD [EXDATE]` - renew a domain (1 year by default). If you do not provide the `EXDATE` argument, pepper will perform an `<info>` command to get it from the server.
- `transfer PARAMS` - object transfer management See ["Object Transfers"](#object-transfers) for more information.
- `delete TYPE OBJECT` - delete an object. `TYPE` is one of `domain`, `host`, or `contact`.
- `restore DOMAIN` - submit an RGP restore request for a domain.

## Miscellaneous Commands

- `send FILE` - send the contents of `FILE` as an EPP command.
- `BEGIN` - begin inputting a frame to send to the server, end with "`END`".
- `edit` - Invoke `$EDITOR` and send the resulting file.

## Claims and fee Checks

Pepper provides limited support for the the Launch and Fee extensions:

### Claims Check

The following command will extend the standard &lt;check> command to perform
a claims check as per Section 3.1.1. of [draft-ietf-eppext-launchphase](https://metacpan.org/pod/draft-ietf-eppext-launchphase).

        pepper> check claims example.xyz

### Fee Check

The following command will extend the standard &lt;check> command to perform
a fee check as per Section 3.1.1. of [draft-brown-epp-fees-02](https://metacpan.org/pod/draft-brown-epp-fees-02).

        pepper> check fee example.xyz COMMAND [CURRENCY [PERIOD]]

`COMMAND` must be one of: `create`, `renew`, `transfer`, or `restore`.
`CURRENCY` is OPTIONAL but if provided, must be a three-character currency code.
`PERIOD` is also OPTIONAL but if provided, must be an integer between 1 and 99.

## Creating Objects

### Creating Domain Objects

There are two ways of creating a domain:

        clone domain OLD NEW

This command creates the domain `NEW` using the same contacts and nameservers as `OLD`.

        create domain DOMAIN PARAMS

This command creates a domain according to the parameters specified after the domain. `PARAMS` consists of pairs of name and (optionally quoted) value pairs as follows:

- `period` - the registration period. Defaults to 1 year.
- `registrant` - the registrant.
- `admin` - the admin contact.
- `tech` - the tech contact.
- `billing` - the billing contact.
- `ns` - add a nameserver.
- `authinfo` - authInfo code. A random string will be used if not provided.

Example:

    pepper (id@host)> create domain example.xyz period 1 registrant sh8013 admin sh8013 tech sh8013 billing sh8013 ns ns0.example.com ns ns1.example.net

### Creating Host Objects

Syntax:

        create host HOSTNAME [IP [IP [IP [...]]]]

Create a host object with the specified `HOSTNAME`. IP address may also be
specified: IPv4 and IPv6 addresses are automatically detected.

### Creating Contact Objects

There are two ways of creating a contact:

        clone contact OLD NEW

This command creates the contact `NEW` using the same data as `OLD`.

        create contact PARAMS

This command creates a contact object according to the parameters specified. `PARAMS` consists of pairs of name and (optionally quoted) value pairs as follows:

- `id` - contact ID. If not provided, a random 16-charater ID will be generated
- `type` - specify the "type" attribute for the postal address information. Only one type is supported. Possible values are "int" (default) and "loc".
- `name` - contact name
- `org` - contact organisation
- `street` - street address, may be provided multiple times
- `city` - city
- `sp` - state/province
- `pc` - postcode
- `cc` - ISO-3166-alpha2 country code
- `voice` - E164 voice number
- `fax` - E164 fax number
- `email` - email address
- `authinfo` - authInfo code. A random string will be used if not provided.

Example:

    pepper (id@host)> create contact id "sh8013" name "John Doe" org "Example Inc." type int street "123 Example Dr." city Dulles sp VA pc 20166-6503 cc US voice +1.7035555555 email jdoe@example.com
    

## Object Updates

Objects may be updated using the `update` command.

### Domain Updates

        update domain DOMAIN CHANGES

The `CHANGES` argument consists of groups of three values: an action (ie `add`, `rem` or `chg`), followed by a property name (e.g. `ns`, a contact type (such as `admin`, `tech` or `billing`) or `status`), followed by a value.

Example:

        update domain example.com add ns ns0.example.com

        update domain example.com rem ns ns0.example.com

        update domain example.com add status clientUpdateProhibited

        update domain example.com rem status clientHold

        update domain example.com add admin H12345

        update domain example.com rem tech H54321

        update domain example.com chg registrant H54321

        update domain example.cm chg authinfo foo2bar

Multiple changes can be combined in a single command:

        update domain example.com add status clientUpdateProhibited rem ns ns0.example.com chg registrant H54321

### Host Updates

Syntax:

        update host HOSTNAME CHANGES

The `CHANGES` argument consists of groups of three values: an action (ie `add`, `rem` or `chg`), followed by a property name (ie `addr`, `status` or `name`), followed by a value (which may be quoted).

Examples:

        update host ns0.example.com add status clientUpdateProhibited

        update host ns0.example.com rem addr 10.0.0.1

        update host ns0.example.com chg name ns0.example.net

Multiple changes can be combined in a single command:

        update host ns0.example.com add status clientUpdateProhibited rem addr 10.0.0.1 add addr 1::1 chg name ns0.example.net

### Contact Updates

Not currently implemented.

## Object Transfers

Object transfers may be managed with the `transfer` command. Usage:

        transfer TYPE OBJECT CMD [AUTHINFO [PERIOD]]

where:

- `TYPE` - `domain` or `contact`
- `OBJECT` - domain name or contact ID
- `CMD` - one of (`request`, `query`, `approve`, `reject`, or `cancel`)
- `AUTHINFO` - authInfo code (used with `request` only)
- `PERIOD` - additional validity period (used with domain `request` only)

## Errors

If you prefix a command with a `!` character, then Pepper will end the session if an EPP command fails (that is, if the result code of the response is 2000 or higher).

This is mostly useful in scripting mode where you may want the script to terminate if an error occurs.

Example usage:

    !create domain example.com authinfo foo2bar
    update domain example.com add ns ns0.example.com

In the above example, Pepper will end the session if the first command fails, since there is no point in running the second command if the first has failed.

# INSTALLATION

To install, run:

        cpanm --sudo App::pepper

If [Term::ReadLine::Gnu](https://metacpan.org/pod/Term%3A%3AReadLine%3A%3AGnu) is available, then Pepper can provide a richer interactive command line, with support for history and rich command editing.

# RUNNING VIA DOCKER

The [git repository](https://github.com/gbxyz/pepper) contains a `Dockerfile`
that can be used to build an image on your local system.

Alternatively, you can pull the [image from Docker Hub](https://hub.docker.com/r/gbxyz/pepper):

        $ docker pull gbxyz/pepper

        $ docker run -it gbxyz/pepper --help

# LICENSE

Copyright 2014 - 2023 CentralNic Group plc.

This program is Free Software; you can use it and/or modify it under the same terms as Perl itself.
