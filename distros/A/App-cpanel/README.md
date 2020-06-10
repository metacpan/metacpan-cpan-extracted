# NAME

App::cpanel - CLI for cPanel UAPI and API 2

# PROJECT STATUS

[![CPAN version](https://badge.fury.io/pl/App-cpanel.svg)](https://metacpan.org/pod/App::cpanel)

# SYNOPSIS

    $ cpanel get Notifications get_notifications_count
    $ cpanel get ResourceUsage get_usages
    $ cpanel get Fileman list_files dir=public_html
    $ cpanel get Fileman get_file_content dir=public_html file=index.html
    $ cpanel download public_html/index.html
    $ cpanel api2 Fileman fileop op=chmod metadata=0755 sourcefiles=public_html/cgi-bin/hello-world
    $ cpanel api2 Fileman fileop op=unlink sourcefiles=public_html/cgi-bin/hello-world
    $ cpanel api2 Fileman mkdir path= name=new-dir-at-top

    # this one is one at a time but can overwrite files
    $ cpanel api2 Fileman savefile dir=public_html/cgi-bin filename=hello-world content="$(cat public_html/cgi-bin/hello-world)"
    # this is multiple files but refuses to overwrite
    $ cpanel upload public_html/cgi-bin hello-world

# DESCRIPTION

CLI for cPanel UAPI and also API 2, due to missing functionality in UAPI.

Stores session token in `~/.cpanel-token`, a two-line file. First line
is the URL component that goes after `cpsess`. Second is the `cpsession`
cookie, which you can get from your browser's DevTools.

Stores relevant domain name in `~/.cpanel-domain`.

# SEE ALSO

https://documentation.cpanel.net/display/DD/Guide+to+UAPI

https://documentation.cpanel.net/display/DD/Guide+to+cPanel+API+2

# AUTHOR

Ed J

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
