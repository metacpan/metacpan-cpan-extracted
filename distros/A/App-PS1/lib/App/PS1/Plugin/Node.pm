package App::PS1::Plugin::Node;

# Created on: 2011-06-21 09:48:47
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use English qw/ -no_match_vars /;

our $VERSION     = 0.08;
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub node {
    my ($self, $options) = @_;
    my $version;
    my $path;

    if ( $path = $ENV{NVM_BIN} ) {
        # best guess for nvm
        ($version) = $path =~ m{/([^/]+)/bin};
    }
    elsif ( $path = $ENV{NODE_PATH} ) {
        # best guess for nave
        ($version) = $path =~ /installed.(.*?).lib/;
    }
    else {
        return;
    }

    return if !$version;

    return $self->surround( 5 + length $version, $self->colour('branch_label') . 'node ' . $self->colour('branch') . $version );
}

1;

__END__

=head1 NAME

App::PS1::Plugin::Node - Shows current version of node if using nave

=head1 VERSION

This documentation refers to App::PS1::Plugin::Node version 0.08.

=head1 SYNOPSIS

   use App::PS1::Plugin::Node;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<node ()>

Determines the current version of C<nodejs> if using C<nave> or C<nvm>.

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
