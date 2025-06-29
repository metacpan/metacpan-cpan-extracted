
# NAME

sshca - A minimal SSH Certificate Authority

## SYNOPSIS

```bash
  $ sshca init
  Successfully created SH CA directory ~/sshca
  $ sshca issue certName ~/.ssh/id_ed25519.pub
  User certificate with identity 'certName' and serial number 1:
  ... certificate data ...
  $ sshca renew 1
  ... certificate data ...
```

## DESCRIPTION

This is a simple SSH Certificate Authority. SSH certificates greatly
enhance the functionality of SSH public keys. The `sshca` script hands
out certificates for public keys and tracks these certs. It can be
used to create both user and host certificates.

Read more about SSH certificates in the following articles:

* [Tightening SSH access using short-lived SSH certificates](https://www.bastionxp.com/blog/tightening-ssh-access-using-short-lived-ssh-certificates/)
* [How to configure and setup SSH certificates for SSH authentication](https://dev.to/gvelrajan/how-to-configure-and-setup-ssh-certificates-for-ssh-authentication-b52)
* [Server access with SSH certificates - deep dive](https://dev.to/ehuelsmann/server-access-with-ssh-certificates-deep-dive-4h05)

## COMMANDS

### init

```plain
  sshca [global-options] init [options] <ca-directory>
```

Creates a certificate authority administrative directory `<ca-directory>`.

Available options:

* `--serial=<number>`\
  Used to override the initial serial number (defaults to 1)

### issue

```plain
  sshca [global-options] issue [options] <identity> <pubkey filename>
```

Issues a new user certificate for the public key read from `<pubkey filename>`.
If the filename is equal to `-` (hyphen), the public key data is read from
standard input.

Available options:

* `--host`\
  When provided, issues a host certificate instead of a user certificate
* `--option=<option>`\
  Add the given option to the certificate; this option may be passed multiple times
* `--principal=<principal>`\
  Adds the given principal to the certificate; this option may be passed multiple times.
  Principles on "host" certificates must be host names or IP addresses; principles on
  "user" certificates the values are documented to be user names, but can also be used
  as the more general concept of tags.

### renew

```plain
  sshca [global-options] renew <identifier>
```

Issues a new certificate using the input data that was provided to generate the
certificate with serial number `<identifier>`, except for the validity period.

Available options:

* `--serial`|`--fingerprint`|`--identity`\
  Used to change the interpretation of the `<identifier>` argument.
  * `--serial` indicates the identifier argument is to be interpreted as a certificate
    serial number.
  * (planned) `--fingerprint` indicates the identifier argument is to be interpreted as a public
    key finger print; in case multiple certificates have been issued for this public
    key the last issued certificate is renewed.
  * (planned) `--identity` indicates the identifier argument is to be interpreted as a certificate
    identity; in case multiple certificates have been issued for this identity the last
    issued certificate is renewed.
* `--validity`\
  Indicates the validity period of the new certificate.

### revoke

Planned.

### history

Planned.

## GLOBAL OPTIONS

These options can be specified before commands and are accepted with all commands:

* `--debug`
* `--config` (ignored on `init` command)
* `--basedir` (ignored on `init` command)

## ENVIRONMENT VARIABLES

Environment variables override hard-coded defaults as well as configuration values.
Command line options take precedence over environment variables.

### SSHCA_CONF

Used to specify the location of the configuration file, disabling the built-in
list of locations to be tried.

### SSHCA_HOME

Used to override the location of the administrative files.

## CONFIGURATION

The configuration file (`sshca.conf`) is a YAML file with the following keys:

* `basedir`
* `ca_keytype`\
  Default: `ed25519`
* `hostcert_validity`\
  Default: `+53w`
* `usercert_validity`\
  Default: `+13w1d`

## FUTURE DEVELOPMENT

The current version stores the certificate data in the filesystem. Next iterations
should be more flexible and contain configurable storage backends, e.g. using DBI
which would allow storing the data in SQLite or PostgreSQL.



## SEE ALSO

* [sshca (shell script)](https://github.com/mattferris/sshca)

## LICENSE AND COPYRIGHT

Copyright 2025 Erik Huelsmann <ehuels@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
