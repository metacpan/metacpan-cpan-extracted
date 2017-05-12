package App::Dispatch;
use strict;
use warnings;

our $VERSION = '0.007';

# NOTE:
# All code is located in bin/app_dispatch. No code is here, this is to help with
# portability, and to allow use of dispatch.pl in any perl installed to the
# system even ones other than the one to which it was installed.

1;

__END__

=pod

=head1 NAME

App::Dispatch - Tool to have #! dispatch to the best executable for the job.

=head1 DESCRIPTION

App::Dispatch is an alternative to C</usr/bin/env>. Unlike C</usr/bin/env>, it
does not rely on your environment to tell it which program to use. You can set
system-wide, and user level configurations for which program to use. You can
also specify a cascade of aliases and/or paths to search.

Lately it has been a trend to avoid the system install of programming
languages, Perl, Ruby, Python, etc, in most cases it is recommended that you do
not use the system installation of the language. A result of this is heavy use
of C<#!/usr/bin/env> to lookup the correct binary to execute based on your
C<$PATH>. The problem with C</usr/bin/env> is that you may not always have
control over the environment. For example if you have a script that you must
run with sudo, your C<$PATH> will be reset.

With App::Dispatch you can specify multiple locations to try when looking for
the program. You can also configure aliases at the system or user level. This
is useful when you have multiple versions of the program installed and wish
different things to use different ones by a label. In this way the versions
need not be in the same location on each machine that can run the script.

=head1 SYNOPSYS

=head2 NO CONFIG

The following #! line will cause the script to be run by perl, it will try each
path listed in order.

    #!/usr/local/bin/dispatch perl /path/to/perl /alternate/path/to/perl /another/perl

This tells the script to use the specified path if available, otherwise fall
back to whichever perl is in the environment.

    #!/usr/local/bin/dispatch perl /path/to/perl ENV

You can also pass arguments to the program by putting them after C<-->:

    #!/usr/local/bin/dispatch perl /path/to/perl ENV -- -w

=head2 WITH CONFIG

$HOME/.dispatch.conf:

    [perl]
        SYSTEM     = /usr/bin/perl
        DEFAULT    = /opt/ACME/current/bin/perl
        production = /opt/ACME/stable/bin/perl

This #! line will run perl, it will find the 'production' perl, if no
production perl is found it will try 'DEFAULT'. Anything after the -- is passed
as arguments to perl.

    #!/usr/local/bin/dispatch perl production DEFAULT -- -w

This will run the default perl.

    #!/usr/local/bin/dispatch perl

=head1 CONFIG FILES

=head2 LOCATIONS

Locations are loaded in this order. All locations that exist are loaded. Later
files can override earlier ones.

=over 4

=item /etc/dispatch.conf

The system wide configuration

=item /etc/dispatch/*

System wide config dir, to have app specific config files for easier management
with system packages.

=item $HOME/.dispatch.conf

User specific overrides or additions.

=back

=head2 EXAMPLE

    [perl]
        SYSTEM     = /usr/bin/perl
        DEFAULT    = /opt/ACME/current/bin/perl
        production = /opt/ACME/stable/bin/perl

    [gcc]
        SYSTEM  = /usr/bin/gcc
        DEFAULT = /usr/bin/gcc
        old     = /opt/legacy/bin/gcc

=head1 NOTE FOR CPAN AUTHORS

This tool is very useful for perl shops in their own scripts. However it most
likely should not be used in any scripts that will be installed with a cpan
distribution. Distributions should use a normal #! line that will be rewritten
by the build tools to use the perl for which the dist was installed. This is
important because of dependency chains and XS modules.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

App-Dispatch is free software; Standard perl licence.

App-Dispatch is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.

=cut
