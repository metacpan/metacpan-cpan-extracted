# NAME

Dancer2::Plugin::Minion - Easy access to Minion job queue in your Dancer2 
applications

# SYNOPSIS

    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::Minion;
    use Plack::Builder;

    get '/' => sub {
        add_task( add => sub {
            my ($job, $first, $second) = @_;
            $job->finish($first + $second);
        });
    };

    get '/another-route' => sub {
        my $id = enqueue(add => [1, 1]);
        # Do something with $id
    };

    get '/yet-another-route' => sub {
        # Get a job ID, then...
        my $result = minion->job($id)->info->{result};
    };

    build {
      mount '/dashboard/' => minion_app->start;
      mount '/' => start;
    }

    # In config.yml
    plugins:
        Minion:
            dsn: sqlite:test.db
            backend: SQLite

# DESCRIPTION

`Dancer2::Plugin::Minion` makes it easy to add a job queue to any of your
[Dancer2](https://metacpan.org/pod/Dancer2) applications. The queue is powered by [Minion](https://metacpan.org/pod/Minion) and uses a 
backend of your choosing, such as PostgreSQL or SQLite.

The plugin lazily instantiates a Minion object, which is accessible via the
`minion` keyword. Any method, attribute, or event you need in Minion is 
available via this keyword. Additionally, `add_task` and `enqueue` keywords
are available to make it convenient to add and start new queued jobs.

See the [Minion](https://metacpan.org/pod/Minion) documentation for more complete documentation on the methods
and functionality available.

# ATTRIBUTES

## minion

The [Minion](https://metacpan.org/pod/Minion)-based object. See the [Minion](https://metacpan.org/pod/Minion) documentation for a list of
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

# RUNNING JOBS

You will need to create a Minion worker if you want to be able to run your 
queued jobs. Thankfully, you can write a minimal worker with just a few
lines of code:

    #!/usr/bin/env perl

    use Dancer2;
    use Dancer2::Plugin::Minion;
    use MyJobLib;

    minion->add_task( my_job_1 => MyJobLib::job1());

    my $worker = minion->worker;
    $worker->run;

By using `Dancer2::Plugin::Minion`, your worker will be configured with 
the settings provided in your `config.yml` file. See [Minion::Worker](https://metacpan.org/pod/Minion%3A%3AWorker) 
for more information.

# SEE ALSO

- [Dancer2](https://metacpan.org/pod/Dancer2)
- [Minion](https://metacpan.org/pod/Minion)

# AUTHOR

Jason A. Crome ` cromedome AT cpan DOT org `

# ACKNOWLEDGEMENTS

I'd like to extend a hearty thanks to my employer, Clearbuilt Technologies,
for giving me the necessary time and support for this module to come to
life.

The following contributors have sent patches, suggestions, or bug reports that
led to the improvement of this plugin:

- Gabor Szabo
=item \* Joel Berger
=item \* Slaven Rezić

# COPYRIGHT AND LICENSE

Copyright (c) 2020, Clearbuilt Technologies.

This is free software; you can redistribute it and/or modify it under 
the same terms as the Perl 5 programming language system itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 211:

    Non-ASCII character seen before =encoding in 'Rezić'. Assuming UTF-8
