# NAME

Dancer::Logger::ConsoleAggregator - Dancer Console Logger that aggregates each requests logs to 1 line.

# VERSION

version 0.004

# SYNOPSIS

This module will aggregate all logging done for each request into one line
in the output.  It does this by queueing everything up and adding an
`after` hook that calls the `flush` function, which causes the logger
to output the log line for the current request.

In your `config.yml` simply put:

    logger: 'consoleAggregator'

To use this log module.  Then you can debug like this:

    debug { field1 => "data" };
    debug to_json({ field2 => "data" });
    debug "Raw Data";

And this module will log something like this:

    { "field1" : "data", "field2" : "data", "messages" : [ "Raw Data" ] }

All on one line.

# AUTHORS

- Khaled Hussein <khaled.hussein@gmail.com>
- William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Khaled Hussein.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.