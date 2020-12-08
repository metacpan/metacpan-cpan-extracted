# Lupa Pona

Lupa Pona serves the local directory as a Gemini site.

It's a super simple server: it just serves the current directory. I use
[Phoebe](https://alexschroeder.ch/cgit/phoebe/about/) myself, for Gemini
hosting. It's a wiki, not just a file server.

Let me know if you want to use Lupa Pona in a multi-user or virtual-hosting
setup. All the necessary bits can be lifted from elsewhere. Right now, I'm just
using Lupa Pona to temporarily serve a local directory, as one might
occasionally use a few lines of Python to serve the local directory over the web
using `SimpleHTTPServer`.

**Table of Contents**

- [Limitations](#limitations)
- [Dependencies](#dependencies)
- [Quickstart](#quickstart)
- [Troubleshooting](#troubleshooting)
- [Options](#options)
- [Using systemd](#using-systemd)
- [Privacy](#privacy)

## Limitations

Currently, all files are served as `text/gemini; charset=UTF-8`.

## Dependencies

Perl libraries you need to install if you want to run Lupa Pona:

- [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) and [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop), or `libmojolicious-perl`
- [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL), or `libio-socket-ssl-perl`
- [File::Slurper](https://metacpan.org/pod/File%3A%3ASlurper), or `libfile-slurper-perl`
- [Modern::Perl](https://metacpan.org/pod/Modern%3A%3APerl), or `libmodern-perl-perl`
- [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape), or `liburi-escape-xs-perl`

## Quickstart

Since Lupa Pona traffic is encrypted, we need to generate a certificate and a
key. When you start it for the first time, it will ask you for a hostname. Use
'localhost' if you don't know. You can also generate your own certificate, like
this, replacing `$hostname` with whatever you need:

    openssl req -new -x509 -newkey ec -subj "/CN=$hostname" \
    -pkeyopt ec_paramgen_curve:prime256v1 \
    -days 1825 -nodes -out cert.pem -keyout key.pem

This creates a certificate and a private key, both of them unencrypted, using
eliptic curves of a particular kind, valid for five years.

Start the server:

    lupa-pona

This starts the server in the foreground, for `gemini://localhost:1965`. If it
aborts, see the ["Troubleshooting"](#troubleshooting) section below. If it runs, open your
favourite Gemini client and test it, or open another terminal and test it:

    echo gemini://localhost \
      | openssl s_client --quiet --connect localhost:1965 2>/dev/null

You should see a Gemini page starting with the following:

    20 text/gemini; charset=UTF-8
    Welcome to Lupa Pona!

Success!! 😀 🚀🚀

## Troubleshooting

No trouble, yet!

## Options

These are the options Lupa Pona knows about:

- `--host` is the address to use; the default is 0.0.0.0, i.e. accepting
all connections (use this option if your machine is reachable via multiple
names, e.g. `alexschroeder.ch` and `emacswiki.org` and you just want want to
serve one of them)
- `--port` is the port to use; the default is 1965
- `--log_level` is the log level to use (error, warn, info, debug, trace);
the default is `warn`
- `--cert_file` is the certificate file to use; the default is `cert.pem`
- `--key_file` is the key file to use; the default is `key.pem`

## Using systemd

Systemd is going to handle daemonisation for us. There's more documentation
[available
online](https://www.freedesktop.org/software/systemd/man/systemd.service.html).

You could create a specific user:

    sudo adduser --disabled-login --disabled-password lupa-pona

Copy Lupa Pona to `/home/lupa-pona/lupa-pona`.

Basically, this is the template for our service:

    [Unit]
    Description=Lupa Pona
    After=network.target
    [Service]
    Type=simple
    WorkingDirectory=/home/lupa-pona
    ExecStart=/home/lupa-pona/lupa-pona
    Restart=always
    User=lupa-pona
    Group=lupa-pona
    [Install]
    WantedBy=multi-user.target

Save this as `lupa-pona.service`, and then link it:

    sudo ln -s /home/lupa-pona/lupa-pona.service /etc/systemd/system/

Reload systemd:

    sudo systemctl daemon-reload

Start Lupa Pona:

    sudo systemctl start lupa-pona

Check the log output:

    sudo journalctl --unit lupa-pona

All the files in `/home/lupa-pona` are going to be served, if the `lupa-pona`
user can read them.

## Privacy

If you increase the log level, the server will produce more output, including
information about the connections happening, like `2020/06/29-15:35:59 CONNECT
SSL Peer: "[::1]:52730" Local: "[::1]:1965"` and the like (in this case `::1`
is my local address so that isn't too useful but it could also be your visitor's
IP numbers, in which case you will need to tell them about it using in order to
comply with the
[GDPR](https://en.wikipedia.org/wiki/General_Data_Protection_Regulation).
