So you want to read 1Password Interchange Format exports? This is the
right place indeed!

## Quick Start

1. download the bundle and make it executable:

        curl -LO https://github.com/polettix/App-OnePif/raw/master/bundle/1pif
        chmod +x 1pif

2. export all or part of 1Password database in the 1Password Interchange
Format (**beware that this is unencrypted**)

3. go in the export's main directory and run `1pif` downloaded above:

        cd /path/to/export
        /path/to/1pif

There you go, you'll see an interactive shell that you can play with. The
first command you probably want to try is `help`:

        1password> help
        Available commands:
        * quit (also: q, .q)
        exit the program immediately, exit code is 0
        * exit [code] (also: e)
        exit the program immediately, can accept optional exit code
        * file [filename] (also: f)
        set the filename to use for taking data (default: 'data1.pif')
        * types (also: ts)
        show available types and possible aliases
        * type [wanted] (also: t, use, u)
        get current default type or set it to wanted. It is possible to
        reset the default type by setting type "*" (no quotes)
        * list [type] (also: l)
        get a list for the current set type. By default no type is set
        and the list includes all elements, otherwise it is filtered
        by the wanted type.
        If type parameter is provided, work on specified type instead
        of default one.
        * print [ <id> ] (also: p)
        show record by provided id (look for ids with the list command).
        It is also possible to specify the type, in which case the id
        is interpreted in the context of the specific type.
        * search <query-string> (also: s)
        search for the query-string, literally. Looks for a substring in
        the YAML rendition of each record that is equal to the query-string,
        case-insensitively. If a type is set, the search is restricted to
        that type.

## Security

I'm no security expert, but it's easy to see that having an unencrypted
database of your stuff is not a great idea. If you really want to go this
way, you should at least take some care about where you save the
unencrypted stuff.

### Export (from MAC OS X)

My 1Password program runs on my personal Mac. When I want to do an export,
I:

1. use [`ramenc`][ramenc] to create an encrypted RAM disk, so that nothing
gets to the disk (or if it goes due to memory paging, it will be
encrypted):

        # 100 MB are plenty of space for me, your mileage may vary
        ramenc 100

2. do the export from 1Password to this encrypted RAM disk;

3. use [7-Zip][7zip] to put the export in an encrypted archive (this will
ask you for a passphrase to set on the archive):

        7z a -m0=lzma2 -mhe=on -mx=9 -mfb=64 -md=64m -ms=on -p -- \
            export.7z /Volumes/ramenc/1Password...

4. get rid of the export directory (make sure your archive is in a safe
place though!):

        # this gets rid of the encrypted RAM disk and its contents, for good
        ramenc off

### Access (from Linux)

I usually need to access the export from Linux and use [`1p`][1p] to do all
the heavy lifting. It assumes that some programs are available in the Linux
box, namely:

- `sudo`
- `cryptsetup` (in Debian, package `cryptsetup-bin` suffices)
- `badblocks`
- `mkfs.ext2`
- `losetup`
- `7z`

Most of the stuff in [`1p`][1p] were taken from [this article][erd] by
*WatsonDE* (in case the link goes awry, there's a cached copy in the
[Internet Archive][] [here][erda]).

To use [`1p`][1p], just make sure to have it and [`1pif`][1pif] in the same
directory, and run [`1p`][1p] with the path to the encrypted archive you
created (if you don't provide any, it will look in the current directory).



[ramenc]: https://github.com/polettix/App-OnePif/blob/master/bundle/ramenc
[7zip]: http://www.7-zip.org/
[1p]: https://github.com/polettix/App-OnePif/blob/master/bundle/1p
[erd]: http://www.backtrack-linux.org/forums/showthread.php?t=42033
[erda]: http://web.archive.org/web/20161202035137/http://www.backtrack-linux.org/forums/showthread.php?t=42033
[Internet Archive]: http://archive.org/web/
[1pif]: https://github.com/polettix/App-OnePif/blob/master/bundle/1pif
