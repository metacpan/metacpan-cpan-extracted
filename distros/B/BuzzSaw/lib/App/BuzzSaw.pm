package App::BuzzSaw;
use strict;
use warnings;

# $Id: BuzzSaw.pm.in 21368 2012-07-17 11:18:36Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21368 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/App/BuzzSaw.pm.in $
# $Date: 2012-07-17 12:18:36 +0100 (Tue, 17 Jul 2012) $

our $VERSION = '0.12.0';

use Moose;

extends qw(MooseX::App::Cmd);

use constant plugin_search_path => 'BuzzSaw::Cmd';
use constant allow_any_unambiguous_abbrev => 1;

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=head1 NAME

App::BuzzSaw - The BuzzSaw command-line application.

=head1 VERSION

This documentation refers to App::BuzzSaw version 0.12.0

=head1 SYNOPSIS

This module is not designed to be used directly. It is used by the
C<buzzsaw> command-line application. The command-line application
looks like:

  use App::BuzzSaw;

  App::BuzzSaw->run();

=head1 DESCRIPTION

This module provides the command-line interface handling for the
C<buzzsaw> command. It extends the L<MooseX::App::Cmd> class and
configures it to load application modules from the L<BuzzSaw::Cmd>
namespace. It allows the use of any unambiguous shortened version of a
longer application module name. For example, if the module is named
C<BuzzSaw::FooBar> you can call it as C<buzzsaw foo>.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

This class has no attributes.

=head1 SUBROUTINES/METHODS

This class has a single method:

=over

=item run

This method does the work of processing the command-line arguments and
loading the appropriate L<BuzzSaw::Cmd> module.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need L<MooseX::App::Cmd>

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Cmd>, L<App::Cmd>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
