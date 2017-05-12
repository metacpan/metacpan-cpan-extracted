# Copyright (C) 2004 by Dominic Mitchell. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

=pod

=head1 NAME

Config::Setting - Perl extension for configuration files.

=head1 SYNOPSIS

  use Config::Setting;
  my $stg = Config::Setting->new;
  $stg->get("section", "key");

=head1 DESCRIPTION

This module provides an OO interface to a file full of settings.
Settings are assumed to be contained in collections (known as
"sections").  Each setting has a key and a value. The value of a
setting may refer to other settings using a similiar syntax to
variables in perl.

Whilst this module can be used directly it is anticipated that it will
be subclassed.  This way policy regarding the location and layout of
the settings can be determined for your project.

=head1 METHODS

=over 4

=item new ( )

The constructor.  Takes no arguments.

=item is_configured ( )

Returns true if more than one configuration file has been found and
read.

=item provider ( )

Returns an object which can be used to collect the contents of files.
The default returns a L<Config::Setting::FileProvider> object.  You
probably want to override this method when you set up your subclass, in
order to set the policy for file locations.

=item parser ( )

Returns a parser object.  The default is the
L<Config::Setting::IniParser> object.  You may want to override this in
a subclass if you wish to use an alternative format for your
configuration files.

=item sections ( )

Return a list of which sections are available from this object.

=item keylist ( SECTION )

Return a list of keys that SECTION contains.

=item has ( SECTION, KEY )

Returns true if SECTION contains KEY.

=item expand ( )

Internal use only.

=item get ( SECTION, KEY )

Return the value of KEY in SECTION.  If the value contains any
variables of the form ${word}, they will be fully expanded in the
return value.

When trying to replace a variable "word", first, "word" will be looked
up as a key in the current section.  If not found, it will then be
looked up sequentially in all the other sections.  If still not found,
it will be replaced with an empty string.

Expansion is recursive, so an expanded variable can contain other
variables.

=back

=head1 TODO

It would be useful to know where each setting derived from, in order to
help debugging.

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan (at) happygiraffe.netE<gt>

=head1 SEE ALSO

L<Config::Setting::FileProvider>,
L<Config::Setting::IniParser>,
L<Config::Setting::XMLParser>.

=cut

package Config::Setting;

use strict;
use vars qw($VERSION $rcsid);

use Carp;
use Config::Setting::IniParser;
use Config::Setting::FileProvider;

$VERSION = '0.04';
$rcsid = '@(#) $Id: Setting.pm 765 2005-08-31 20:05:59Z dom $ ';

sub new {
        my $class = shift;
        my $self = {
                Config => { },
        };

        bless $self, $class;
        return $self->_init;
}

#---------------------------------------------------------------------
# These two functions are defaults and may be overridden

sub provider {
        my $self = shift;
        return Config::Setting::FileProvider->new(@_);
}

sub parser {
        my $self = shift;
        return Config::Setting::IniParser->new(@_);
}

#---------------------------------------------------------------------

sub _init {
        my $self = shift;
        my $provider = $self->provider;

        my @txts = $provider->provide();
        my @configs;
        foreach my $s (@txts) {
                my $p = $self->parser();
                push @configs, $p->parse_string( $s );
        }
        $self->{ is_configured } = @configs > 0;

        return $self->_merge(@configs);
}

# Make up a combined configuration from all the ones provided.
# NB: Must maintain order of sections!
sub _merge {
        my $self = shift;
        my @configs = @_;
        my %cf;           # Combined config.
        my @sections;

        my $chunk = Config::Setting::Chunk->new;
        foreach my $c (@configs) {
                foreach my $s ($c->sections) {
                        $chunk->add_section( $s );
                        foreach my $k ($c->section_keys($s)) {
                                my $v = $c->get_item($s, $k);
                                $chunk->set_item( $s, $k, $v );
                        }
                }
        }
        $self->_chunk( $chunk );
        return $self;
}

#---------------------------------------------------------------------
# Data access...

sub sections {
        my $self = shift;
        return $self->_chunk->sections;
}

sub keylist {
        my $self = shift;
        my ($section) = @_;
        croak "usage: Config::Setting->keylist(section)"
                unless $section;
        return $self->_chunk->section_keys( $section );
}

sub has {
        my $self = shift;
        my ($section, $key) = @_;
        croak "usage: Config::Setting->get(section,key)"
                unless $section && $key;

        return defined $self->_chunk->get_item( $section, $key );
}

# Get the value of a setting, searching all sections, but starting in
# the section specified.  May also specify a key that cannot be expanded.
# Internal.
sub expand {
        my $self = shift;
        my ($section, $key, $origkey) = @_;
        croak "usage: expand(section,key,origkey)"
                unless $section && $key && $origkey;

        # Move our section to the top of the list.
        my @sections = ($section, grep { $_ ne $section} $self->sections);

        return undef
                if $key eq $origkey;

        foreach my $s (@sections) {
                return $self->get($s, $key)
                        if $self->has($s, $key);
        }

        return undef;
}

# Return the value of a setting, fully expanded.
sub get {
        my $self = shift;
        my ($section, $key) = @_;
        croak "usage: Config::Setting->get(section,key)"
                unless $section && $key;

        my $val = $self->_chunk->get_item( $section, $key );
        while ($val && $val =~ m/\$/) {
                $val =~ s{ \$ \{ (\w+) \} }{
                        $self->expand($section, $1, $key) || "";
                }exg;
        }
        return $val;
}

sub _chunk {
        my $self = shift;
        $self->{ _chunk } = $_[0] if @_;
        return $self->{ _chunk };
}

sub is_configured {
        my $self = shift;
        return $self->{ is_configured };
}

1;
__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 8
# indent-tabs-mode: nil
# cperl-continued-statement-offset: 8
# End:
#
# vim: set ai et sw=8 :
