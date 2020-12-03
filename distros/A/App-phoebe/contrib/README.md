# Contributions

These are config files for the `conf.d/` subdirectory of your wiki
directory.

## block-fediverse.pl

This is a small extension that blocks requests from fediverse servers
such as Mastodon in order to try and save Phoebe from being
overwhelmed when hundreds of requests start pouring in.

Example:

```
$ curl --user-agent Mastodon https://transjovian.org:1965/
curl: (52) Empty reply from server
```

## debug-ip-numbers.pl

By default the IP numbers of your visitors are not logged. This small
extensions allows you to log them anyway if you're trying to figure
out whether a bot is going crazy.

## favicon.pl

This small extensions adds a favicon to your website.

Example:

=> https://transjovian.org/favicon.ico

## galleries.pl

This extensions is only useful if you're hosting image galleries made
by fgallery or sitelen mute.

=> https://alexschroeder.ch/cgit/sitelen-mute/about/

Example:

=> gemini://alexschroeder.ch/do/gallery

## moku-pona.pl

This extension is only useful if you're hosting your Gopher, Gemini,
RSS or Atom subscriptions via moku pona.

=> https://alexschroeder.ch/cgit/moku-pona/about/

Example:

=> gemini://alexschroeder.ch/do/moku-pona/updates.txt

## oddmuse.pl

This extension is only useful if you're hosting web-based wikis using
Oddmuse and you want offer a way to access them via Gemini. The tricky
part is that most Oddmuse wikis don't use Gemini markup (“gemtext”)
and therefore care is required. The extension tries to transmogrify
typical Oddmuse markup (based on my own wikis) to Gemini.

=> https://alexschroeder.ch/cgit/oddmuse/about/

Example:

=> gemini://alexschroeder.ch/

## toki-pona.pl

This extension allows you to write blocks using toki pona and on the
web, the linja pona font is used to render them. In order for this to
work, you must have the linja-pona-4.2.woff file in your wiki data
directory.

=> https://github.com/janSame/linja-pona/#linja-pona

Example:

=> gemini://toki.transjovian.org/

## web-edit.pl

This extension allows visitors to edit your wiki via the web. Phoebe
is still a Gemini-first wiki, so some features are still not available
via the web.

Example:

=> gemini://transjovian.org/

## wikipedia.pl

This extension acts as a proxy for Wikipedia.

Example:

=> gemini://vault.transjovian.org/
