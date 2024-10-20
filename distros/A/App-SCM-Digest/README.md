## App-SCM-Digest

Provides for generating source control management (SCM) repository
commit digest emails for a given period of time.  It does this based
on the time when the commit was pulled into the local repository,
rather than when the commit was committed.  This means that, with
scheduled digests, commits aren't omitted from the digest due to their
having originally occurred at some other time (e.g. due to delayed
push or subsequent rebasing).

### Installation

Run the following commands from within the checkout directory:

```
perl Makefile.PL
make
make test
make install
```

Alternatively, run `cpanm .` from within the checkout directory.  This
will fetch and install module dependencies, if required.  See
https://cpanmin.us.

### Usage

```
scm-digest [ options ]
```

Options:

 * `--conf {config}`
    * Set configuration path (defaults to /etc/scm-digest.conf).
 * `--update`
    * Initialise and update local repositories.
 * `--get-email`
    * Print digest email to standard output.
 * `--from {time}`
    * Only include commits made after this time in digest.
 * `--to {time}`
    * Only include commits made before this time in digest.

Time format is `%Y-%m-%dT%H:%M:%S`, e.g. `2000-12-25T22:00:00`.

If `get-email` is used without `from` and `to` arguments, then `from`
will default to one day ago, and `to` will default to the current
time.  If only `from` is provided, then there will be no upper bound
on the commit date.  If only `to` is provided, then there will be no
lower bound on the commit date.

The configuration file must be in YAML format.  Options that may be
specified are as follows:

```
  db_path:          /path/to/db
  repository_path:  /path/to/local/repositories
  timezone:         UTC
  ignore_errors:    0
  headers:
    From: From Address <from@example.org>
    To:   To Address <to@example.org>
    ...
  repositories:
    - name: test
      url: http://example.org/path/to/repository
      type: [git|hg]
    - name: local-test
      url: file:///path/to/repository
      type: [git|hg]
      ...
```

`db_path`, `repository_path`, and `repositories` are the mandatory
configuration entries.  Paths must be absolute.

`timezone` is optional, and defaults to 'UTC'.  See
`DateTime::TimeZone::Catalog` for a list of valid timezones.

`ignore_errors` is an optional boolean, and defaults to false.  If
false, errors will cause the process to abort immediately.  If true,
errors will instead be printed to `stderr`, and the process will
continue onto the next repository.

Depending on what has happened to the remote repository, the updating
of the local repository may involve a merge.  That merge will prefer
the content from the remote repository, in the event of a conflict.

If an operation against a given repository fails, then this will
re-clone the repository and retry the operation.  If the operation
still fails, the original repository will be restored and the
operation will be skipped.

### Example

```
user@host:~$ cd /tmp
user@host:tmp$ mkdir db
user@host:tmp$ mkdir repos
user@host:tmp$ cat << EOF >> config.yml
> db_path: /tmp/db
> repository_path: /tmp/repos
> repositories:
>   - name: scm-digest
>     url: https://github.com/tomhrr/p5-App-SCM-Digest
>     type: git
> EOF
user@host:tmp$ scm-digest --conf /tmp/config.yml --update
user@host:tmp$ scm-digest --conf /tmp/config.yml --get-email | sendmail user@host
```

### Copyright and licence

Copyright (C) 2015-2024 Tom Harrison

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
