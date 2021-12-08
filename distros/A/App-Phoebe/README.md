# Phoebe Wiki

Phoebe does two and a half things:

It's a program that you run on a computer and other people connect to it using
their Gemini client in order to read the pages on it.

It's a wiki, which means that people can edit the pages without needing an
account. All they need is a client that speaks both Gemini and Titan, and the
password. The default password is "hello". 😃

Optionally, people can also access it using a regular web browser.

Gemini itself is very simple network protocol, like Gopher or Finger, but with
TLS. Gemtext is a very simple markup language, a bit like Markdown, but line
oriented.

To take a look for yourself, check out the test wiki via the web or via the web.

- [What is Gemini?](https://gemini.circumlunar.space/)
- [Gemini link collection](https://git.sr.ht/~kr1sp1n/awesome-gemini)
- [Test site, via the web](https://transjovian.org:1965/test)
- [Test site, via Gemini](gemini://transjovian.org/test)

## Reading the wiki

This repository comes with a Perl script called
[gemini](https://metacpan.org/pod/gemini) to download Gemini URLs.

Other clients can be found here:

- [Gemini software](https://gemini.circumlunar.space/software/)
- [Gemini clients](https://transjovian.org:1965/gemini/page/Clients)

See [App::Phoebe::Web](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWeb) to
enable reading via the web.

## Editing the wiki

How do you edit a Phoebe wiki? You need to use a Titan-enabled client.

[Titan](https://transjovian.org:1965/titan) is a companion protocol to Gemini:
it allows clients to upload files to Gemini sites, if servers allow this. On
Phoebe, you can edit "raw" pages. That is, at the bottom of a page you'll see a
link to the "raw" page. If you follow it, you'll see the page content as plain
text. You can submit a changed version of this text to the same URL using Titan.

Known clients:

This repository comes with a Perl script called
[titan](https://metacpan.org/pod/titan) to upload files.

[Gemini Write](https://alexschroeder.ch/cgit/gemini-write/) is an extension for
the Emacs Gopher and Gemini client [Elpher](https://thelambdalab.xyz/elpher/).

[Gemini & Titan for Bash](https://alexschroeder.ch/cgit/gemini-titan/about/) are
two shell functions that allow you to download and upload files.

[Lagrange](https://gmi.skyjake.fi/lagrange/) is a GUI client that is Titan
enabled.

See [App::Phoebe::WebEdit](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebEdit) to
enable editing via the web.

## Installation

Using `cpan`:

    cpan App::Phoebe

Manual install:

    perl Makefile.PL
    make
    make install

## Dependencies

If you are not using `cpan` or `cpanm` to install Phoebe, you'll need to install
the following dependencies:

- [Algorithm::Diff](https://metacpan.org/pod/Algorithm%3A%3ADiff), or `libalgorithm-diff-xs-perl`
- [File::ReadBackwards](https://metacpan.org/pod/File%3A%3AReadBackwards), or `libfile-readbackwards-perl`
- [File::Slurper](https://metacpan.org/pod/File%3A%3ASlurper), or `libfile-slurper-perl`
- [Mojolicious](https://metacpan.org/pod/Mojolicious), or `libmojolicious-perl`
- [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL), or `libio-socket-ssl-perl`
- [Modern::Perl](https://metacpan.org/pod/Modern%3A%3APerl), or `libmodern-perl-perl`
- [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape), or `liburi-escape-xs-perl`
- [Net::IDN::Encode](https://metacpan.org/pod/Net%3A%3AIDN%3A%3AEncode), or `libnet-idn-encode-perl`
- [Encode::Locale](https://metacpan.org/pod/Encode%3A%3ALocale), or `libencode-locale-perl`

I'm going to be using `curl` and `openssl` in the Quickstart section of
`phoebe`, so you'll need those tools as well. And finally, when people download
their data, the code calls `tar` (available from packages with the same name on
Debian derived systems).

## See also

* [phoebe](https://metacpan.org/pod/phoebe) - a Gemini-first wiki server

* [gemini](https://metacpan.org/pod/gemini) - a command line client for the Gemini protocol

* [gemini-chat](https://metacpan.org/pod/gemini-chat) - a command line client for the Gemini protocol to send lines you type

* [ijirait](https://metacpan.org/pod/ijirait) - a command line client for the Gemini protocol to play the Ijirait MUSH

* [phoebe-ctl](https://metacpan.org/pod/phoebe-ctl) - admin control for a Phoebe wiki

* [spartan](https://metacpan.org/pod/spartan) - a command line client for the Spartan protocol

* [titan](https://metacpan.org/pod/titan) - a command line client to upload texts and files using the Titan protocol

* [App::Phoebe](https://metacpan.org/pod/App%3A%3APhoebe) - a Gemini-based wiki

* [App::Phoebe::BlockFediverse](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ABlockFediverse) - block Fediverse instances from Phoebe wiki

* [App::Phoebe::Capsules](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ACapsules) - provide every visitor with a writeable capsule

* [App::Phoebe::Chat](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AChat) - add a Gemini-based chat room for every Phoebe wiki space

* [App::Phoebe::Comments](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AComments) - add comment pages to Phoebe wiki

* [App::Phoebe::Css](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ACss) - use a CSS file for Phoebe wiki served on the web

* [App::Phoebe::DebugIpNumbers](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ADebugIpNumbers) - log visitor IP numbers for Phoebe

* [App::Phoebe::Favicon](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AFavicon) - serve a favicon via the web for Phoebe

* [App::Phoebe::Galleries](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AGalleries) - serving sitelen mute image galleries via Gemini

* [App::Phoebe::Gopher](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AGopher) - serving a Phoebe wiki via the Gopher protocol

* [App::Phoebe::HeapDump](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AHeapDump) - debugging Phoebe memory leaks

* [App::Phoebe::Iapetus](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AIapetus) - uploads using the Iapetus protocol

* [App::Phoebe::Ijirait](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AIjirait) - a Gemini-based MUSH running on Phoebe

* [App::Phoebe::MokuPona](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AMokuPona) - serve files from moku pona

* [App::Phoebe::Oddmuse](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AOddmuse) - act as a Gemini proxy for an Oddmuse wiki

* [App::Phoebe::Oracle](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AOracle) - an anonymous question asking game

* [App::Phoebe::PageHeadings](https://metacpan.org/pod/App%3A%3APhoebe%3A%3APageHeadings) - use headings instead of file names

* [App::Phoebe::RegisteredEditorsOnly](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ARegisteredEditorsOnly) - only known users may edit Phoebe wiki pages

* [App::Phoebe::Spartan](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ASpartan) - implement the Spartan protocol for Phoebe

* [App::Phoebe::SpeedBump](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ASpeedBump) - defend Phoebe against bots and leeches

* [App::Phoebe::StaticFiles](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AStaticFiles) - serve static files via a Phoebe wiki

* [App::Phoebe::TokiPona](https://metacpan.org/pod/App%3A%3APhoebe%3A%3ATokiPona) - serve a linja pona via the web

* [App::Phoebe::Web](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWeb) - serve Phoebe wiki pages via the web

* [App::Phoebe::WebComments](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebComments) - allow comments on a Phoebe wiki via the web

* [App::Phoebe::WebDAV](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebDAV) - add WebDAV to Phoebe wiki

* [App::Phoebe::WebEdit](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebEdit) - allow edits of a Phoebe wiki via the web

* [App::Phoebe::WebStaticFiles](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWebStaticFiles) - serve static files via the web

* [App::Phoebe::Wikipedia](https://metacpan.org/pod/App%3A%3APhoebe%3A%3AWikipedia) - act as Wikipedia proxy from Phoebe
