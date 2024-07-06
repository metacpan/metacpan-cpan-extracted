<p align="center">
    <img src="https://c.tenor.com/Yz9re4omkaQAAAAC/minions-dance.gif" alt="Dancing Minion">
</p>

# Dancer2::Plugin::Minion - Make your minions dance!

<p align="center">
  This plugin provides easy access to a Minion job queue
  in your Dancer2 applications.
  <br>
  <a href="https://metacpan.org/pod/Dancer2%3A%3AManual">Dancer2 Documentation</a>
  ·
  <a href="https://metacpan.org/pod/Minion">Minion Documentation</a>
  ·
  <a href="https://github.com/cromedome/Dancer2-Plugin-Minion/wiki">Public Wiki</a>
  ·
  <a href="https://github.com/cromedome/Dancer2-Plugin-Minion/issues">Issues</a>
</p><br>

`Dancer2::Plugin::Minion` makes it easy to add a job queue to any of your
[Dancer2](https://metacpan.org/pod/Dancer2) applications. The queue is powered by [Minion](https://metacpan.org/pod/Minion)
and a backend of your choosing, such as [PostgreSQL](https://postgresql.org) or
[SQLite](https://sqlite.org).

The plugin lazily instantiates a Minion object, which is accessible via the
`minion` keyword. Any method, attribute, or event you need in Minion is
available via this keyword. Additionally, `add_task` and `enqueue` keywords
are available to make it convenient to add and start new queued jobs.

Add Minion to your `config.yml`:
```
plugins:
  Minion:
    dsn: sqlite:test.db
    backend: SQLite
```
And then implement queuing in your Dancer2 application:

```
package MyApp;
use Dancer2;
use Dancer2::Plugin::Minion;
use Plack::Builder;

get '/' => sub {
    add_task( add => sub {
        my ( $job, $first, $second ) = @_;
        $job->finish( $first + $second );
    });
};

get '/start-job' => sub {
    my $id = enqueue( add => [1, 1] );
    return "Started job ID $id";
};

get '/job-results/:job_id' => sub {
    my $id     = route_parameters->get( 'job_id' ) // 0;
    my $result = minion->job( $id )->info->{ result };
};

build {
    mount '/dashboard/' => minion_app->start;
    mount '/' => start;
}
```
The above application:
- Adds a route (`/`) that defines a job (`add`)
- Adds a route (`/start-job`) to start the `add` job
- Adds a route (`/job-results`) to show information about a job
- Enables the Minion admin dashboard on `/dashboard`

Finally, create a Minion worker to run your queued jobs:
```
#!/usr/bin/env perl

use Dancer2;
use Dancer2::Plugin::Minion;

minion->add_task( add => sub {
    my ( $job, $first, $second ) = @_;
    $job->finish( $first + $second );
});

my $worker = minion->worker;
$worker->run;
```
(you can even refactor the definition of `add` into another module to
eliminate duplicated code too!)

By using `Dancer2::Plugin::Minion` in your worker, it will have
access to the settings defined in your Dancer2 application's
`config.yml` file. See [Minion::Worker](https://metacpan.org/pod/Minion%3A%3AWorker)
for more information.

# ATTRIBUTES

## minion

A [Minion](https://metacpan.org/pod/Minion)-based object. See the [Minion](https://metacpan.org/pod/Minion) documentation for a list of
additional methods provided.

If no backend is specified, Minion will default to an in-memory temporary
database. This is not recommended for any serious use. See
[the Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite#BASICS) docs
for details

# METHODS

## add\_task()

Keyword/shortcut for `minion->add_task()`. See
[Minion's add\_task() documentation](https://metacpan.org/pod/Minion#add_task) for
more information.

## enqueue()

Keyword/shortcut for `minion->enqueue()`.
See [Minion's enqueue() documentation](https://metacpan.org/pod/Minion#enqueue1)
for more information.

## minion\_app()

Build a [Mojolicious](https://metacpan.org/pod/Mojolicious) application with the
[Mojolicious::Plugin::Minion::Admin](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AMinion%3A%3AAdmin) application running. This application can
then be started and mounted inside your own but be sure to leave a trailing
slash in your mount path!

You can optionally pass in an absolute URL to act as the "return to" link. The url must
be absolute or else it will be made relative to the admin UI, which is probably
not what you want. For example:
`mount '/dashboard/' => minion_app( 'http://localhost:5000/foo' )->start;`

# ACKNOWLEDGEMENTS

I'd like to extend a hearty thanks to my employer, Clearbuilt Technologies,
for giving me the necessary time and support for this module to come to
life.

The following contributors have sent patches, suggestions, or bug reports that
led to the improvement of this plugin:

- Gabor Szabo
- Joel Berger
- Slaven Rezić
- Julien Fiegehenn

# COPYRIGHT AND LICENSE

Copyright (c) 2024, Jason A. Crome

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
