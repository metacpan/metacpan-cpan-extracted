package App::PS1::Daemon;

# Created on: 2011-06-21 09:47:54
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Class::Accessor::Fast/;

our $VERSION = 0.05;

sub new {
    my $caller = shift;
    my $class  = ref $caller ? ref $caller : $caller;
    my %param  = @_;
    my $self   = \%param;

    bless $self, $class;

    return $self;
}

1;

__END__

=head1 NAME

App::PS1::Daemon - Gets info that can take a long time to collect so the app_ps1 command can have the data pre-populated

=head1 VERSION

This documentation refers to App::PS1::Daemon version 0.05.

=head1 SYNOPSIS

   use App::PS1::Daemon;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

This module starts a deamon process (if one doesn't already exist) and
communicates with that process. The aim of which is to make sure things plugins
that can take a long time run (eg getting process counts when there are many
processes running on a system) can do their work at either regular intervals
or by triggered events and just hand the pre-processed results back to the
app_ps1 command.

=head2 TODO

Everything.

    * Create an event driven deamon
    * Work out how to talk to said deamon
    * Make sure there is only one deamon running at a time per user

=head1 SUBROUTINES/METHODS

=head2 C<new ( $search, )>

Param: C<$search> - type (detail) - description

Return: App::PS1::Daemon -

Description:

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
