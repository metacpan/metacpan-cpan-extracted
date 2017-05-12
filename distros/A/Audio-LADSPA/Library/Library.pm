# Audio::LADSPA perl modules for interfacing with LADSPA plugins
# Copyright (C) 2003  Joost Diepenmaat.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# See the COPYING file for more information.



package Audio::LADSPA::Library;
use strict;
our $VERSION = "0.021";
no strict 'refs';

sub plugins {
    @{$_[0].'::PLUGINS'};
}

sub library_file {
    ${$_[0].'::LIBRARY_FILE'};
}

package Audio::LADSPA::Library::Perl;

my @plugins;
sub plugins {
    @plugins;
}

sub register {
    my $dummy = shift;
    push @plugins,@_;
}


sub library_file {
    qw( 'Audio::LADSPA::Library::Perl' );
}

1;

__END__

=pod

=head1 NAME

Audio::LADSPA::Library

=head1 SYNOPSIS

    use Audio::LADSPA;
    my @libs = Audio::LADSPA->libraries();
    # @libs is an array of Audio::LADSPA::Library classes

=head1 DESCRIPTION

Audio::LADSPA::Library is a base class for perl modules representing LADSPA libraries
No objects can be instantiated from it. Each LADSPA library gets its own namespace
based on the name of the library.

=head1 METHODS

All methods in the Audio::LADSPA::Library class are class methods.

=head2 plugins

 my @plugin_classes = $library->plugins();
 
Returns the @plugin_classes this $library implements.

=head2 library_file

 my $shared_object_file = $library->library_file();

Returns the name of the $shared_object_file this $library was created from.

=head1 SEE ALSO

L<Audio::LADSPA>, L<Audio::LADSPA::Plugin>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 Joost Diepenmaat <jdiepen@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

