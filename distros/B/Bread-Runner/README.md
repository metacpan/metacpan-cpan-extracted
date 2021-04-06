# NAME

Bread::Runner - run ALL the apps via Bread::Board

# VERSION

version 0.905

# SYNOPSIS

    # Define the components of your app in a Bread::Board
    container 'YourProduct' => as {
        container 'App' => as {
            service 'api.psgi' => (
                # ...
            );
            service 'some_script' => (
                # ...
            )
        };
    };

    # Write one generic wrapper script to run all your services
    # bin/generic_runner.pl
    use Bread::Runner;
    Bread::Runner->run('YourProduct');

    # Symlink this generic runner to filenames matchin your services
    ln -s bin/generic_runner.pl bin/api.psgi
    ln -s bin/generic_runner.pl bin/some_script

    # Never write a wrapper script again!

# DESCRIPTION

`Bread::Runner` provides an easy way to re-use your [Bread::Board](https://metacpan.org/pod/Bread%3A%3ABoard)
to run all your scripts via a simple and unified method.

This of course only makes sense for big-ish apps which consist of more
than just one script. But in my experience this is true for all apps,
as you will need countless helper scripts, importer, exporter,
cron-jobs, fixups etc.

If you still keep the code of your scripts in your scripts, I strongly
encourage you to join us in the 21st century and move all your code
into proper classes and replace your scripts by thin wrappers that
call those classes. And if you use `Bread::Runner`, you'll only need
one wrapper (though you can have as many as you like, as TIMTOWTDI)

## Real-Live Example

TODO

## Guessing the service name from $0

TODO

# METHODS

## run

    Bread::Runner->run('YourProduct', \%opts);

    Bread::Runner->run('YourProduct', {
        service => 'some_script.pl'
    });

Initialize your Bread::Board, find the correct service, initialize the
service, and then run it!

## setup

    my ($bread_board, $service) = Bread::Runner->_setup( 'YourProduct',  \%opts );

Initialize and compose your `Bread::Board` and find and initialize the correct `service`.

Usually you will just call [run](https://metacpan.org/pod/run), but maybe you want to do something fancy..

# OPTIONS

[setup](https://metacpan.org/pod/setup) and [run](https://metacpan.org/pod/run) take the following options as a hashref

### service

Default: `$0` modulo some cleanup magic, see ["Guessing the service name from $0"](#guessing-the-service-name-from-0)

The name of the service to use.

If you do not want to use this magic, pass in the explicit service
name you want to use. This could be hardcoded, or you could come up
with an alternative implementation to get the service name from the
environment available to a generic wrapper script.

### container

Default: "App"

The name of the `Bread::Board` container containing your services.

### init\_method

Default: "init"

The name of the method in the class implementing your `Bread::Board`
that will return the topmost container.

### run\_method

Default: \["run"\]

An arrayref of names of potential methods call in your services to
make them do their job.

Useful for running legacy classes via `Bread::Runner`.

### pre\_run

A subref to be called just before `run` is called.

Gets the following things as a list in this order

- the `Bread::Board` container
- the initiated service
- the opts hashref (so you can pass on more stuff from your wrapper)

You could use this hook to do some further initialisation, setup etc
that might not be doable in `Bread::Board` itself.

### post\_run

A subref to be called just after `run` is called.

Gets the same stuff like `pre_run`.

Could be used for cleanup etc.

### no\_startup\_logmessage

Set this to a true value to prevent the startup log message.

# THANKS

Thanks to

- [validad.com](http://www.validad.com/) for supporting Open Source.
- [Klaus Ita](https://metacpan.org/author/KOKI) for feedback & input during initial in-house development

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
