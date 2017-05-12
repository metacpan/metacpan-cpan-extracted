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

Config::Setting::XMLParser - parse XML settings file.

=head1 SYNOPSIS

 use Config::Setting::XMLParser;

 my $ini = Config::Setting::XMLParser->new(Filename => $xmlfile);
 foreach my $s ($ini->sections()) {
     print "[$s]\n";
     foreach my $k ($ini->keylist($s)) {
         print $k, "=", $ini->get($s, $k), "\n";
     }
     print "\n";
 }


=head1 DESCRIPTION

This class provides access to settings stored in an XML File.  The XML
File is expected to have the following structure:

  <settings>
    <section name="SECTION">
      <item name="KEY">VALUE</item>
    </section>
  </settings>

Multiple E<lt>sectionE<gt>s and E<lt>itemE<gt>s may be present.  Any
leading and trailing whitespace within an E<lt>itemE<gt> tag will be
stripped.

=head1 METHODS

=over 4

=item new ( ARGS )

Instantiate a new object.  ARGS is a set of keyword / value pairs which
will be passed to the L<XML::Parser> constructor.

=item parse_file ( FILENAME )

Parse FILENAME as XML.

=item parse_string ( STRING )

Parse the string as XML.

=item sections ( )

Return a list of all sections that occurred in the data.  They are
returned in the order in which they originally occurred.

=item keylist ( SECTION )

Return a list of all keys in SECTION.

=item get ( SECTION, KEY )

Return the value of KEY in SECTION.

=back

=head1 SEE ALSO

perl(1),
L<Config::Setting::IniParser>,
L<XML::Parser>.

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan (at) happygiraffe.netE<gt>.

=cut

package Config::Setting::XMLParser;

use strict;
use vars qw($rcsid $VERSION);

use Carp;
use Config::Setting::Chunk;
use XML::Parser;

$rcsid = '@(#) $Id: XMLParser.pm 765 2005-08-31 20:05:59Z dom $ ';
$VERSION = (qw( $Revision: 765 $ ))[1];

sub new {
        my $class = shift;
        my (%args) = @_;

        my $self = {
                Contents => {},
                Sections => [],
                Args     => \%args,
        };
        bless($self, $class);
        return $self;
}

sub parse_file {
        my $self = shift;
        my ( $filename ) = @_;
        open my $fh, $filename
                or croak "open($filename): $!";
        my $string = do { local $/ ; <$fh> };
        close $fh;
        return $self->_parse( $string );
}

sub parse_string {
        my $self = shift;
        my ( $string ) = @_;
        return $self->_parse( $string );
}

#---------------------------------------------------------------------

{
        my $chunk;                 # Copy of $self during parse.
        my $CurSection;
        my $CurItem;
        my $CurVal;

        # Parse the stuff we hold.
        sub _parse {
                my $self = shift;
                my ($string) = @_;
                my $p = XML::Parser->new(
                        Style => "Subs",
                        Pkg => ref($self),
                        %{ $self->{ Args } },
                       );
                $p->setHandlers(Char => \&Text);

                $chunk = Config::Setting::Chunk->new;
                $CurSection = $CurItem = $CurVal = "";
                eval { $p->parse($string) };
                croak $@ if $@;

                return $chunk;
        }

        sub section {
                my ($expat, $tag, %attrs) = @_;
                my $section = $attrs{name};
                croak "no section name specified!"
                        unless $section;
                $CurSection = $section;
                $chunk->add_section( $section );
        }

        sub item {
                my ($expat, $tag, %attrs) = @_;
                my $key = $attrs{name};
                croak "no item name specified!"
                        unless $key;
                $CurItem = $key;
        }

        sub Text {
                my ($expat, $val) = @_;
                return unless $CurItem;
                $CurVal .= $val;
        }

        sub item_ {
                my ($expat, $tag) = @_;
                # Trim whitespace.
                $CurVal =~ s/^\s*(.*)\s*$/$1/;
                $chunk->set_item( $CurSection, $CurItem, $CurVal );
                $CurItem = $CurVal = "";
        }
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
