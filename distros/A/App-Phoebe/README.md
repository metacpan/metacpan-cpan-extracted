# Phoebe Wiki

**Table of Contents**

- [phoebe](#phoebe)
- [Gemtext](#gemtext)
- [Editing the wiki](#editing-the-wiki)
- [Editing via the web](#editing-via-the-web)
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Quickstart](#quickstart)
- [Image uploads](#image-uploads)
- [Using systemd](#using-systemd)
- [Troubleshooting](#troubleshooting)
- [Files](#files)
- [Options](#options)
- [Uploads](#uploads)
- [Notes](#notes)
- [Security](#security)
- [Privacy](#privacy)
- [Example](#example)
- [Certificates and File Permission](#certificates-and-file-permission)
- [Main Page and Title](#main-page-and-title)
- [robots.txt](#robots-txt)
- [Configuration](#configuration)
- [Wiki Spaces](#wiki-spaces)
- [Tokens per Wiki Space](#tokens-per-wiki-space)
- [Virtual Hosting](#virtual-hosting)
- [Multiple Certificates](#multiple-certificates)
- [See also](#see-also)
- [License](#license)
- [gemini](#gemini)
- [Client Certificates](#client-certificates)
- [gemini-chat](#gemini-chat)
- [ijirait](#ijirait)
- [phoebe-ctl](#phoebe-ctl)
- [Commands](#commands)
- [spartan](#spartan)
- [titan](#titan)
- [App::Phoebe](#appphoebe)
- [App::Phoebe::BlockFediverse](#appphoebeblockfediverse)
- [App::Phoebe::Chat](#appphoebechat)
- [App::Phoebe::Comments](#appphoebecomments)
- [App::Phoebe::Css](#appphoebecss)
- [App::Phoebe::DebugIpNumbers](#appphoebedebugipnumbers)
- [App::Phoebe::Favicon](#appphoebefavicon)
- [App::Phoebe::Galleries](#appphoebegalleries)
- [App::Phoebe::Gopher](#appphoebegopher)
- [App::Phoebe::HeapDump](#appphoebeheapdump)
- [App::Phoebe::Iapetus](#appphoebeiapetus)
- [App::Phoebe::Ijirait](#appphoebeijirait)
- [App::Phoebe::MokuPona](#appphoebemokupona)
- [App::Phoebe::Oddmuse](#appphoebeoddmuse)
- [App::Phoebe::PageHeadings](#appphoebepageheadings)
- [App::Phoebe::RegisteredEditorsOnly](#appphoeberegisterededitorsonly)
- [App::Phoebe::Spartan](#appphoebespartan)
- [App::Phoebe::SpeedBump](#appphoebespeedbump)
- [App::Phoebe::StaticFiles](#appphoebestaticfiles)
- [App::Phoebe::TokiPona](#appphoebetokipona)
- [App::Phoebe::Web](#appphoebeweb)
- [App::Phoebe::WebComments](#appphoebewebcomments)
- [App::Phoebe::WebEdit](#appphoebewebedit)
- [App::Phoebe::Wikipedia](#appphoebewikipedia)

# phoebe

**phoebe** \[**--host=**_hostname_ ...\] \[**--port=**_port_\]
\[**--cert\_file=**_filename_\] \[**--key\_file=**_filename_\]
\[**--log\_level=error**|**warn**|**info**|**debug**\] \[**--log\_file=**_filename_\]
\[**--wiki\_dir=**_directory_\] \[**--wiki\_token=**_token_ ...\]
\[**--wiki\_page=**_pagename_ ...\] \[**--wiki\_main\_page=**_pagename_\]
\[**--wiki\_mime\_type=**_mimetype_ ...\] \[**--wiki\_page\_size\_limit=**_n_\]
\[**--wiki\_space=**_space_ ...\]

Phoebe does two and a half things:

It's a program that you run on a computer and other people connect to it using
their Gemini client in order to read the pages on it.

It's a wiki, which means that people can edit the pages without needing an
account. All they need is a client that speaks both Gemini and Titan, and the
password. The default password is "hello". 😃

Optionally, people can also access it using a regular web browser.

Gemini itself is very simple network protocol, like Gopher or Finger, but with
TLS. Gemtext is a very simple markup language, a bit like Markdown, but line
oriented. See ["GEMTEXT"](#gemtext).

To take a look for yourself, check out the test wiki via the web or via the web.

- [What is Gemini?](https://gemini.circumlunar.space/)
- [Gemini link collection](https://git.sr.ht/~kr1sp1n/awesome-gemini)
- [Test site, via the web](https://transjovian.org:1965/test)
- [Test site, via Gemini](gemini://transjovian.org/test)

# Gemtext

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

# Editing the wiki

How do you edit a Phoebe wiki? You need to use a Titan-enabled client.

Titan is a companion protocol to Gemini: it allows clients to upload files to
Gemini sites, if servers allow this. On Phoebe, you can edit "raw" pages. That
is, at the bottom of a page you'll see a link to the "raw" page. If you follow
it, you'll see the page content as plain text. You can submit a changed version
of this text to the same URL using Titan. There is more information for
developers available on Community Wiki. [https://communitywiki.org/wiki/Titan](https://communitywiki.org/wiki/Titan)

Known clients:

This repository comes with a Perl script called `titan` to upload files.
[https://alexschroeder.ch/cgit/phoebe/plain/script/titan](https://alexschroeder.ch/cgit/phoebe/plain/script/titan)

_Gemini Write_ is an extension for the Emacs Gopher and Gemini client
_Elpher_. [https://alexschroeder.ch/cgit/gemini-write/](https://alexschroeder.ch/cgit/gemini-write/)
[https://thelambdalab.xyz/elpher/](https://thelambdalab.xyz/elpher/)

Gemini & Titan for Bash are two shell functions that allow you to download and
upload files. [https://alexschroeder.ch/cgit/gemini-titan/about/](https://alexschroeder.ch/cgit/gemini-titan/about/)

## Editing via the web

The Configuration section of the Phoebe space on _The Transjovian Council_ has
an example config on how to enable editing via the web.

- [https://transjovian.org:1965/phoebe/page/Configuration](https://transjovian.org:1965/phoebe/page/Configuration)
- [gemini://transjovian.org/phoebe/page/Configuration](gemini://transjovian.org/phoebe/page/Configuration)

# Installation

Using `cpan`:

    cpan App::Phoebe

Manual install:

    perl Makefile.PL
    make
    make install

## Dependencies

If you are not using `cpan` or `cpanm` to install Phoebe, you'll need to
install the following dependencies:

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

    cpan App::Phoebe

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

    phoebe --wiki_mime_type=image/jpeg --wiki_mime_type=image/png

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

    phoebe --wiki_page_size_limit=10000000 \
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
    MemoryMax=100M
    MemoryHigh=90M
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

# Files

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

# Options

- `--wiki_token` is for the token that users editing pages have to
      provide; the default is "hello"; you can use this option multiple times
      and give different users different passwords, if you want
- `--wiki_page` is an extra page to show in the main menu; you can use
      this option multiple times; this is ideal for general items like _About_
      or _Contact_
- `--wiki_main_page` is the page containing your header for the main
      page; that's were you would put your ASCII art header, your welcome
      message, and so on, see ["Main Page and Title"](#main-page-and-title) below
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
- `--wiki_dir` is the wiki data directory to use; the default is either
      the value of the `PHOEBE_DATA_DIR` environment variable, or the "./wiki"
      subdirectory
- `--wiki_space` adds an extra space that acts as its own wiki; a
      subdirectory with the same name gets created in your wiki data directory
      and thus you shouldn't name spaces like any of the files and directories
      already there (see ["FILES"](#files)); not that settings such as
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

## Uploads

If you allow uploads of binary files, these are stored separately from the
regular pages; the wiki doesn't keep old revisions of files around. If somebody
overwrites a file, the old revision is gone.

You definitely don't want random people uploading all sorts of images, videos
and binaries to your server. Make sure you set up those [tokens](#security)
using `--wiki_token`!

# Notes

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

# Example

Here's an example for how to start Phoebe. It listens on `localhost` port 1965,
adds the "Welcome" and the "About" page to the main menu, and allows editing
using one of two tokens.

    phoebe \
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
    MemoryMax=100M
    MemoryHigh=90M
    ExecStart=/home/alex/src/phoebe/script/phoebe \
     --port=1965 \
     --log_level=debug \
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

## robots.txt

There are search machines out there that will index your site. Ideally, these
wouldn't index the history pages and all that: they would only get the list of
all pages, and all the pages. I'm not even sure that we need them to look at all
the files. The Robots Exclusion Standard lets you control what the bots ought to
index and what they ought to skip. It doesn't always work.
[https://en.wikipedia.org/wiki/Robots\_exclusion\_standard](https://en.wikipedia.org/wiki/Robots_exclusion_standard)

Here's my suggestion:

    User-agent: *
    Disallow: /raw
    Disallow: /html
    Disallow: /diff
    Disallow: /history
    Disallow: /do/comment
    Disallow: /do/changes
    Disallow: /do/all/changes
    Disallow: /do/all/latest/changes
    Disallow: /do/rss
    Disallow: /do/atom
    Disallow: /do/all/atom
    Disallow: /do/new
    Disallow: /do/more
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

## Configuration

See [App::Phoebe](https://metacpan.org/pod/App%3A%3APhoebe) for more information.

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

## Virtual Hosting

Sometimes you want have a machine reachable under different domain names and you
want each domain name to have their own wiki space, automatically. You can do
this by using multiple `--host` options.

Here's a simple, stand-alone setup that will work on your local machine. These
are usually reachable using the IPv4 `127.0.0.1` or the name `localhost`. The
following command tells Phoebe to serve both `127.0.0.1` and `localhost`
(the default is to just serve `localhost`).

    phoebe --host=127.0.0.1 --host=localhost

Visit both at [gemini://localhost/](gemini://localhost/) and [gemini://127.0.0.1/](gemini://127.0.0.1/), and create a
new page in each one, then examine the data directory `wiki`. You'll see both
`wiki/localhost` and `wiki/127.0.0.1`.

If you're using more wiki spaces, you need to prefix them with the respective
hostname if you use more than one:

    phoebe --host=127.0.0.1 --host=localhost \
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

    phoebe --host=transjovian.org \
        --cert_file=/var/lib/dehydrated/certs/transjovian.org/cert.pem \
        --key_file=/var/lib/dehydrated/certs/transjovian.org/privkey.pem \
        --host=alexschroeder.ch \
        --cert_file=/var/lib/dehydrated/certs/alexschroeder.ch/cert.pem \
        --key_file=/var/lib/dehydrated/certs/alexschroeder.ch/privkey.pem

# See also

As you might have guessed, the system is easy to tinker with, if you know some
Perl. The Transjovian Council has a wiki space dedicated to Phoebe, and it
includes a section with more configuration examples.
See [gemini://transjovian.org/](gemini://transjovian.org/) or [https://transjovian.org:1965/](https://transjovian.org:1965/).

# License

GNU Affero General Public License

# gemini

**gemini** \[**--help**\] \[**--verbose**\] \[**--cert\_file=**_filename_
**--key\_file=**_filename_\] _URL_

This is a very simple client. All it does is print the response. The header is
printed to standard error so the rest can be redirected to get just the content.

Usage:

    gemini gemini://alexschroeder.ch/Test

Download an image:

    gemini gemini://alexschroeder.ch:1965/do/gallery/2016-aminona/thumbs/Bisse_de_Tsittoret.jpg \
      > Bisse_de_Tsittoret.jpg

Download all the images on a page:

    for url in $(./gemini gemini://alexschroeder.ch:1965/do/gallery/2016-aminona \
                 | grep thumbs | cut --delimiter=' ' --fields=2); do
      echo $url
      ./gemini "$url" > $(basename "$url")
    done

In the shell script above, the first call to gemini gets the page with all the
links, grep then filters for the links to thumbnails, extract the URL using cut
(assuming a space between "=>" and the URL), and download each URL, and save the
output in the filename indicated by the URL.

## Client Certificates

You can provide a certificate and a key file:

        gemini --cert_file=cert.pem --key_file=key.pem \
          gemini://campaignwiki.org/play/ijirait

# gemini-chat

**gemini-chat** \[**--help**\] \[**--cert\_file=**_filename_
**--key\_file=**_filename_\] _URL_

All `gemini-chat` does is repeatedly post stuff to a Gemini URL. For example,
assume that there is a Phoebe wiki with chat enabled via [App::Phoebe::Chat](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AChat).
First, you connect to the _listen_ URL using `gemini`:

    gemini --cert_file=cert.pem --key_file=key.pem \
      gemini://localhost/do/chat/listen

Then you connect the chat client to the _say_ URL using `gemini-chat`:

    gemini-chat --cert=cert.pem --key=key.pem \
      gemini://transjovian.org/do/chat/say

At the prompt, type your message. What effectively happens is that all you type
ends up being sent to the server via a Gemini request:
`gemini://transjovian.org/do/chat/say?your%20text%20here`.

To generate your client certificate for 100 days and using “Alex” as your common
name:

    openssl req -new -x509 -newkey ec -subj "/CN=Alex" \
      -pkeyopt ec_paramgen_curve:prime256v1 -days 100 \
      -nodes -out cert.pem -keyout key.pem

# ijirait

**ijirait** \[**--help**\] \[**--verbose**\] \[**--stream**\] \[**--cert\_file=**_filename_
**--key\_file=**_filename_\] _URL_

This is a command-line client for Ijirait, a Gemini-based MUSH that can be run
by Phoebe. See [App::Phoebe::Ijirait](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AIjirait).

First, generate your client certificate for as many or as few days as you like:

    openssl req -new -x509 -newkey ec -subj "/CN=Alex" \
      -pkeyopt ec_paramgen_curve:prime256v1 -days 100 \
      -nodes -out cert.pem -keyout key.pem

Then start this program to play:

    ijirait --cert_file=cert.pem --key_file=key.pem \
      gemini://campaignwiki.org/play/ijirait

You can also use it to stream, i.e. get notified of events in real time:

    ijirait --cert_file=cert.pem --key_file=key.pem --stream \
      gemini://campaignwiki.org/play/ijirait/stream

Here are the Debian package names to satisfy the dependencies. Use `cpan` or
`cpanm` to install them.

- [Modern::Perl](https://metacpan.org/pod/Modern%3A%3APerl) from `libmodern-perl-perl`
- [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop) from `libmojolicious-perl`
- [Term::ReadLine::Gnu](https://metacpan.org/pod/Term%3A%3AReadLine%3A%3AGnu) from `libterm-readline-gnu-perl`
- [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape) from `liburi-escape-xs-perl`
- [Encode::Locale](https://metacpan.org/pod/Encode%3A%3ALocale) from `libencode-locale-perl`
- [Text::Wrapper](https://metacpan.org/pod/Text%3A%3AWrapper) from `libtext-wrapper-perl`

# phoebe-ctl

This script helps you maintain your Phoebe installation.

- **--wiki\_dir=**_DIR_

    This the wiki data directory to use; the default is either the value of the
    `GEMINI_WIKI_DATA_DIR` environment variable, or the `./wiki` subdirectory. Use
    it to specify a space, too.

- **--log=**_NUMBER_

    This is the log level to use. 1 only prints errors; 2 also prints warnings (this
    is the default); 3 prints any kind of information; 4 prints all sorts of info
    the developer wanted to see as they were fixing bugs.

## Commands

**phoebe-ctl help**

This is what you're reading right now.

**phoebe-ctl update-changes**

This command looks at all the pages in the `page` directory and generates new
entries for your changes log into `changes.log`.

**phoebe-ctl erase-page**

This command removes pages from the `page` directory, removes all the kept
revisions in the `keep` directory, and all the mentions in the `change.log`.
Use this if spammers and vandals created page names you want to eliminate.

**phoebe-ctl html-export** \[**--source=**`subdirectory` ...\]
\[**--target=**`directory`\] \[**--no-extension**\]

This command converts all the pages in the subdirectories provided to HTML and
writes the HTML files into the target directory. The subdirectories must exist
inside your wiki data directory. The default wiki data directory is `wiki` and
the default source subdirectory is undefined, so the actual files to be
processed are `wiki/page/*.gmi`; if you're using virtual hosting, the
subdirectory might be your host name; if you're using spaces, those need to be
appended as well.

Example:

    phoebe-ctl html-export --wiki_dir=/home/alex/phoebe \
      --source=transjovian.org \
      --source=transjovian.org/phoebe \
      --source=transjovian.org/gemini \
      --source=transjovian.org/titan \
      --target=/home/alex/transjovian.org

This will create HTML files in `/home/alex/transjovian.org`,
`/home/alex/transjovian.org/phoebe`, `/home/alex/transjovian.org/gemini`, and
`/home/alex/transjovian.org/titan`.

Note that the _links_ in these HTML files do not include the `.html` extension
(e.g. `/test`), so this relies on your web server doing the right thing: if a
visitor requests `/test` the web server must serve `/test.html`. If that
doesn't work, perhaps using `--no-extension` is your best bet: the HTML files
will be written without the `.html` extension. This should also work for local
browsing, although it does look strange, all those pages with the `.html`
extension.

# spartan

**spartan** \[**--help**\] \[**--verbose**\] _URL_

This is a very simple test client. All it does is print the response. The header
is printed to standard error so the rest can be redirected to get just the
content.

    spartan URL

Usage:

    spartan spartan://mozz.us/

Send some text:

    echo "Hello $USER!" | script/spartan spartan://mozz.us/echo

# titan

**titan** \[**--help**\] \[**--token=**_TOKEN_\] \[**--mime=**_MIMETYPE_\]
\[**--cert\_file=**_FILE_ **--key\_file=**_FILE_\] _URL_ \[_FILES_ ...\]

This is a script to upload content to a Titan-enabled site like Phoebe.

**--url=URL** specifies the Titan URL to use; this should be really similar to
the Gemini URL you used to read the page.

**--token=TOKEN** specifies the token to use; this is optional but spammers and
vandals basically ensured that any site out on the Internet needs some sort of
protection; how to get a token depends on the site you're editing.

**--mime=MIMETYPE** specifies the MIME type to send to the server. If you don't
specify a MIME type, the `file` utility is used to determine the MIME type of
the file you're uploading.

**FILES...** are the files to upload, if any; this is optional: you can also use
a pipe, or type a few words by hand (terminating it with a Ctrl-D, the end of
transmission byte).

Note that if you specify multiple files, the URL must end in a slash and all the
filenames are used as page names. So, uploading `Alex.gmi` and `Berta.gmi` to
`titan://localhost/` will create `gemini://localhost/Alex` and
`gemini://localhost/Berta`.

The following two options control the use of client certificates:

**--cert\_file=FILE** specifies an optional client certificate to use; if you
don't specify one, the default is to try to use `client-cert.pem` in the
current directory.

**--key\_file=FILE** specifies an optional client certificate key to use; if you
don't specify one, the default is to try to use `client-key.pem` in the current
directory.

Usage:

    echo "This is my test." > test.txt
    titan --url=titan://transjovian.org/test/raw/testing --token=hello text.txt

Or from a pipe:

    echo "This is my test." \
      | titan --url=titan://transjovian.org/test/raw/testing --token=hello

# App::Phoebe

This module contains the core of the Phoebe wiki. Import functions and variables
from this module to write extensions, or to run it some other way. Usually,
`script/phoebe` is used to start a Phoebe server. This is why all the
documentation regarding server startup can be found there.

This section describes some hooks you can use to customize your wiki using the
`config` file, or using a Perl file (ending in `*.pl` or `*.pm`) in the
`conf.d` directory. Once you're happy with the changes you've made, restart the
server, or send a SIGHUP if you know the PID.

Here are the ways you can hook into Phoebe code:

`@extensions` is a list of code references allowing you to handle additional
URLs; return 1 if you handle a URL; each code reference gets called with $stream
([Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AStream)), the first line of the request (a Gemini URL, a Gopher
selector, a finger user, a HTTP request line), a hash reference for the headers
(in the case of HTTP requests), and a buffer of bytes (e.g. for Titan or HTTP
PUT or POST requests).

`@main_menu` adds more lines to the main menu, possibly links that aren't
simply links to existing pages.

`@footer` is a list of code references allowing you to add things like licenses
or contact information to every page; each code reference gets called with
$stream ([Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AStream)), $host, $space, $id, $revision, and $format
('gemini' or 'html') used to serve the page; return a gemtext string to append
at the end; the alternative is to overwrite the `footer` or `html_footer` subs
– the default implementation for Gemini adds History, Raw text and HTML link,
and `@footer` to the bottom of every page; the default implementation for HTTP
just adds `@footer` to the bottom of every page.

If you do hook into Phoebe's code, you probably want to make use of the
following variables:

`$server` stores the command line options provided by the user.

`$log` is how you log things.

A very simple example to add a contact mail at the bottom of every page; this
works for both Gemini and the web:

    # tested by t/example-footer.t
    use App::Phoebe::Web;
    use App::Phoebe qw(@footer);
    push(@footer, sub { '=> mailto:alex@alexschroeder.ch Mail' });

This prints a very simply footer instead of the usual footer for Gemini, as the
`footer` function is redefined. At the same time, the `@footer` array is still
used for the web:

    # tested by t/example-footer2.t
    package App::Phoebe;
    use App::Phoebe::Web;
    use Modern::Perl;
    our (@footer); # HTML only
    push(@footer, sub { '=> https://alexschroeder.ch/wiki/Contact Contact' });
    # footer sub is Gemini only
    no warnings qw(redefine);
    sub footer {
      return "\n" . '—' x 10 . "\n" . '=> mailto:alex@alexschroeder.ch Mail';
    }

This example shows you how to add a new route (a new path served by the wiki).
Instead of just writing "Test" to the page, you could of course run arbitrary
Perl code.

    # tested by t/example-route.t
    our @config = (<<'EOT');
    use App::Phoebe qw(@extensions @main_menu port host_regex success);
    use Modern::Perl;
    push(@main_menu, "=> /do/test Test");
    push(@extensions, \&serve_test);
    sub serve_test {
      my $stream = shift;
      my $url = shift;
      my $hosts = host_regex();
      my $port = port($stream);
      if ($url =~ m!^gemini://($hosts):$port/do/test$!) {
        success($stream, 'text/plain; charset=UTF-8');
        $stream->write("Test\n");
        return 1;
      }
      return;
    }
    EOT

This example also shows how to redefine existing code in your config file
without the warning "Subroutine … redefined".

Here's a more elaborate example to add a new action the main menu and a handler
for it, for Gemini only:

    # tested by t/example-new-action.t
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
        result($stream, "20", "text/plain");
        $stream->write("Test\n");
        return 1;
      }
      return;
    }
    1;

# App::Phoebe::BlockFediverse

This extension blocks the Fediverse user agent from your website (Mastodon,
Friendica, Pleroma). The reason is this: when these sites federate a status
linking to your site, each instance will fetch a preview, so your site will get
hit by hundreds of requests from all over the Internet. Blocking them helps us
weather the storm.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::BlockFediverse;

Sure, we could also think of better caching and all that. I hate the fact that
other developers are forcing us to build “software that scales” – I hate how
they think that I have nothing better to do than think about blocking and
caching. Phoebe is software for the Smolnet, not for people that keep thinking
about scaling.

The solution implemented is this: if the user agent of a HTTP request matches
the regular expression, quit immediatly. The result:

    $ curl --header "User-Agent: Pleroma" https://transjovian.org:1965/
    Blocking Fediverse previews

Yeah, we could respond with a error, but fediverse developers aren’t interested
in a new architecture for this problem. They think the issue has been solved.
See [#4486](https://github.com/tootsuite/mastodon/issues/4486), “Mastodon can be
used as a DDOS tool.”

# App::Phoebe::Chat

For every wiki space, this creates a Gemini-based chat room. Every chat client
needs two URLs, the "listen" and the "say" URL.

The _Listen URL_ is where you need to _stream_: as people say things in the
room, these messages get streamed in one endless Gemini document. You might have
to set an appropriate timeout period for your connection for this to work. 1h,
perhaps?

The URL will look something like this:
`gemini://localhost/do/chat/listen` or
`gemini://localhost/space/do/chat/listen`

The _Say URL_ is where you post things you want to say: point your client at
the URL, it prompts your for something to say, and once you do, it redirects you
to the same URL again, so you can keep saying things.

The URL will look something like this: `gemini://localhost/do/chat/say` or
`gemini://localhost/space/do/chat/say`

Your chat nickname is the client certificate's common name. One way to create a
client certificate that's valid for five years with an appropriate common name:

    openssl req -new -x509 -newkey ec \
    -pkeyopt ec_paramgen_curve:prime256v1 \
    -subj '/CN=Alex' \
    -days 1825 -nodes -out cert.pem -keyout key.pem

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::Chat;

As a user, first connect using a client that can stream:

    gemini --cert_file=cert.pem --key_file=key.pem \
      gemini://localhost/do/chat/listen

Then connect with a client that let's you post what you type:

    gemini-chat --cert_file=cert.pem --key_file=key.pem \
      "gemini://localhost/do/chat/say"

# App::Phoebe::Comments

Add a comment link to footers such that visitors can comment via Gemini.
Commenting requires the access token.

Comments are appended to a "comments page". For every page _Foo_ the comments
are found on _Comments on Foo_. This prefix is fixed, currently.

On the comments page, each new comment starts with the character LEFT SPEECH
BUBBLE (🗨). This character is fixed, currently.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::Comments;

# App::Phoebe::Css

By default, Phoebe comes with its own, minimalistic CSS when serving HTML
rendition of pages: they all refer to `/default.css` and when this URL is
requested, Phoebe serves a small CSS.

With this extension, Phoebe serves an actual `default.css` in the wiki
directory.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::Css;

Then create `default.css` and make it look good. 😁

The cache control settings make sure that unless explicitly requested by a user
via a reload button, the CSS file is only fetched once per day. That also means
that if you change the CSS file, many users might only see a change after 24h.
That’s the trade-off…

# App::Phoebe::DebugIpNumbers

By default the IP numbers of your visitors are not logged. This small extensions
allows you to log them anyway if you're trying to figure out whether a bot is
going crazy.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::DebugIpNumbers;

Phoebe tries not to collect visitor data. Logging visitor IP numbers goes
against this. If your aim is detect and block crazy bots by having `fail2ban`
watch the log files, consider using [App::Phoebe::SpeedBump](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ASpeedBump) instead.

# App::Phoebe::Favicon

This adds an ominous looking Jupiter planet SVG icon as the favicon for the web
view of your site.

There is no configuration. Simply add it to your `config` file:

    App::Phoebe::Favicon

It would be nice if this code were to look for a `favicon.jpg` or
`favicon.svg` in the data directory and served that, only falling back to the
Jupiter planet SVG if no such file can be found. We could cache the content of
the file in the `$server` hash reference… Well, if somebody writes it, it shall
be merged. 😃

# App::Phoebe::Galleries

This extension only makes sense if you have image galleries created by
`fgallery` or [App::sitelenmute](https://metacpan.org/pod/App%3A%3Asitelenmute).

If you do, you can serve them via Gemini. You have to configure two things: in
which directory the galleries are, and under what host they are served (the code
assumes that when you are virtual hosting multiple domains, only one of them has
the galleries).

`$galleries_dir` is the directory where the galleries are. This assumes that
your galleries are all in one directory. For example, under
`/home/alex/alexschroeder.ch/gallery` you’d find `2016-altstetten` and many
others like it. Under `2016-altstetten` you’d find the `data.json` and
`index.html` files (both of which get parsed), and the various subdirectories.

In your `config` file:

    package App::Phoebe::Galleries;
    our $galleries_dir = "/home/alex/alexschroeder.ch/gallery";
    our $galleries_host = "alexschroeder.ch";
    use App::Phoebe::Galleries;

# App::Phoebe::Gopher

This extension serves your Gemini pages via Gopher and generates a few automatic
pages for you, such as the main page.

To configure, you need to specify the Gopher port(s) in your Phoebe `config` file.
The default port is 70. This is a priviledge port. Thus, you either need to
grant Perl the permission to listen on a priviledged port, or you need to run
Phoebe as a super user. Both are potential security risk, but the first option
is much less of a problem, I think.

If you want to try this, run the following as root:

    setcap 'cap_net_bind_service=+ep' $(which perl)

Verify it:

    getcap $(which perl)

If you want to undo this:

    setcap -r $(which perl)

The alternative is to use a port number above 1024.

If you don't do any of the above, you'll get a permission error on startup:
"Mojo::Reactor::Poll: Timer failed: Can't create listen socket: Permission
denied…"

If you are virtual hosting note that the Gopher protocol is incapable of doing
that: the server does not know what hostname the client used to look up the IP
number it eventually contacted. This works for HTTP and Gemini because HTTP/1.0
and later added a Host header to pass this information along, and because Gemini
uses a URL including a hostname in its request. It does not work for Gopher.
This is why you need to specify the hostname via `$gopher_host`.

You can set the normal Gopher via `$gopher_port` and the encrypted Gopher ports
via `$gophers_port` (note the extra s). The values either be a single port, or
an array of ports. See the example below.

In this example we first switch to the package namespace, set some variables,
and then we _use_ the package. At this point the ports are specified and the
server processes it starts go up, one for ever IP number serving the hostname.

    package App::Phoebe::Gopher;
    our $gopher_host = "alexschroeder.ch";
    our $gopher_port = [70,79]; # listen on the finger port as well
    our $gophers_port = 7443; # listen on port 7443 using TLS
    our $gopher_main_page = "Gopher_Welcome";
    use App::Phoebe::Gopher;

Note the `finger` port in the example. This works, but it's awkward since you
have to finger `page/alex` instead of `alex`. In order to make that work, we
need some more code.

    package App::Phoebe::Gopher;
    use App::Phoebe qw(@extensions port $log);
    use Modern::Perl;
    our $gopher_host = "alexschroeder.ch";
    our $gopher_port = [70,79]; # listen on the finger port as well
    our $gophers_port = 7443; # listen on port 7443 using TLS
    our $gopher_main_page = "Gopher_Welcome";
    our @extensions;
    push(@extensions, \&finger);
    sub finger {
      my $stream = shift;
      my $selector = shift;
      my $port = port($stream);
      if ($port == 79 and $selector =~ m!^[^/]+$!) {
        $log->debug("Serving $selector via finger");
        gopher_serve_page($stream, $gopher_host, undef, decode_utf8(uri_unescape($selector)));
        return 1;
      }
      return 0;
    }
    use App::Phoebe::Gopher;

# App::Phoebe::HeapDump

Perhaps you find yourself in a desperate situation: your server is leaking
memory and you don't know where. This extension provides a way to use
[Devel::MAT::Dumper](https://metacpan.org/pod/Devel%3A%3AMAT%3A%3ADumper) by allowing users identified with a known fingerprint of
their client certificate to initiate a dump.

You must set the fingerprints in your `config` file.

    package App::Phoebe;
    our @known_fingerprints = qw(
      sha256$fce75346ccbcf0da647e887271c3d3666ef8c7b181f2a3b22e976ddc8fa38401);
    use App::Phoebe::HeapDump;

Once have restarted the server, [gemini://localhost/do/heap-dump](gemini://localhost/do/heap-dump) will write a
heap dump to its wiki data directory. See [Devel::MAT::UserGuide](https://metacpan.org/pod/Devel%3A%3AMAT%3A%3AUserGuide) for more.

# App::Phoebe::Iapetus

This allows known editors to upload files and pages using the Iapetus protocol.
See [Iapetus documentation](https://codeberg.org/oppenlab/iapetus).

In order to be a known editor, you need to set `@known_fingerprints` in your
`config` file. Here’s an example:

    package App::Phoebe;
    our @known_fingerprints;
    @known_fingerprints = qw(
      sha256$fce75346ccbcf0da647e887271c3d3666ef8c7b181f2a3b22e976ddc8fa38401
      sha256$54c0b95dd56aebac1432a3665107d3aec0d4e28fef905020ed6762db49e84ee1);
    use App::Phoebe::Iapetus;

The way to do it is to run the following, assuming the certificate is named
`client-cert.pem`:

    openssl x509 -in client-cert.pem -noout -sha256 -fingerprint \
    | sed -e 's/://g' -e 's/SHA256 Fingerprint=/sha256$/' \
    | tr [:upper:] [:lower:]

This should give you the fingerprint in the correct format to add to the list
above.

Make sure your main menu has a link to the login page. The login page allows
people to pick the right certificate without interrupting their uploads.

    => /login Login

# App::Phoebe::Ijirait

The ijirait are red-eyed shape shifters, and a game one plays via the Gemini
protocol, and Ijiraq is also one of the moons of Saturn.

The Ijirait game is modelled along traditional MUSH games ("multi-user shared
hallucination"), that is: players have a character in the game world; the game
world consists of rooms; these rooms are connected to each other; if two
characters are in the same room, they see each other; if one of them says
something, the other hears it.

When you visit the URL using your Gemini browser, you're asked for a client
certificate. The common name of the certificate is the name of your character in
the game.

As the server doesn't know whether you're still active or not, it assumes a
10min timout. If you were active in the last 10min, other people in the same
"room". Similarly, if you "say" something, whatever you said hangs on the room
description for up to 10min as long as your character is still in the room.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::Ijirait;

In a virtual host setup, this extension serves all the hosts. Here's how to
serve just one of them:

    package App::Phoebe::Ijirait;
    our $host = "campaignwiki.org";
    use App::Phoebe::Ijirait;

The help file, if you have one, is `ijirait-help.gmi` in your wiki data
directory. Feel free to get a copy of
[gemini://transjovian.org/ijiraq/page/Help](gemini://transjovian.org/ijiraq/page/Help).

# App::Phoebe::MokuPona

This serves files from your moku pona directory. See [App::mokupona](https://metacpan.org/pod/App%3A%3Amokupona).

If you need to change the directory (defaults to `$HOME/.moku-pona`), or if you
need to change the host (defaults to the first one), use the following for your
`config` file:

    package App::Phoebe::MokuPona;
    our $dir = "/home/alex/.moku-pona";
    our $host = "alexschroeder.ch";
    use App::Phoebe::MokuPona;

# App::Phoebe::Oddmuse

This extension allows you to serve files from an Oddmuse wiki instead of a real
Phoebe wiki directory.

The tricky part is that most Oddmuse wikis don't use Gemini markup (“gemtext”)
and therefore care is required. The extension tries to transmogrify typical
Oddmuse markup (based on my own wikis) to Gemini.

Here's one way to configure it. I use Apache as my proxy server and have
multiple Oddmuse wikis running on the same machine, each only serving
`localhost`. I need to recreate some of the Apache configuration, here.

    package App::Phoebe::Oddmuse;

    our %oddmuse_wikis = (
      "alexschroeder.ch" => "http://localhost:4023/wiki",
      "communitywiki.org" => "http://localhost:4019/wiki",
      "emacswiki.org" => "http://localhost:4002/wiki",
      "campaignwiki.org" => "http://localhost:4004/wiki", );

    our %oddmuse_wiki_names = (
      "alexschroeder.ch" => "Alex Schroeder",
      "communitywiki.org" => "Community Wiki",
      "emacswiki.org" => "Emacs Wiki",
      "campaignwiki.org" => "Campaign Wiki", );

    our %oddmuse_wiki_dirs = (
      "alexschroeder.ch" => "/home/alex/alexschroeder",
      "communitywiki.org" => "/home/alex/communitywiki",
      "emacswiki.org" => "/home/alex/emacswiki",
      "campaignwiki.org" => "/home/alex/campaignwiki", );

    our %oddmuse_wiki_links = (
      "communitywiki.org" => 1,
      "campaignwiki.org" => 1, );

    use App::Phoebe::Oddmuse;

# App::Phoebe::PageHeadings

This extension hides the page name from visitors, unless they start digging.

One the front page, where the last ten pages of your date pages are listed, the
name of the page is replaced with the level one heading of your page.

If you visit a page, the name of the page is similarly replaced with the level
one heading of your page.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::PageHeadings;

Beware the consequences:

Every time somebody visits the main page, the main page itself is read, and the
ten blog pages are also read, in order to look for the headings to use; in some
high traffic situations, this could be problematic.

Every page needs to have a top level heading: the file name is no longer shown
to users.

Opening pages and looking for a top level heading doesn’t do regular parsing,
thus if your first top level heading is actually inside code fences (“\`\`\`”) it
still gets used.

Beware the limitations:

The code doesn’t do the same for requests over the web.

# App::Phoebe::RegisteredEditorsOnly

This extension limits editing to registered editors only. In order to register
an editor, you need to know the client certificate's fingerprint, and add it to
the Phoebe wiki `config` file. Do this by setting `@known_fingerprints`.
Here’s an example:

    package App::Phoebe;
    our @known_fingerprints = qw(
      sha256$fce75346ccbcf0da647e887271c3d3666ef8c7b181f2a3b22e976ddc8fa38401
      sha256$54c0b95dd56aebac1432a3665107d3aec0d4e28fef905020ed6762db49e84ee1);
    use App::Phoebe::RegisteredEditorsOnly;
    our $server->{wiki_token} = []; # no tokens
    1;

If you have your editor’s client certificate (not their key!), run the
following to get the fingerprint:

    openssl x509 -in client-cert.pem -noout -sha256 -fingerprint \
    | sed -e 's/://g' -e 's/SHA256 Fingerprint=/sha256$/' \
    | tr [:upper:] [:lower:]

This should give you the fingerprint in the correct format to add to the list
above. Add it, and restart Phoebe.

If a visitor uses a fingerprint that Phoebe doesn’t know, the fingerprint is
printed in the log (if your log level is set to “info” or more), so you can get
it from there in case the user can’t send you their client certificate, or tell
you what the fingerprint is.

You should also have a login link somewhere such that people can login
immediately. If they don’t, and they try to save, their client is going to ask
them for a certificate and their edits may or may not be lost. It depends. 😅

    => /login Login

This code works by intercepting all `titan:` links, and all web edit requests.
If you allow editing via the web using [App::Phoebe::WebEdit](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebEdit), then those also
require a valid client certificate – and setting these up in a web browser are
not easy. Be prepared to explain how to do this to your users!

This code does _not_ prevent simple comments using [App::Phoebe::Comments](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AComments) or
[App::Phoebe::WebComments](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebComments). People can still leave comments, if you use these
modules. This can be a problem: if only registered users can edit the site, you
probably don’t want a token; if anonymous users can comment, you probably want a
token. There is currently no solution for this. Choose one or the other. If you
choose both, registered users might have to provide a token, which might annoy
them.

Here’s an example config that allows reading and editing via the web, but only
for users with known fingerprints, with no comments and no tokens:

    # tested by t/example-registered-editors-only.t
    package App::Phoebe;
    use App::Phoebe::Web;
    use App::Phoebe::WebEdit;
    use App::Phoebe::RegisteredEditorsOnly;
    our @known_fingerprints = qw(
      sha256$0ba6ba61da1385890f611439590f2f0758760708d1375859b2184dcd8f855a00);
    our $server->{wiki_token} = []; # no tokens
    1;

At the time of this writing, here’s a way to do provide a client certificate for
Firefox users. First, we need a file in the `PKCS12` format. On the command
line, create this file from the `cert.pem` and `key.pem` files you have.
Provide no password when you run the command.

    openssl pkcs12 -export -inkey key.pem -in cert.pem -out cert.p12

In Firefox, go to Preferences → Privacy & Security → Certificates, click on the
View Certificates button, switch the Your Certificates tab, click on Import… and
pick the `cert.p12` file you just created.

Once you have done this and you visit the site, it’ll ask you what client
certificate to use. Sadly, at this point Firefox will ask you for a certificate
whenever you visit a Phoebe wiki, even if you don’t intend to identify yourself
because Phoebe always tries to read the client’s client certificate. You can
always cancel, but there’s that uncomfortable moment when you visit a new Phoebe
wiki…

# App::Phoebe::Spartan

This extension serves your Gemini pages via the Spartan protocol and generates a
few automatic pages for you, such as the main page.

**Warning!** If you install this code, anybody can write to your site using the
Spartan protocol. There is no token being checked.

To configure, you need to specify the Spartan port(s) in your Phoebe config
file. The default port is 300. This is a priviledge port. Thus, you either need
to grant Perl the permission to listen on a priviledged port, or you need to run
Phoebe as a super user. Both are potential security risk, but the first option
is much less of a problem, I think.

If you want to try this, run the following as root:

    setcap 'cap_net_bind_service=+ep' $(which perl)

Verify it:

    getcap $(which perl)

If you want to undo this:

    setcap -r $(which perl)

Once you do that, no further configuration is necessary. Just add the following
to your `config` file:

    use App::Phoebe::Spartan;

The alternative is to use a port number above 1024. Here's a way to do that:

    package App::Phoebe::Spartan;
    our $spartan_port = 7000; # listen on port 7000
    use App::Phoebe::Spartan;

If you don't do any of the above, you'll get a permission error on startup:
"Mojo::Reactor::Poll: Timer failed: Can't create listen socket: Permission
denied…"

# App::Phoebe::SpeedBump

We want to block crawlers that are too fast or that don’t follow the
instructions in robots.txt. We do this by keeping a list of recent visitors: for
every IP number, we remember the timestamps of their last visits. If they make
more than 30 requests in 60s, we block them for an ever increasing amount of
seconds, starting with 60s and doubling every time this happens.

For every IP number, Phoebe also records whether the last 30 requests were
“suspicious” or not. A suspicious request is a request that is “disallowed” for
bots according to “robots.txt” (more or less). If 10 requests or more of the
last 30 requests in the last 60 seconds are suspicious, the IP number is
blocked.

When an IP number is blocked, it is blocked for 60s, and there’s a 120s
probation time. When you’re blocked, Phoebe responds with a “44” response. This
means: slow down!

If the IP number is unblocked but gives cause for another block in the probation
time, it is blocked again and the blocking time is doubled: the IP is blocked
for 120s and there’s 240s probation time. And if it happens again, it is doubled
again.

There is no configuration required, but adding a known fingerprint is suggested.
The `/do/speed-bump` URL shows you more information, if you have a client
certificate with a known fingerprint.

The exact number of requests and the length of the time window (in seconds) can
be changed in the `config` file, too.

    Here’s one way to do all that:

       package App::Phoebe;
       our @known_fingerprints = qw(
         sha256$0ba6ba61da1385890f611439590f2f0758760708d1375859b2184dcd8f855a00);
       package App::Phoebe::SpeedBump;
       our $speed_bump_requests = 20;
       our $speed_bump_window = 20;
       use App::Phoebe::SpeedBump;

Here’s how to get the fingerprint from a certificate named `client-cert.pem`:

    openssl x509 -in client-cert.pem -noout -sha256 -fingerprint \
    | sed -e 's/://g' -e 's/SHA256 Fingerprint=/sha256$/' \
    | tr [:upper:] [:lower:]

This should give you the fingerprint in the correct format to add to the list
above.

# App::Phoebe::StaticFiles

Serving static files... Sometimes it's just easier. All the static files are
served from `/do/static`, without regard to wiki spaces. You need to define
routes that map a path to your filesystem.

    package App::Phoebe::StaticFiles;
    our %routes = (
      "zürich" => "/home/alex/Pictures/2020/Zürich",
      "amaryllis" => "/home/alex/Pictures/2021/Amaryllis", );
    use App::Phoebe::StaticFiles;

The setup does not allow recursive traversal of the file system.

You still need to add a link to `/do/static` somewhere in your wiki.

# App::Phoebe::TokiPona

This extension adds rendering of Toki Pona glyphs to the web output of your
site. For this to work, you need to download the WOFF file from the Linja Pona
4.2 repository and put it into your wiki directory.

[https://github.com/janSame/linja-pona/](https://github.com/janSame/linja-pona/)

No further configuration is necessary. Simply add it to your `config` file:

    use App::Phoebe::TokiPona;

# App::Phoebe::Web

Phoebe doesn’t have to live behind another web server like Apache or nginx. It
can be a (simple) web server, too!

This package gives web visitors read-only access to Phoebe. HTML is served via
HTTP on the same port as everything else, i.e. 1965 by default.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::Web;

Beware: these days browser will refuse to connect to sites that have self-signed
certificates. You’ll have to click buttons and make exceptions and all of that,
or get your certificate from Let’s Encrypt or the like. That in turn is
aggravating for your Gemini visitors, since you are changing the certificate
every few months.

If you want to allow web visitors to comment on your pages, see
[App::Phoebe::WebComments](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebComments); if you want to allow web visitors to edit pages,
see [App::Phoebe::WebEdit](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebEdit).

You can serve the wiki both on the standard Gemini port and on the standard
HTTPS port:

    phoebe --port=443 --port=1965

Note that 443 is a priviledge port. Thus, you either need to grant Perl the
permission to listen on a priviledged port, or you need to run Phoebe as a super
user. Both are potential security risk, but the first option is much less of a
problem, I think.

If you want to try this, run the following as root:

    setcap 'cap_net_bind_service=+ep' $(which perl)

Verify it:

    getcap $(which perl)

If you want to undo this:

    setcap -r $(which perl)

If you don't do any of the above, you'll get a permission error on startup:
"Mojo::Reactor::Poll: Timer failed: Can't create listen socket: Permission
denied…" You could, of course, always use a traditional web server like Apache
as a front-end, proxying all requests to your site on port 443 to port 1965.
This server config also needs access to the same certificates that Phoebe is
using, for port 443. The example below doesn’t rewrite `/.well-known` URLs
because these are used by Let’s Encrypt and others.

    <VirtualHost *:80>
        ServerName transjovian.org
        RewriteEngine on
        # Do not redirect /.well-known URL
        RewriteCond %{REQUEST_URI} !^/\.well-known/
        RewriteRule ^/(.*) https://%{HTTP_HOST}:1965/$1
    </VirtualHost>
    <VirtualHost *:443>
        ServerName transjovian.org
        RewriteEngine on
        # Do not redirect /.well-known URL
        RewriteCond %{REQUEST_URI} !^/\.well-known/
        RewriteRule ^/(.*) https://%{HTTP_HOST}:1965/$1
        SSLEngine on
        SSLCertificateFile      /var/lib/dehydrated/certs/transjovian.org/cert.pem
        SSLCertificateKeyFile   /var/lib/dehydrated/certs/transjovian.org/privkey.pem
        SSLCertificateChainFile /var/lib/dehydrated/certs/transjovian.org/chain.pem
        SSLVerifyClient None
    </VirtualHost>

Here’s an example where we wrap one the subroutines in App::Phoebe::Web in order
to change the default CSS that gets served. We keep a code reference to the
original, substitute our own, and when it gets called, it first calls the old
code to print some CSS, and then we append some CSS of our own. Also note how we
import `$log`.

    # tested by t/example-dark-mode.t
    package App::Phoebe::DarkMode;
    use App::Phoebe qw($log);
    use App::Phoebe::Web;
    no warnings qw(redefine);

    # fully qualified because we're in a different package!
    *old_serve_css_via_http = \&App::Phoebe::Web::serve_css_via_http;
    *App::Phoebe::Web::serve_css_via_http = \&serve_css_via_http;

    sub serve_css_via_http {
      my $stream = shift;
      old_serve_css_via_http($stream);
      $log->info("Adding more CSS via HTTP (for dark mode)");
      $stream->write(<<'EOT');
    @media (prefers-color-scheme: dark) {
       body { color: #eeeee8; background-color: #333333; }
       a:link { color: #1e90ff }
       a:hover { color: #63b8ff }
       a:visited { color: #7a67ee }
    }
    EOT
    }

    1;

# App::Phoebe::WebComments

This extension allows visitors on the web to add comments.

Comments are appended to a "comments page". For every page _Foo_ the comments
are found on _Comments on Foo_. This prefix is fixed, currently.

On the comments page, each new comment starts with the character LEFT SPEECH
BUBBLE (🗨). This character is fixed, currently.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::WebComments;

# App::Phoebe::WebEdit

This package allows visitors on the web to edit your pages.

There is no configuration. Simply add it to your `config` file:

    use App::Phoebe::WebEdit;

# App::Phoebe::Wikipedia

This extension turns one of your hosts into a Wikipedia proxy.

In your `config` file, you need to specify which of your hosts it is:

    package App::Phoebe::Wikipedia;
    our $host = "vault.transjovian.org";
    use App::Phoebe::Wikipedia;

You can also use [App::Phoebe::Web](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWeb) in which case web requests will get
redirected to the actual Wikipedia.
