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

Config::Setting::IniParser - parse windows .ini style files.

=head1 SYNOPSIS

 use Config::Setting::IniParser;

 my $ini = Config::Setting::IniParser->new(Filename => $inifile);
 foreach my $s ($ini->sections()) {
     print "[$s]\n";
     foreach my $k ($ini->keylist($s)) {
         print $k, "=", $ini->get($s, $k), "\n";
     }
     print "\n";
 }


=head1 DESCRIPTION

This class provides OO access to windows .ini style files.  At present,
it only provides read access, not writing.

=head1 METHODS

=over 4

=item new ( ARGS )

Instantiate a new object.  ARGS is a set of keyword / value pairs.
Recognised options are:

=over 4

=item CommentChar

Pass in a character that is used as a comment inside the data.  This
defaults to "#", but is also commonly ";".

=back

=item parse_file ( FILENAME )

Parse FILENAME into the object.

=item parse_string ( STRING )

Parse STRING into the object.

=item sections ( )

Return a list of all sections that occurred in the data.  They are
returned in the order in which they originally occurred.

=item keylist ( SECTION )

Return a list of all keys in SECTION.

=item get ( SECTION, KEY )

Return the value of KEY in SECTION.

=back

=head1 SEE ALSO

perl(1).

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan (at) happygiraffe.netE<gt>.

=head1 BUGS

Does not cater for quoted keys and values.

It is a bit eager about comment stripping.

=cut

package Config::Setting::IniParser;

use strict;
use vars qw($rcsid $VERSION);

use Carp;
use Config::Setting::Chunk;

$rcsid = '@(#) $Id: IniParser.pm 765 2005-08-31 20:05:59Z dom $ ';
$VERSION = (qw( $Revision: 765 $ ))[1];

# Pass in either a Filename parameter or a String parameter.
sub new {
        my $class = shift;
        my (%args) = @_;

        my $self = {
                Contents    => {},
                Sections    => [],
                CommentChar => "#",
                %args,
        };
        bless($self, $class);
        return $self;
}

sub parse_file {
        my $self = shift;
        open my $fh, $self->{Filename}
                or croak "open($self->{Filename}): $!";
        my $string = do { local $/ ; <$fh> };
        close $fh;
        return $self->_parse( $string );
}

sub parse_string {
        my $self = shift;
        my ( $string ) = @_;
        return $self->_parse( $string );
}

# Parse the stuff we hold.
sub _parse {
        my $self = shift;
        my ( $string ) = @_;
        my $section = "";
        my $cc = $self->{CommentChar};
        my $lineno = 1;
        my $chunk = Config::Setting::Chunk->new;

        foreach my $line (split /\r?\n/, $string) {
                $line =~ s/$cc.*//;
                $line =~ s/^\s+//;
                next unless $line;

                if ($line =~ m/^\[(.*?)\]/) {
                        $section = $1;
                        $chunk->add_section( $section );
                } elsif ($line =~ m/^(.+?)\s*=\s*(.*)/) {
                        croak "line $lineno occurs outside a section"
                                unless $section;
                        $chunk->set_item( $section, $1, $2 );
                } else {
                        carp "line $lineno is invalid: '$line'";
                }
        }
        return $chunk;
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
# vim: ai et sw=8 :
