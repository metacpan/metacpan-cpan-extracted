# NAME

Traveller – a web application to generate sector and subsector maps
for the Traveller RPG

# SYNOPSIS

**traveller** daemon -m production -l http://*:8080

**traveller** routes -v

**traveller** get /uwp/subsector/mgt/123 | w3m -T text/html

# DESCRIPTION

This package contains a web application to generate sector and
subsector maps for the Traveller RPG. The rules are either based on
Classic Traveller (CT), Classic Traveller with the Merchant Prince
Trade System (MPTS), or Mongoose Traveller (1st edition).

To start it as a web server in production mode, listening for all
hostnames on port 8080:

```
traveller daemon -m production -l http://*:8080
```

To run it in development mode and reload it whenever you change a
file:

```
morbo $(which traveller)
```

# INSTALLATION

Using `cpan`:

```
cpan App::traveller
```

Manual install:

```
perl Makefile.PL
make
make install
```

## Dependencies

Perl libraries you need to install if you install it manually:

* [Mojolicious](https://metacpan.org/pod/Mojolicious) or `libmojolicious-perl`
* [Modern::Perl](https://metacpan.org/pod/Modern::Perl) or `libmodern-perl-perl`

## Deployment

If you want to know more, see
[Mojolicious::Guides::Tutorial](https://metacpan.org/pod/Mojolicious::Guides::Tutorial),
[Mojolicious::Guides::Cookbook](https://metacpan.org/pod/Mojolicious::Guides::Cookbook),
[Mojo::Server::Hypnotoad](https://metacpan.org/pod/Mojo::Server::Hypnotoad),
and so on.

One way to do it, for `https://campaignwiki.org/traveller`:

First, the request is received by the Apache webserver which must hand
it to the backend, which is running on some arbitrary other port:

```perl
<VirtualHost *:443>
    ServerName campaignwiki.org
	# lost of stuff here
	
	# the location of your certificates may vary
    SSLEngine on
    SSLCertificateFile      /var/lib/dehydrated/certs/campaignwiki.org/cert.pem
    SSLCertificateKeyFile   /var/lib/dehydrated/certs/campaignwiki.org/privkey.pem
    SSLCertificateChainFile /var/lib/dehydrated/certs/campaignwiki.org/chain.pem
    SSLVerifyClient None

	# this is the important part
    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "https"
    ProxyPass /traveller          http://localhost:4011/traveller
</VirtualHost>
```

The tricky part is having the application mounted on `/traveller`.
There’s a separate wrapper script which does that, and configures
`hypnotoad` to serve the application on the right port.

```perl
#! /usr/bin/env perl

use Mojolicious::Lite;

app->config(hypnotoad => {
  # this is the port mentioned in the Apache config above
  listen => ['http://localhost:4011'],
  # the PID file must be stored in some directory
  pid_file => '/home/alex/farm/traveller2.pid',
  # you probably don’t need four workers
  workers => 1});

plugin Mount => {'/traveller' => '/home/alex/src/traveller/script/traveller'};

app->start;
```

The plugin `Mount` is a new dependency:

* [Mojolicious](https://metacpan.org/pod/Mojolicious::Plugin::Mount)

# LICENSE

GNU Affero General Public License
