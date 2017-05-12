# SYNOPSIS

    use App::Monitor::Simple qw/run/;

    my $ret = run(
        {
            command     => 'ping -c 1 blahhhhhhhhhhhhhhhh.jp',   # required
            interval    => 10,
            retry       => 5,
            quiet       => 1,
        }
    );

# DESCRIPTION

This module provides a simple monitoring.

# METHODS

## run

    my $status = App::Monitor::Simple::run(\%arg);

This method runs the monitoring.

Valid arguments are:

    command   - Specify the monitoring commands.

    interval  - Number of interval seconds. (default: 5)

    retry     - Number of retry count. (default: 0)

    quiet     - if true, suppress stdout / stderror messages. (dafailt: 0)

Return zero if the command succeeds, it returns a non-zero if a failure.
If the retry is specified, the number of times repeat the command.

# AUTHOR

toritori0318 <lt>toritori0318@gmail.com<gt>

# COPYRIGHT AND LICENSE

Copyright (C) 2012 by toritori0318

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
