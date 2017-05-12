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

Config::Setting::Chunk - Representation of a configuration file

=head1 SYNOPSIS

  use Config::Setting::Chunk;

  my $chunk = Config::Setting::Chunk->new;
  $chunk->add_section( "login" );
  $chunk->set_item( "login", "username", "fred" );

  my @sections = $chunk->sections;
  my $username = $chunk->get_item( "login", "username" );

=head1 DESCRIPTION

This class is a representation of a configuration file.  A chunk
consists of zero or more I<sections>, each of which consists of zero or
more I<items>.

=head1 METHODS

=over 4

=item new ( )

Class Method.  Constructor.

=item add_section ( SECTION )

Create a new section named SECTION.  Has no effect if SECTION is already
present in this chunk.

=item sections ( )

Return a list of all sections in this chunk, in the order in which they
were added.

=item has_section ( SECTION )

Returns true or false if SECTION is present or not in this chunk.

=item section_keys ( SECTION )

Returns a list of all keys present in SECTION.

=item set_item ( SECTION, KEY, VALUE )

Set the item KEY to have VALUE in SECTION.  if SECTION does not exist,
it will be created.

=item get_item ( SECTION, KEY )

Return the value of KEY in SECTION.  Returns undef if KEY or SECTION
does not exist.

=item get ( KEY )

Return the value of KEY in the first section which contains it, or undef
if no section contains it.

=item to_string ( )

Returns the chunk in windows .INI style format.  This may be useful for
debugging.

=back

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan (at) happygiraffe.netE<gt>

=head1 SEE ALSO

L<Config::Setting>.

=cut

package Config::Setting::Chunk;

use strict;
use vars qw($VERSION $rcsid);

use Carp;

$VERSION = ( qw( $Revision: 765 $ ) )[1];
$rcsid   = '@(#) $Id: Chunk.pm 765 2005-08-31 20:05:59Z dom $ ';

sub new {
        my $class = shift;
        return bless {}, $class;
}

sub add_section {
        my $self = shift;
        my ( $sect ) = @_;
        croak "usage: add_section(sect)" unless $sect;
        unless ( exists $self->{ Sections }{ $sect } ) {
                $self->{ Sections }{ $sect } = {};
                $self->{ SectionOrder } ||= [];
                push @{ $self->{ SectionOrder } }, $sect;
        }
        return;
}

sub sections {
        my $self = shift;
        return @{ $self->{ SectionOrder } || [] };
}

sub has_section {
        my $self = shift;
        my ( $sect ) = @_;
        croak "usage: has_section(sect)" unless $sect;
        return exists $self->{ Sections }{ $sect };
}

sub section_keys {
        my $self = shift;
        my ( $sect ) = @_;
        croak "usage: section_keys(sect)"
                unless $sect;
        return sort keys %{ $self->{Sections}{$sect} || {} };
}

sub set_item {
        my $self = shift;
        my ( $sect, $key, $val ) = @_;
        croak "usage: set_item(sect,key,val)"
            unless $sect && $key && $val;
        $self->add_section( $sect );
        $self->{ Sections }{ $sect }{ $key } = $val;
        return;
}

sub get_item {
        my $self = shift;
        my ( $sect, $key ) = @_;
        croak "usage: get_item(sect,key)"
            unless $sect && $key;
        # Avoid autovivification.
        return unless $self->has_section( $sect );
        return $self->{ Sections }{ $sect }{ $key };
}

sub get {
        my $self = shift;
        my ( $key ) = @_;
        foreach my $sect ( $self->sections ) {
                my $val = $self->get_item( $sect, $key );
                return $val if defined $val;
        }
        return;
}

sub to_string {
        my $self = shift;
        my $str  = '';
        foreach my $sect ( $self->sections ) {
                $str .= "[$sect]\n";
                foreach my $key ( $self->section_keys( $sect ) ) {
                        $str .= $key . '=' . $self->get_item( $sect, $key );
                        $str .= "\n";
                }
                $str .= "\n";
        }
        return $str;
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
