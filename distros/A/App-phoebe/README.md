# NAME

Phoebe - serve a wiki as a Gemini site

**Table of Contents**

- [Name](#name)
- [Synopsis](#synopsis)
- [Description](#description)
- [Gemtext](#gemtext)
- [Editing the wiki](#editing-the-wiki)
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Quickstart](#quickstart)
- [Image uploads](#image-uploads)
- [Using systemd](#using-systemd)
- [Troubleshooting](#troubleshooting)
- [Files](#files)
- [Options](#options)
- [Files](#files)
- [Notes](#notes)
- [Security](#security)
- [Privacy](#privacy)
- [Example](#example)
- [Certificates and file permission](#certificates-and-file-permission)
- [Main page and title](#main-page-and-title)
- [Gus and robots.txt](#gus-and-robots-txt)
- [Limited, read-only http support](#limited-read-only-http-support)
- [Configuration](#configuration)
- [Wiki spaces](#wiki-spaces)
- [Tokens per wiki space](#tokens-per-wiki-space)
- [Client certificates](#client-certificates)
- [Virtual hosting](#virtual-hosting)
- [Multiple certificates](#multiple-certificates)
- [Css for the web](#css-for-the-web)
- [Favicon for the web](#favicon-for-the-web)
- [See also](#see-also)
- [License](#license)

# SYNOPSIS

**phoebe** \[**--host=**_hostname_ ...\] \[**--port=**_port_\]
\[**--cert\_file=**_filename_\] \[**--key\_file=**_filename_\]
\[**--log\_level=error**|**warn**|**info**|**debug**\] \[**--log\_file=**_filename_\]
\[**--wiki\_dir=**_directory_\] \[**--wiki\_token=**_token_ ...\]
\[**--wiki\_page=**_pagename_ ...\] \[**--wiki\_main\_page=**_pagename_\]
\[**--wiki\_mime\_type=**_mimetype_ ...\] \[**--wiki\_page\_size\_limit=**_n_\]
\[**--wiki\_space=**_space_ ...\]

# DESCRIPTION

Phoebe does two and a half things:

It's a program that you run on a computer and other people connect to it using
their Gemini client in order to read the pages on it.

It's a wiki, which means that people can edit the pages without needing an
account. All they need is a client that speaks both Gemini and Titan, and the
password. The default password is "hello". 😃

People can also access it using a regular web browser. They'll get a very
simple, read-only version of the site.

To take a look for yourself, check out the test wiki via the web or via the web.

- [https://gemini.circumlunar.space/clients.html](https://gemini.circumlunar.space/clients.html)
- [https://transjovian.org:1965/test](https://transjovian.org:1965/test)
- [gemini://transjovian.org/test](gemini://transjovian.org/test)

# GEMTEXT

Pages are written in gemtext, a lightweight hypertext format. You can use your
favourite text editor to write them.

A text line is a paragraph of text.

    This is a paragraph.
    This is another paragraph.

A link line starts with "=>", a space, a URL, optionally followed by whitespace
and some text; the URL can be absolute or relative.

    => http://transjovian.org/ The Transjovian Council on the web
    => Welcome                 Welcome to The Transjovian Council

A line starting with "\`\`\`" toggles preformatting on and off.

    Example:
    ```
    ./phoebe
    ```

A line starting with "#", "##", or "###", followed by a space and some text is a
heading.

    ## License
    The GNU Affero General Public License.

A line starting with "\*", followed by a space and some text is a list item.

    * one item
    * another item

A line starting with ">", followed by a space and some text is a quote.

    The monologue at the end is fantastic, with the city lights and the rain.
    > I've seen things you people wouldn't believe.

# EDITING THE WIKI

How do you edit a Phoebe wiki? You need to use a Titan-enabled client.

Titan is a companion protocol to Gemini: it allows clients to upload files to
Gemini sites, if servers allow this. On Phoebe, you can edit "raw" pages. That
is, at the bottom of a page you'll see a link to the "raw" page. If you follow
it, you'll see the page content as plain text. You can submit a changed version
of this text to the same URL using Titan. There is more information for
developers available on Community Wiki. [https://communitywiki.org/wiki/Titan](https://communitywiki.org/wiki/Titan)

Known clients:

This repository comes with a Perl script called `titan` to upload files.
[https://alexschroeder.ch/cgit/phoebe/plain/titan](https://alexschroeder.ch/cgit/phoebe/plain/titan)

_Gemini Write_ is an extension for the Emacs Gopher and Gemini client
_Elpher_. [https://alexschroeder.ch/cgit/gemini-write/](https://alexschroeder.ch/cgit/gemini-write/)
[https://thelambdalab.xyz/elpher/](https://thelambdalab.xyz/elpher/)

Gemini & Titan for Bash are two shell functions that allow you to download and
upload files. [https://alexschroeder.ch/cgit/gemini-titan/about/](https://alexschroeder.ch/cgit/gemini-titan/about/)

# INSTALLATION

Using `cpan`:

    cpan App::phoebe

Manual install:

    perl Makefile.PL
    make
    make install

## Dependencies

Perl libraries you need to install if you want to run Phoebe:

- [Algorithm::Diff](https://metacpan.org/pod/Algorithm%3A%3ADiff), or `libalgorithm-diff-xs-perl`
- [File::ReadBackwards](https://metacpan.org/pod/File%3A%3AReadBackwards), or `libfile-readbackwards-perl`
- [File::Slurper](https://metacpan.org/pod/File%3A%3ASlurper), or `libfile-slurper-perl`
- [Mojolicious](https://metacpan.org/pod/Mojolicious), or `libmojolicious-perl`
- [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL), or `libio-socket-ssl-perl`
- [Modern::Perl](https://metacpan.org/pod/Modern%3A%3APerl), or `libmodern-perl-perl`
- [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape), or `liburi-escape-xs-perl`
- [Net::IDN::Encode](https://metacpan.org/pod/Net%3A%3AIDN%3A%3AEncode), or `libnet-idn-encode-perl`
- [Encode::Locale](https://metacpan.org/pod/Encode%3A%3ALocale), or `libencode-locale-perl`

I'm going to be using `curl` and `openssl` in the ["Quickstart"](#quickstart) instructions,
so you'll need those tools as well. And finally, when people download their
data, the code calls `tar` (available from packages with the same name on
Debian derived systems).

The `update-readme.pl` script I use to generate `README.md` also requires some
libraries:

- [Pod::Markdown](https://metacpan.org/pod/Pod%3A%3AMarkdown), or `libpod-markdown-perl`
- [Text::Slugify](https://metacpan.org/pod/Text%3A%3ASlugify), which has no Debian package, apparently 😭

## Quickstart

I'm going to assume that you're going to create a new user just to be safe.

    sudo adduser --disabled-login --disabled-password phoebe
    sudo su phoebe --shell=/bin/bash
    cd

Now you're in your home directory, `/home/phoebe`. We're going to install
things right here.

    cpan App::phoebe

Start Phoebe. It's going to prompt you for a hostname and create certificates
for you. If in doubt, answer `localhost`. The certificate and a private key are
stored in the `cert.pem` and `key.pem` files, using elliptic curves, valid for
five years, without password protection.

    perl5/bin/phoebe

This starts the server in the foreground. If it aborts, see the
["Troubleshooting"](#troubleshooting) section below. If it runs, open a second terminal and test
it:

    perl5/bin/gemini gemini://localhost/

You should see a Gemini page starting with the following:

    20 text/gemini; charset=UTF-8
    Welcome to Phoebe!

Success!! 😀 🚀🚀

Let's create a new page using the Titan protocol, from the command line:

    echo "Welcome to the wiki!" > test.txt
    echo "Please be kind." >> test.txt
    perl5/bin/titan --url=titan://localhost/raw/Welcome --token=hello test.txt

You should get a nice redirect message, with an appropriate date.

    30 gemini://localhost:1965/page/Welcome

You can check the page, now (replacing the appropriate date):

    perl5/bin/gemini gemini://localhost:1965/page/Welcome

You should get back a page that starts as follows:

    20 text/gemini; charset=UTF-8
    Welcome to the wiki!
    Please be kind.

Yay! 😁🎉 🚀🚀

If you have a bunch of Gemtext files in a directory, you can upload them all in
one go:

    titan --url=titan://localhost/ --token=hello *.gmi

## Image uploads

OK, how do image uploads work? First, we need to specify which MIME types Phoebe
accepts. The files are going to be served back with that MIME type, so even if
somebody uploads an executable and claim it's an image, other people's clients
will treat it as an image instead of executing it (one hopes!) – so let's start
with a list of common MIME types.

- `image/jpeg` is for photos (usually with the `jpg` extension)
- `image/png` is for graphics (usually with the `png` extension)
- `audio/mpeg` is for sound (usually with the `mp3` extension)

Let's continue using the setup we used for the ["Quickstart"](#quickstart) section. Restart
the server and allow photos:

    perl5/bin/phoebe --wiki_mime_type=image/jpeg

Upload the image using the `titan` script:

    perl5/bin/titan --url=titan://localhost:1965/jupiter.jpg \
      --token=hello Pictures/Planets/Juno.jpg

You should get back a redirect to the uploaded image:

    30 gemini://localhost:1965/file/jupiter.jpg

How did the `titan` script know the MIME-type to use for the upload? If you
don't specify a MIME-type using `--mime`, the `file` utility is called to
guess the MIME type of the file.

Test it:

    file --mime-type --brief Pictures/Planets/Juno.jpg

The result is the MIME-type we enabled for our wiki:

    image/jpeg

Here's what happens when you're trying to upload an unsupported MIME-type:

    titan --url=titan://localhost:1965/earth.png \
      --token=hello Pictures/Planets/Earth.png

What you get back explains the problem:

    59 This wiki does not allow image/png

In order to allow such graphics as well, you need to restart Phoebe:

    perl phoebe --wiki_mime_type=image/jpeg --wiki_mime_type=image/png

Except that in my case, the image is too big:

    59 This wiki does not allow more than 100000 bytes per page

I could scale it down before I upload the image, using `convert` (which is part
of ImageMagick):

    convert -scale 20% Pictures/Planets/Earth.png earth-small.png

Try again:

    titan --url=titan://localhost:1965/earth.png \
      --token=hello earth-small.png

Alternatively, you can increase the size limit using the
`--wiki_page_size_limit` option, but you need to restart Phoebe:

    perl phoebe --wiki_page_size_limit=10000000 \
      --wiki_mime_type=image/jpeg --wiki_mime_type=image/png

Now you can upload about 10MB…

## Using systemd

Systemd is going to handle daemonisation for us. There's more documentation
available online.
[https://www.freedesktop.org/software/systemd/man/systemd.service.html](https://www.freedesktop.org/software/systemd/man/systemd.service.html).

Basically, this is the template for our service:

    [Unit]
    Description=Phoebe
    After=network.target
    [Service]
    Type=simple
    WorkingDirectory=/home/phoebe
    ExecStart=/home/phoebe/phoebe
    Restart=always
    User=phoebe
    Group=phoebe
    [Install]
    WantedBy=multi-user.target

Save this as `phoebe.service`, and then link it:

    sudo ln -s /home/phoebe/phoebe.service /etc/systemd/system/

Reload systemd:

    sudo systemctl daemon-reload

Start Phoebe:

    sudo systemctl start phoebe

Check the log output:

    sudo journalctl --unit phoebe

## Troubleshooting

🔥 **1408A0C1:SSL routines:ssl3\_get\_client\_hello:no shared cipher** 🔥 If you
created a new certificate and key using elliptic curves using an older OpenSSL,
you might run into this. Try to create a RSA key instead. It is larger, but at
least it'll work.

    openssl req -new -x509 -newkey rsa \
    -days 1825 -nodes -out cert.pem -keyout key.pem

# FILES

Your home directory should now also contain a wiki directory called `wiki`,
your wiki directory. In it, you'll find a few more files:

`page` is the directory with all the page files in it; each file has the `gmi`
extension and should be written in Gemtext format

`index` is a file containing all the files in your `page` directory for quick
access; if you create new files in the `page` directory, you should delete the
`index` file – it will get regenerated when needed; the format is one page name
(without the `.gmi` extension) per line, with lines separated from each other
by a single `\n`

`keep` is the directory with all the old revisions of pages in it – if you've
only made one change, then it won't exist; if you don't care about the older
revisions, you can delete them; assuming you have a page called `Welcome` and
edit it once, you have the current revision as `page/Welcome.gmi`, and the old
revision in `keep/Welcome/1.gmi` (the page name turns into a subdirectory and
each revision gets an apropriate number)

`file` is the directory with all the uploaded files in it – if you haven't
uploaded any files, then it won't exist; you must explicitly allow MIME types
for upload using the `--wiki_mime_type` option (see _Options_ below)

`meta` is the directory with all the meta data for uploaded files in it – there
should be a file here for every file in the `file` directory; if you create new
files in the `file` directory, you should create a matching file here; if you
have a file `file/alex.jpg` you want to create a file `meta/alex.jpg`
containing the line `content-type: image/jpeg`

`changes.log` is a file listing all the pages made to the wiki; if you make
changes to the files in the `page` or `file` directory, they aren't going to
be listed in this file and thus people will be confused by the changes you made
– your call (but in all fairness, if you're collaborating with others you
probably shouldn't do this); the format is one change per line, with lines
separated from each other by a single `\n`, and each line consisting of time
stamp, pagename or filename, revision number if a page or 0 if a file, and the
numeric code of the user making the edit (see ["Privacy"](#privacy) below), all separated
from each other with a `\x1f`

`config` probably doesn't exist, yet; it is an optional file containing Perl
code where you can add new features and change how Phoebe works (see
["Configuration"](#configuration) below)

`conf.d` probably doesn't exist, either; it is an optional directory containing
even more Perl files where you can add new features and change how Phoebe works
(see ["Configuration"](#configuration) below); the idea is that people can share stand-alone
configurations that you can copy into this directory without having to edit your
own `config` file.

# OPTIONS

- `--wiki_token` is for the token that users editing pages have to provide;
      the default is "hello"; you can use this option multiple times and give
      different users different passwords, if you want
- `--wiki_page` is an extra page to show in the main menu; you can use this
      option multiple times; this is ideal for general items like _About_ or
      _Contact_
- `--wiki_main_page` is the page containing your header for the main page;
      that's were you would put your ASCII art header, your welcome message, and
      so on, see ["Main Page and Title"](#main-page-and-title) below
- `--wiki_mime_type` is a MIME type to allow for uploads; text/plain is
      always allowed and doesn't need to be listed; you can also just list the
      type without a subtype, eg. `image` will allow all sorts of images (make
      sure random people can't use your server to exchange images – set a
      password using `--wiki_token`)
- `--wiki_page_size_limit` is the number of bytes to allow for uploads,
      both for pages and for files; the default is 10000 (10kB)
- `--host` is the hostname to serve; the default is `localhost` – you
      probably want to pick the name of your machine, if it is reachable from
      the Internet; if you use it multiple times, each host gets its own wiki
      space (see `--wiki_space` below)
- `--port` is the port to use; the default is 1965
- `--wiki_dir` is the wiki data directory to use; the default is either the
      value of the `PHOEBE_DATA_DIR` environment variable, or the "./wiki"
      subdirectory
- `--wiki_space` adds an extra space that acts as its own wiki; a
      subdirectory with the same name gets created in your wiki data directory
      and thus you shouldn't name spaces like any of the files and directories
      already there (see ["Wiki Directory"](#wiki-directory)); not that settings such as
      `--wiki_page` and `--wiki_main_page` apply to all spaces, but the page
      content will be different for every wiki space
- `--cert_file` is the certificate PEM file to use; the default is
      `cert.pem`
- `--key_file` is the private key PEM file to use; the default is
      `key.pem`
- `--log_level` is the log level to use (`fatal`, `error`, `warn`,
      `info`, `debug`); the default is `warn`
- `--log_file` is the log file to use; the default is undefined, which
      means that STDERR is used

## FILES

If you allow uploads of binary files, these are stored separately from the
regular pages; the wiki doesn't keep old revisions of files around. If somebody
overwrites a file, the old revision is gone.

You definitely don't want random people uploading all sorts of images, videos
and binaries to your server. Make sure you set up those [tokens](#security)
using `--wiki_token`!

# NOTES

## Security

The server uses "access tokens" to check whether people are allowed to edit
files. You could also call them "passwords", if you want. They aren't associated
with a username. You set them using the `--wiki_token` option. By default, the
only password is "hello". That's why the Titan command above contained
"token=hello". 😊

If you're going to check up on your wiki often (daily!), you could just tell
people about the token on a page of your wiki. Spammers would at least have to
read the instructions and in my experience the hardly ever do.

You could also create a separate password for every contributor and when they
leave the project, you just remove the token from the options and restart
Phoebe. They will no longer be able to edit the site.

## Privacy

The server only actively logs changes to pages. It calculates a "code" for every
contribution: it is a four digit octal code. The idea is that you could colour
every digit using one of the eight standard terminal colours and thus get little
four-coloured flags.

This allows you to make a pretty good guess about edits made by the same person,
without telling you their IP numbers.

The code is computed as follows: the IP numbers is turned into a 32bit number
using a hash function, converted to octal, and the first four digits are the
code. Thus all possible IP numbers are mapped into 8⁴=4096 codes.

If you increase the log level, the server will produce more output, including
information about the connections happening, like `2020/06/29-15:35:59 CONNECT
SSL Peer: "[::1]:52730" Local: "[::1]:1965"` and the like (in this case `::1`
is my local address so that isn't too useful but it could also be your visitor's
IP numbers, in which case you will need to tell them about it using in order to
comply with the
[GDPR](https://en.wikipedia.org/wiki/General_Data_Protection_Regulation).

# EXAMPLE

Here's an example for how to start Phoebe. It listens on `localhost` port 1965,
adds the "Welcome" and the "About" page to the main menu, and allows editing
using one of two tokens.

    perl phoebe \
      --wiki_token=Elrond \
      --wiki_token=Thranduil \
      --wiki_page=Welcome \
      --wiki_page=About

Here's what my `phoebe.service` file actually looks like:

    [Unit]
    Description=Phoebe
    After=network.target
    [Install]
    WantedBy=multi-user.target
    [Service]
    Type=simple
    WorkingDirectory=/home/alex/farm
    Restart=always
    User=alex
    Group=ssl-cert
    ExecStart=/home/alex/src/phoebe/script/phoebe \
     --port=1965 \
     --log_level=info \
     --wiki_dir=/home/alex/phoebe \
     --host=transjovian.org \
     --cert_file=/var/lib/dehydrated/certs/transjovian.org/fullchain.pem \
     --key_file=/var/lib/dehydrated/certs/transjovian.org/privkey.pem \
     --host=toki.transjovian.org \
     --cert_file=/var/lib/dehydrated/certs/transjovian.org/fullchain.pem \
     --key_file=/var/lib/dehydrated/certs/transjovian.org/privkey.pem \
     --host=vault.transjovian.org \
     --cert_file=/var/lib/dehydrated/certs/transjovian.org/fullchain.pem \
     --key_file=/var/lib/dehydrated/certs/transjovian.org/privkey.pem \
     --host=communitywiki.org \
     --cert_file=/var/lib/dehydrated/certs/communitywiki.org/fullchain.pem \
     --key_file=/var/lib/dehydrated/certs/communitywiki.org/privkey.pem \
     --host=alexschroeder.ch \
     --cert_file=/var/lib/dehydrated/certs/alexschroeder.ch/fullchain.pem \
     --key_file=/var/lib/dehydrated/certs/alexschroeder.ch/privkey.pem \
     --host=next.oddmuse.org \
     --cert_file=/var/lib/dehydrated/certs/oddmuse.org/fullchain.pem \
     --key_file=/var/lib/dehydrated/certs/oddmuse.org/privkey.pem \
     --host=emacswiki.org \
     --cert_file=/var/lib/dehydrated/certs/emacswiki.org/fullchain.pem \
     --key_file=/var/lib/dehydrated/certs/emacswiki.org/privkey.pem \
     --wiki_main_page=Welcome \
     --wiki_page=About \
     --wiki_mime_type=image/png \
     --wiki_mime_type=image/jpeg \
     --wiki_mime_type=audio/mpeg \
     --wiki_space=transjovian.org/test \
     --wiki_space=transjovian.org/phoebe \
     --wiki_space=transjovian.org/anthe \
     --wiki_space=transjovian.org/gemini \
     --wiki_space=transjovian.org/titan

## Certificates and File Permission

In the example above, I'm using certificates I get from Let's Encrypt. Thus, the
regular website served on port 443 and the Phoebe website on port 1965 use the
same certificates. My problem is that for the regular website, Apache can read
the certificates, but in the setup above Phoebe runs as the user `alex` and
cannot access the certificates. My solution is to use the group `ssl-cert`.
This is the group that already has read access to `/etc/ssl/private` on my
system. I granted the following permissions:

    drwxr-x--- root ssl-cert /var/lib/dehydrated/certs
    drwxr-s--- root ssl-cert /var/lib/dehydrated/certs/*
    drwxr----- root ssl-cert /var/lib/dehydrated/certs/*/*.pem

## Main Page and Title

The main page will include ("transclude") a page of your choosing if you use the
`--wiki_main_page` option. This also sets the title of your wiki in various
places like the RSS and Atom feeds.

In order to be more flexible, the name of the main page does not get printed. If
you want it, you need to add it yourself using a header. This allows you to keep
the main page in a page called "Welcome" containing some ASCII art such that the
word "Welcome" does not show on the main page. This assumes you're using
`--wiki_main_page=Welcome`, of course.

If you have pages with names that start with an ISO date like 2020-06-30, then
I'm assuming you want some sort of blog. In this case, up to ten of them will be
shown on your front page.

## GUS and robots.txt

There are search machines out there that will index your site. Ideally, these
wouldn't index the history pages and all that: they would only get the list of
all pages, and all the pages. I'm not even sure that we need them to look at all
the files. The Robots Exclusion Standard lets you control what the bots ought to
index and what they ought to skip. It doesn't always work.
[https://en.wikipedia.org/wiki/Robots\_exclusion\_standard](https://en.wikipedia.org/wiki/Robots_exclusion_standard)

Here's my suggestion:

    User-agent: *
    Disallow: /raw/*
    Disallow: /html/*
    Disallow: /diff/*
    Disallow: /history/*
    Disallow: /do/changes*
    Disallow: /do/all/changes*
    Disallow: /do/all/latest/changes*
    Disallow: /do/rss
    Disallow: /do/atom
    Disallow: /do/all/atom
    Disallow: /do/new
    Disallow: /do/more/*
    Disallow: /do/match
    Disallow: /do/search
    # allowing do/index!
    Crawl-delay: 10

In fact, as long as you don't create a page called `robots` then this is what
gets served. I think it's a good enough way to start. If you're using spaces,
the `robots` pages of all the spaces are concatenated.

If you want to be more paranoid, create a page called `robots` and put this on
it:

    User-agent: *
    Disallow: /

Note that if you've created your own `robots` page, and you haven't decided to
disallow them all, then you also have to do the right thing for all your spaces,
if you use them at all.

## Limited, read-only HTTP support

You can actually look at your wiki pages using a browser! But beware: these days
browser will refuse to connect to sites that have self-signed certificates.
You'll have to click buttons and make exceptions and all of that, or get your
certificate from Let's Encrypt or the like. Anyway, it works in theory. If you
went through the ["Quickstart"](#quickstart), visiting `https://localhost:1965/` should
work!

Notice that Phoebe doesn't have to live behind another web server like
Apache or nginx. It's a (simple) web server, too!

Here's how you could serve the wiki both on Gemini, and the standard HTTPS port,
443:

    sudo ./phoebe --port=443 --port=1965 \
      --user=$(id --user --name) --group=$(id --group  --name)

We need to use `sudo` because all the ports below 1024 are priviledge ports and
that includes the standard HTTPS port. Since we don't want the server itself to
run with all those priviledges, however, I'm using the `--user` and `--group`
options to change effective and user and group ID. The `id` command is used to
get your user and your group IDs instead. If you've followed the ["Quickstart"](#quickstart)
and created a separate `phoebe` user, you could simply use `--user=phoebe` and
`--group=phoebe` instead. 👍

## Configuration

This section describes some hooks you can use to customize your wiki using the
`config` file, or using a Perl file (ending in `*.pl` or `*.pm`) in the
`conf.d` directory. Once you're happy with the changes you've made, reload the
server to make it read the config file. You can do that by sending it the HUP
signal, if you know the pid, or if you have a pid file:

    kill -s SIGHUP `cat phoebe.pid`

Here are the ways you can hook into Phoebe code:

`@extensions` is a list of code references allowing you to handle additional
URLs; return 1 if you handle a URL; each code reference gets called with $stream
([Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AStream)), the first line of the request (a Gemini URL, a Gopher
selector, a finger user, a HTTP request line), a hash reference for the headers
(in the case of HTTP requests), and a buffer of bytes (e.g. for Titan or HTTP
PUT or POST requests)

`@main_menu` adds more lines to the main menu, possibly links that aren't
simply links to existing pages

`@footer` is a list of code references allowing you to add things like licenses
or contact information to every page; each code reference gets called with
$stream ([Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AStream)), $host, $space, $id, $revision, and $format
('gemini' or 'html') used to serve the page; return a gemtext string to append
at the end; the alternative is to overwrite the `footer` or `html_footer` subs
– the default implementation for Gemini adds History, Raw text and HTML link,
and `@footer` to the bottom of every page; the default implementation for HTTP
just adds `@footer` to the bottom of every page

If you do hook into Phoebe's code, you probably want to make use of the
following variables:

`$server` stores the command line options provided by the user.

`$log` is how you log things.

A very simple example to add a contact mail at the bottom of every page; this
works for both Gemini and the web:

    package App::Phoebe;
    use Modern::Perl;
    our (@footer);
    push(@footer, sub { '=> mailto:alex@alexschroeder.ch Mail' });

This prints a very simply footer instead of the usual footer for Gemini, as the
`footer` function is redefined. At the same time, the `@footer` array is still
used for the web:

    package App::Phoebe;
    use Modern::Perl;
    our (@footer); # HTML only
    push(@footer, sub { '=> https://alexschroeder.ch/wiki/Contact Contact' });
    # footer sub is Gemini only
    no warnings qw(redefine);
    sub footer {
      return '—' x 10 . "\n" . '=> mailto:alex@alexschroeder.ch Mail';
    }

This example also shows how to redefine existing code in your config file
without the warning "Subroutine … redefined".

Here's a more elaborate example to add a new action the main menu and a handler
for it:

    package App::Phoebe;
    use Modern::Perl;
    our (@extensions, @main_menu);
    push(@main_menu, "=> gemini://localhost/do/test Test");
    push(@extensions, \&serve_test);
    sub serve_test {
      my $stream = shift;
      my $url = shift;
      my $headers = shift;
      my $host = host_regex();
      my $port = port($stream);
      if ($url =~ m!^gemini://($host)(?::$port)?/do/test$!) {
        $stream->write("20 text/plain\r\n");
        $stream->write("Test\n");
        return 1;
      }
      return;
    }
    1;

## Wiki Spaces

Wiki spaces are separate wikis managed by the same Phoebe server, on the
same machine, but with data stored in a different directory. If you used
`--wiki_space=alex` and `--wiki_space=berta`, for example, then you'd have
three wikis in total:

- `gemini://localhost/` is the main space that continues to be available
- `gemini://localhost/alex/` is the wiki space for Alex
- `gemini://localhost/berta/` is the wiki space for Berta

Note that all three spaces are still editable by anybody who knows any of the
[tokens](#security).

## Tokens per Wiki Space

Per default, there is simply one set of tokens which allows the editing of the
wiki, and all the wiki spaces you defined. If you want to give users a token
just for their space, you can do that, too. Doing this is starting to strain the
command line interface, however, and therefore the following illustrates how to
do more advanced configuration using the config file:

    package App::Phoebe;
    use Modern::Perl;
    our ($server);
    $server->{wiki_space_token}->{alex} = ["*secret*"];

The code above sets up the `wiki_space_token` property. It's a hash reference
where keys are existing wiki spaces and values are array references listing the
valid tokens for that space (in addition to the global tokens that you can set
up using `--wiki_token` which defaults to the token "hello"). Thus, the above
code sets up the token `*secret*` for the `alex` wiki space.

You can use the config file to change the values of other properties as well,
even if these properties are set via the command line.

    package App::Phoebe;
    use Modern::Perl;
    our ($server);
    $server->{wiki_token} = [];

This code simply deactivates the token list. No more tokens!

## Client Certificates

Phoebe serves a public wiki by default. Limiting editing to known users (that
is, known client certificates) is possible. Here's a config file using client
certificates to limit writing to a single, known fingerprint:

    package App::Phoebe;
    use Modern::Perl;
    our ($server, @extensions, $log);
    my @fingerprints = ('sha256$e4b871adf0d74d9ab61fbf0b6773d75a152594090916834278d416a769712570');
    push(@extensions, \&protected_wiki);
    sub protected_wiki {
      my $stream = shift;
      my $url = shift;
      my $hosts = host_regex();
      my $port = port($stream);
      my $spaces = space_regex($stream);
      my $fingerprint = $server->{client}->get_fingerprint();
      if (my ($host, $path) = $url =~ m!^titan://($hosts)(?::$port)?([^?#]*)!) {
        my ($space, $resource) = $path =~ m!^(?:/($spaces))?(?:/raw)?/([^/;=&]+(?:;\w+=[^;=&]+)+)!;
        if (not $resource) {
          $log->debug("The Titan URL is malformed: $path $spaces");
          $stream->write("59 The Titan URL is malformed\r\n");
        } elsif ($fingerprint and grep { $_ eq $fingerprint} @fingerprints) {
          $log->info("Successfully identified client certificate");
          my ($id, @params) = split(/[;=&]/, $resource);
          save_page($stream, $host, space($stream, $host, $space), decode_utf8(uri_unescape($id)),
                            {map {decode_utf8(uri_unescape($_))} @params});
        } elsif ($fingerprint) {
          $log->info("Unknown client certificate $fingerprint");
          $stream->write("61 Your client certificate is not authorized for editing\r\n");
        } else {
          $log->info("Requested client certificate");
          $stream->write("60 You need a client certificate to edit this wiki\r\n");
        }
        return 1;
      }
      return;
    }
    1;

`@fingerprints` is a list, so you could add more fingerprints:

    my @fingerprints = qw(
      sha256$e4b871adf0d74d9ab61fbf0b6773d75a152594090916834278d416a769712570
      sha256$4a948f5a11f4a81d0a2e8b60b1e4b3c9d1e25f4d95694965d98b333a443a3b25);

Or you could read them from a file:

    use File::Slurper qw(read_lines);
    my @fingerprints = read_lines("fingerprints");

The important part is that this code matches the same Titan requests as the
default code, and it comes first. Thus, the old code can no longer be reached
and this code checks for a known client certificate fingerprint.

To be sure, it doesn't check anything else! It doesn't check whether the client
certificate has expired, for example.

You could, for example, install Phoebe, use the code above for your config
file, and replace the fingerprint with the fingerprint of your own client
certificate. The `Makefile` allows you to easily create such a certificate:

    make client-cert

Answer at least one of the questions OpenSSL asks of you and you should now have
a `client-cert.pem` and a `client-key.pem` file. To get the fingerprint of
your client certificate:

    make client-fingerprint

The output is the fingerprint you need to put into your config file.

## Virtual Hosting

Sometimes you want have a machine reachable under different domain names and you
want each domain name to have their own wiki space, automatically. You can do
this by using multiple `--host` options.

Here's a simple, stand-alone setup that will work on your local machine. These
are usually reachable using the IPv4 `127.0.0.1` or the name `localhost`. The
following command tells Phoebe to serve both `127.0.0.1` and `localhost`
(the default is to just serve `localhost`).

    perl phoebe --host=127.0.0.1 --host=localhost

Visit both at [gemini://localhost/](gemini://localhost/) and [gemini://127.0.0.1/](gemini://127.0.0.1/), and create a
new page in each one, then examine the data directory `wiki`. You'll see both
`wiki/localhost` and `wiki/127.0.0.1`.

If you're using more wiki spaces, you need to prefix them with the respective
hostname if you use more than one:

    perl phoebe --host=127.0.0.1 --host=localhost \
        --wiki_space=127.0.0.1/alex --wiki_space=localhost/berta

In this situation, you can visit [gemini://127.0.0.1/](gemini://127.0.0.1/),
[gemini://127.0.0.1/alex/](gemini://127.0.0.1/alex/), [gemini://localhost/](gemini://localhost/), and
[gemini://localhost/berta/](gemini://localhost/berta/), and they will all be different.

If this is confusing, remember that not using virtual hosting and not using
spaces is fine, too. 😀

## Multiple Certificates

If you're using virtual hosting as discussed above, you have two options: you
can use one certificate for all your hostnames, or you can use different
certificates for the hosts. If you want to use just one certificate for all your
hosts, you don't need to do anything else. If you want to use different
certificates for different hosts, you have to specify them all on the command
line. Generally speaking, use `--host` to specifiy one or more hosts, followed
by both `--cert_file` and `--key_file` to specifiy the certificate and key to
use for the hosts.

For example:

    perl phoebe --host=transjovian.org \
        --cert_file=/var/lib/dehydrated/certs/transjovian.org/cert.pem \
        --key_file=/var/lib/dehydrated/certs/transjovian.org/privkey.pem \
        --host=alexschroeder.ch \
        --cert_file=/var/lib/dehydrated/certs/alexschroeder.ch/cert.pem \
        --key_file=/var/lib/dehydrated/certs/alexschroeder.ch/privkey.pem

## CSS for the Web

The wiki can also answer web requests. By default, it only does that on port
1965\. The web pages refer to a CSS file at `/default.css`, and the response to
a request for this CSS is served by a function that you can override in your
config file. The following would be the beginning of a CSS that supports a dark
theme, for example. The Cache-Control header makes sure browsers don't keep
trying to revalidate the CSS more than once a day.
[https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)

    our ($log);

    sub serve_css_via_http {
      my $stream = shift;
      $log->info("Serving CSS via HTTP");
      $stream->write("HTTP/1.1 200 OK\r\n");
      $stream->write("Content-Type: text/css\r\n");
      $stream->write("Cache-Control: public, max-age=86400, immutable\r\n"); # 24h
      $stream->write("\r\n");
      $stream->write(<<'EOT');
    html { max-width: 70ch; padding: 2ch; margin: auto; }
    body { color: #111111; background-color: #fffff8; }
    a:link { color: #0000ee }
    a:visited { color: #551a8b }
    a:hover { color: #7a67ee }
    @media (prefers-color-scheme: dark) {
       body { color: #eeeee8; background-color: #333333; }
       a:link { color: #1e90ff }
       a:hover { color: #63b8ff }
       a:visited { color: #7a67ee }
    }
    EOT
    }

## Favicon for the Web

Here's an example where we a little Jupiter SVG is being served for the favicon,
for all hosts. You could, of course, accept the `$headers` as an additional
argument to `favicon`, match hostnames, pass the `$host` to
`serve_favicon_via_http`, and return different images depending on the host.
Let me know if you need this and you are stuck.

    our (@extensions, $log);

    push(@extensions, \&favicon);

    sub favicon {
      my $stream = shift;
      my $url = shift;
      if ($url =~ m!^GET /favicon.ico HTTP/1\.[01]$!) {
        serve_favicon_via_http($stream);
        return 1;
      }
      return 0;
    }

    sub serve_favicon_via_http {
      my $stream = shift;
      $log->info("Serving favicon via HTTP");
      $stream->write("HTTP/1.1 200 OK\r\n");
      $stream->write("Content-Type: image/svg+xml\r\n");
      $stream->write("Cache-Control: public, max-age=86400, immutable\r\n"); # 24h
      $stream->write("\r\n");
      $stream->write(<<'EOT');
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
    <circle cx="50" cy="50" r="45" fill="white" stroke="black" stroke-width="5"/>
    <line x1="12" y1="25" x2="88" y2="25" stroke="black" stroke-width="4"/>
    <line x1="5" y1="45" x2="95" y2="45" stroke="black" stroke-width="7"/>
    <line x1="5" y1="60" x2="95" y2="60" stroke="black" stroke-width="4"/>
    <path d="M20,73 C30,65 40,63 60,70 C70,72 80,73 90,72
             L90,74 C80,75 70,74 60,76 C40,83 30,81 20,73" fill="black"/>
    <ellipse cx="40" cy="73" rx="11.5" ry="4.5" fill="red"/>
    <line x1="22" y1="85" x2="78" y2="85" stroke="black" stroke-width="3"/>
    </svg>
    EOT
    }

# SEE ALSO

As you might have guessed, the system is easy to tinker with, if you know some
Perl. The Transjovian Council has a wiki space dedicated to Phoebe, and it
includes a section with more configuration examples, including simple comments
(append-only via Gemini), complex comments (editing via Titan or the web),
wholesale page editing via the web, user-agent blocking, and so on.
[gemini://transjovian.org/](gemini://transjovian.org/) [https://transjovian.org:1965/](https://transjovian.org:1965/)

# LICENSE

GNU Affero General Public License
