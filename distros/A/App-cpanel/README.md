# NAME

App::cpanel - CLI for cPanel UAPI and API 2

# PROJECT STATUS

[![CPAN version](https://badge.fury.io/pl/App-cpanel.svg)](https://metacpan.org/pod/App::cpanel)

# SYNOPSIS

    $ cpanel uapi Notifications get_notifications_count
    $ cpanel uapi ResourceUsage get_usages
    $ cpanel uapi Fileman list_files dir=public_html
    $ cpanel uapi Fileman get_file_content dir=public_html file=index.html
    $ cpanel download public_html/index.html
    $ cpanel api2 Fileman fileop op=chmod metadata=0755 sourcefiles=public_html/cgi-bin/hello-world
    $ cpanel api2 Fileman fileop op=unlink sourcefiles=public_html/cgi-bin/hello-world
    $ cpanel api2 Fileman mkdir path= name=new-dir-at-top

    # this one is one at a time but can overwrite files
    $ cpanel api2 Fileman savefile dir=public_html/cgi-bin filename=hello-world content="$(cat public_html/cgi-bin/hello-world)"
    # this is multiple files but refuses to overwrite
    $ cpanel upload public_html/cgi-bin hello-world

    # download
    $ cpanel mirror public_html public_html cpanel localfs
    # upload
    $ cpanel mirror public_html public_html localfs cpanel

# DESCRIPTION

CLI for cPanel UAPI and also API 2, due to missing functionality in UAPI.

Stores session token in `~/.cpanel-token`, a two-line file. First line
is the URL component that goes after `cpsess`. Second is the `cpsession`
cookie, which you can get from your browser's DevTools.

Stores relevant domain name in `~/.cpanel-domain`.

# FUNCTIONS

Exportable:

## dispatch\_cmd\_print

Will print the return value, using ["dumper" in Mojo::Util](https://metacpan.org/pod/Mojo::Util#dumper) except for
`download`.

## dispatch\_cmd\_raw\_p

Returns a promise of the decoded JSON value or `download`ed content.

## dir\_walk\_p

Takes `$from_dir`, `$to_dir`, `$from_map`, `$to_map`. Copies the
information in the first directory to the second, using the respective
maps. Assumes UNIX-like semantics in filenames, i.e. `$dir/$file`.

Returns a promise of completion.

The maps are hash-refs whose values are functions, and the keys are:

### ls

Takes `$dir`. Returns a promise of two hash-refs, of directories and of
files. Each has keys of relative filename, values are an array-ref
containing a string octal number representing UNIX permissions, and a
number giving the `mtime`. Must reject if does not exist.

### mkdir

Takes `$dir`. Returns a promise of having created the directory.

### read

Takes `$dir`, `$file`. Returns a promise of the file contents.

### write

Takes `$dir`, `$file`. Returns a promise of having written the file
contents.

### chmod

Takes `$path`, `$perms`. Returns a promise of having changed the
permissions.

# SEE ALSO

[https://documentation.cpanel.net/display/DD/Guide+to+UAPI](https://documentation.cpanel.net/display/DD/Guide+to+UAPI)

[https://documentation.cpanel.net/display/DD/Guide+to+cPanel+API+2](https://documentation.cpanel.net/display/DD/Guide+to+cPanel+API+2)

# AUTHOR

Ed J

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
