Catalyst::Plugin::Log::Log4perlSimple
=====================================

Provides a zero configuration alternative to [Catalyst::Log][].

Instantly gives you coloured terminal output and timestamps on your development
server.

Provides a trivial mechanism for routing log messages to a file (configurable
via your application's config file).

You can use it something like this:

    # in MyApp.pm

    use Catalyst qw( Log::Log4perlSimple );

    # in myapp.conf

    # note that this configuration is entirely optional. The block below is
    # indicating the default values for everything, so if they look okay to you,
    # just omit the configuration entirely.

    <Plugin Log::Log4perlSimple>

        # Set this to 0 or 1 to indicate if you would like Catalyst debugging output.
        catalyst_debug 0

        # Set this to 0 or 1 to indicate if you would like Catalyst statistics output.
        catalyst_stats 0

        # What is the lowest level of debugging information you would like output
        # by by Log4perl (trace, debug, info, or warn)
        log_level debug

        # Boolean to control if we want to log to screen
        screen 1

        # Optional control specifying a filename to write log data to (comment this
        # out to disable writing to a file)
        #file /path/to/somefile.log

    </Plugin>

[Catalyst::Log]: http://search.cpan.org/~bobtfish/Catalyst-Runtime-5.80032/lib/Catalyst/Log.pm
