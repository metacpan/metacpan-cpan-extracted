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

package Audio::LADSPA;
use strict;
use Audio::LADSPA::LibraryLoader;
use Audio::LADSPA::Buffer;
use 5.006;
use Carp;

our $VERSION = "0.021";

our @LIBRARIES;	    # will store the list of found libraries as Perl class names
our @PLUGINS;	    # will store the names of all loaded plugins as Perl class names
our %PLUGINS;	    # will store the values in @PLUGINS indexed by id

unless (@LIBRARIES) {
    for my $lib_path (Audio::LADSPA::LibraryLoader->find_libraries()) {
	Audio::LADSPA->load($lib_path);
    }
}

sub load {
    my ($class,$lib_path) = @_;
    if (my $lib = Audio::LADSPA::LibraryLoader->load($lib_path)) {
        push @LIBRARIES,$lib;
        for ($lib->plugins()) {
            push @PLUGINS,$_;
            $PLUGINS{ $_->id } = $_;
        }
        return $lib;
    }
    return;
}


sub libraries {
    @LIBRARIES,'Audio::LADSPA::Library::Perl';
}

sub plugins {
    @PLUGINS,'Audio::LADSPA::Library::Perl'->plugins;
}

sub plugin {
    shift;
    (my (%args) = @_) or croak "usage: Audio::LADSPA::Plugin->( find_args )";
    if ($args{id}) {
        return $PLUGINS{$args{id}};
    }
    else {
	for (@PLUGINS) {
	    if ($args{label}) {
		next unless $_->label eq $args{label};
	    }
	    if ($args{name}) {
		next unless $_->name eq $args{name};
	    }
	    return $_;
	}
    }
}

END {
    for (@LIBRARIES) {
	Audio::LADSPA::LibraryLoader->unload($_);
    }
}

1;

__END__

=head1 NAME

Audio::LADSPA - Modular audio processing using LADSPA plugins. Implements a LADSPA 1.1 host.

=head1 SYNOPSIS

    use Audio::LADSPA;

    for my $class (Audio::LADSPA->plugins) {
	print "\t",$class->name," (",$class->id,"/",$class->label,")";
    }


=head1 DESCRIPTION

LADSPA plugins are objects in shared libraries that can generate or transform audio
signals (like VST or Direct-X plugins on Mac and Win32 systems). Most of the existing
LADSPA plugins are pretty low-level compared to VST plugins (you get seperate
oscilator, ADSR and delay plugins instead of "complete" virtual synthesizers etc). 
See also http://www.ladspa.org/

With these modules you can create a LADSPA host, which can load the plugins,
query their capabilities, connect them together in a network, and run audio
streams through them.

The LADSPA API was developed for linux but should be platform independent, so you
might be able to compile these modules and the nessisary plugins on win32 systems
(please let me know if it works or not).

=head1 USER GUIDE

This is the reference documentation.  If you want a general 
overview/introduction on this set of modules, take a look at 
L<Audio::LADSPA::UserGuide> (not finished).

Reading L<Audio::LADSPA::Plugin> and L<Audio::LADSPA::Network> is
recommended.

=head1 STARTUP

By default, C<use Audio::LADSPA> will attempt to load all
libraries in the $ENV{LADSPA_PATH} (a colon seperated list
of directories) or "/usr/lib/ladspa" and "/usr/local/lib/ladspa" if
$ENV{LADSPA_PATH} is not set.

You can then get the loaded libraries and their plugins using
the C<libraries>, C<plugins> and C<plugin> methods described below.

=head1 METHODS

All methods in the Audio::LADSPA package are class methods.

=head2 plugins

    my @availabe_plugins = Audio::LADSPA->plugins();

Returns the list of @available_plugins. These are package names
you can use to create a new instance of those plugins, can invoke
class-methods on to query the plugins, and pass to Audio::LADSPA::Network
to do most of the work for you. See also L<Audio::LADSPA::Plugin> and
L<Audio::LADSPA::Network>.

=head2 plugin

    my $plugin = Audio::LADSPA->plugin( %search_arguments );

Get the package name (class) for a specific Audio::LADSPA::Plugin
subclass given the %search_arguments. Returns the I<first matching>
plugin class or C<undef> if none is found. You can use one or
less of each of these:

=head3 id

    my $sine_faaa_class = Audio::LADSPA->plugin( id => 1044 );

Match a plugin class by unique id. If one is loaded returns the class
name. If an C<id> argument is present, other %search_arguments will
not be considered.

=head3 label

    my $delay_5s = Audio::LADSPA->plugin( label => 'delay_5s' );

Match a plugin class by C<label>. If C<name> is also specified,
the plugin must also match C<name>.

=head3 name

    my $noise = Audio::LADSPA->plugin( name => 'White Noise Source' );

Match a plugin class by C<name>. If C<label> is also specified,
the plugin must also match C<label>.

=head2 libraries

    my @loaded_libraries = Audio::LADSPA->libraries();

Returns the list of @loaded_libraries (Audio::LADSPA::Library subclasses),
mostly useful if you want to know which plugins are in a specific library.

See also L<Audio::LADSPA::Library>.

=head2 

=head1 SEE ALSO

L<Audio::LADSPA::UserGuide> - the user guide.

=head2 Modules and scripts in this distribution

L<pluginfo> - query ladspa plugins.

L<Audio::LADSPA> - this module.

L<Audio::LADSPA::Library> - libraries containing one
or more plugins

L<Audio::LADSPA::Plugin> - Base class for ladspa plugins 

L<Audio::LADSPA::Network> - a set of connected plugins and buffers

L<Audio::LADSPA::Plugin::Play> - output audio to soundcard.

L<Audio::LADSPA::Plugin::Sequencer4> - a simple 4-step sequencer.

L<Audio::LADSPA::Plugin::XS> - Base class real (compiled) ladspa plugins

L<Audio::LADSPA::Plugin::Perl> - Base class for perl-only ladspa
plugins.

L<Audio::LADSPA::Buffer> - audio/data buffer that can be used to control
a plugin or to connect plugins together

L<Audio::LADSPA::LibraryLoader> - loads ladspa shared libraries (.so files) into
Audio::LADSPA::Library classes

=head2 Links

For more information about the LADSPA API, and how to obtain more plugins, see 
http://www.ladspa.org/

=head1 THANKS TO

=over 4

=item * Mike Castle, for providing a patch for non-C'99 compilers.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 - 2005 Joost Diepenmaat <jdiepen AT cpan.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

