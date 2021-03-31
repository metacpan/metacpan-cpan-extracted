bookmarks - Export browser bookmarks as plain text.
===================================================

SYNOPSIS
--------

    $ bookmarks [-hVda] [-f format] [file ...]

    -h, --help      help
    -V, --version   version
    -d              debug
    -a              all files : process arguments and default locations
    -f format       any combination of letters t,u,d as title/url/description (default : tud)
    -s              find schemeless URLs in text files (default : no)


DESCRIPTION
-----------

`bookmarks` is a tool to export bookmarks from files supplied as arguments, or from browsers default locations (when called without arguments). The following sources are supported :

- Safari (_.plist_)
- Firefox (_.sqlite_)
- Chrome and Edge (_Bookmarks_)
- Internet Explorer (_Favorites_)
- Markdown (_.md_)
- Gemini (_.gmi_)
- Surfraw (same as plain text)
- Plain text (any other extension)

Default export format : `<title> <url> <description>`

- `<title>` is your bookmark's name, alias, or webpage title.
- `<url>` is your bookmark's address, URL or URI.
- `<description>` is empty for Chrome, Edge, Internet Explorer or Gemini. It 
  contains Safari 'Description', Firefox 'Tags' and what the Markdown spec
  calls the 'Title' (just the tooltip, actually).

Markdown, Gemini and plain text files are processed line by line (as UTF-8) :
```
  [markdown example](http://example.md/ "with description")
  => gemini://example.gmi gemini example
  plain text example http://example.txt with description
```


SEARCH BOOKMARKS INTERACTIVELY FROM CLI
---------------------------------------

This tool can be used to search, select and open bookmarks interactively from your terminal. The following instructions are for macOS.

![](tty.png)

Install the wonderful [fzf](https://github.com/junegunn/fzf) (available in [Homebrew](https://brew.sh)), [URI::Find](https://github.com/schwern/URI-Find) (CPAN), [App::uricolor](https://github.com/kal247/App-uricolor) (CPAN), and add these aliases to your shell :

**Open link(s) with default application :**
```
alias lk="bookmarks | uricolor | fzf --ansi --exact --multi | urifind | xargs open"
```

- `uricolor` colorizes URIs to distinguish them from title and description.
- `fzf` is a fuzzy finder : use TAB for multiple selection, press ENTER to confirm, or ESC to cancel.
- `urifind` extracts all URIs. Try `uricolor -s` and `urifind --schemeless` to find schemeless URLs.
- Selected URIs will open with your default browser or application.
- Since `open` uses macOS _Launch Services_ to determine which program to run, most common schemes such as `ftp://` or `ssh://` are automatically recognized.

N.B. On Windows, I use [busybox-w32](https://frippery.org/busybox/) and a file `lk.bat` containing : 
```
@echo off

bookmarks | uricolor | fzf --ansi --exact --multi | urifind | busybox xargs -n1 cmd /c start ""
````

**Copy link(s) to clipboard :**
```
alias lkc="bookmarks | uricolor | fzf --ansi --exact --multi | urifind | pbcopy"
```


CHECK LINKS STATUS
------------------

These examples use the tool _http_status_ provided by [HTTP::SimpleLinkChecker](https://metacpan.org/pod/HTTP::SimpleLinkChecker) (CPAN).

**Check links and show status :**
```
bookmarks -f u | xargs http_status
```

**Show only broken links (parallel) :**
```
bookmarks -f u | xargs -n10 -P16 http_status 2>/dev/null | perl -ne 'print if not /200$/'
```


INSTALLATION
------------

To install this module automatically from CPAN :

    cpan App::bookmarks

To install this module automatically from Git repository :

    cpanm https://github.com/kal247/App-bookmarks.git

To install this module manually, run the following commands :

    perl Makefile.PL
    make     
    make test
    make install


PREREQUISITES
-------------

All are optional.

- Safari : macOS
- Firefox : DBI, DBD::SQLite
- Chrome : File::Slurper, JSON
- Internet Explorer : Config::Any, Config::Tiny, Win32
- Plain text : URI::Find
- Markdown : none


SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command :

    perldoc bookmarks

You can also look for information at :

- CPAN

    [https://metacpan.org/release/App-bookmarks](https://metacpan.org/release/App-bookmarks)

- GITHUB

    [https://github.com/kal247/App-bookmarks](https://github.com/kal247/App-bookmarks)


LICENSE AND COPYRIGHT
---------------------

This software is Copyright (c) 2019-2021 by jul.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
