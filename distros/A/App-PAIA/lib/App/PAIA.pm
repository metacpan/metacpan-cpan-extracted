package App::PAIA;
use strict;
use App::Cmd::Setup -app;

our $VERSION = '0.30';

sub global_opt_spec {
    ['base|b=s'     => "base URL of PAIA server"],
    ['auth=s'       => "base URL of PAIA auth server"],
    ['core=s'       => "base URL of PAIA core server"],
    ['insecure|k'   => "disable verification of SSL certificates"],
    ['config|c=s'   => "configuration file (default: ./paia.json)"],
    ['session|s=s'  => "session file (default: ./paia-session.json)"],
    ['verbose|v'    => "show what's going on internally"],
    ['debug|D|V'    => "show full HTTP requests and responses"],
    ['quiet|q'      => "don't print PAIA response"],
    ["username|u=s" => "username for login"],
    ["password|p=s" => "password for login"],
    ['access_token|token|t=s' => "explicit access_token"],
    ["patron|o=s"   => "explicit patron identifier"],
    ["scope|e=s"    => "comma-separated list of scopes for login"],
    ["help|h|?"     => "show help", { shortcircuit => 1 } ],
    ["version"      => "show client version", { shortcircuit => 1 } ];
}

1;
__END__

=encoding UTF-8

=head1 NAME

App::PAIA - Patrons Account Information API command line client

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/gbv/App-PAIA.png)](https://travis-ci.org/gbv/App-PAIA)
[![Coverage Status](https://coveralls.io/repos/gbv/App-PAIA/badge.svg?branch=master)](https://coveralls.io/r/gbv/App-PAIA?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/App-PAIA.png)](http://cpants.cpanauthors.org/dist/App-PAIA)

=end markdown

=head1 SYNOPSIS

    paia patron --base http://example.org/ --username alice --password 12345

Run C<paia help> or C<perldoc paia> for more commands and options.

=head1 DESCRIPTION

The L<Patrons Account Information API (PAIA)|http://gbv.github.io/paia/> is a
HTTP based API to access library patron information, such as loans,
reservations, and fees. This client can be used to access PAIA servers via
command line.

=head1 USAGE

See the documentation of of L<paia> command.

To avoid SSL errors install L<Mozilla::CA> or use option C<--insecure>.

=head1 IMPLEMENTATION

The client is implemented using L<App::Cmd>. There is a module for each command
in the App::PAIA::Command:: namespace and common functionality implemented in
L<App::PAIA::Command>.

=head1 RESOURCES

=over

=item L<http://gbv.github.io/paia/>

PAIA specification

=item L<https://github.com/gbv/App-PAIA>

Code repository and issue tracker

=back

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voß, 2013-

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
