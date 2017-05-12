#!/usr/bin/env perl
#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('MyApp', 'Test');

1;

=head1 NAME

myapp_test.pl - Catalyst Test

=head1 SYNOPSIS

myapp_test.pl [options] uri

 Options:
   --help    display this help and exits

 Examples:
   myapp_test.pl http://localhost/some_action
   myapp_test.pl /some_action

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst action from the command line.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
