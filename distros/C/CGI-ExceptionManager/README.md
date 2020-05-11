# NAME

CGI::ExceptionManager - DebugScreen with detach!

# SYNOPSIS

    use CGI::ExceptionManager;
    CGI::ExceptionManager->run(
        callback => sub {
            redirect("http://wassr.jp/");

            # do not reach here
        },
        powered_by => 'MENTA',
    );

    sub redirect {
        my $location = shift;
        print "Status: 302\n";
        print "Location: $location\n";
        print "\n";

        CGI::ExceptionManager::detach();
    }

# DESCRIPTION

You can easy to implement DebugScreen and Detach architecture =)

# METHODS

- detach

    detach from current context.

- run

        CGI::ExceptionManager->run(
            callback => \&code,
            powered_by => 'MENTA',
        );

    run the new context.

    You can specify your own renderer like following code:

        CGI::ExceptionManager->run(
            callback   => \&code,
            powered_by => 'MENTA',
            renderer   => sub {
            },
        );

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

Kazuho Oku

# SEE ALSO

[Sledge::Plugin::DebugScreen](https://metacpan.org/pod/Sledge%3A%3APlugin%3A%3ADebugScreen), [http://kazuho.31tools.com/nanoa/nanoa.cgi](http://kazuho.31tools.com/nanoa/nanoa.cgi), [http://gp.ath.cx/menta/](http://gp.ath.cx/menta/)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
