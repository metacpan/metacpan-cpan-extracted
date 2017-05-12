# Copyright 2009-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: RewriteAE.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Util::RewriteAE;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( ArrayRef );

use File::Temp qw(tempfile);
use File::Copy;
use List::Util qw(first);
use Bio::MAGETAB::Util::Reader::Tabfile;

has '_termsources'          => ( is         => 'rw',
                                 isa        => ArrayRef,
                                 default    => sub { [] },
                                 required   => 1 );

sub rewrite_sdrf {

    my ( $self, $sdrf ) = @_;

    my $sdrf_parser = Bio::MAGETAB::Util::Reader::Tabfile->new(
        uri => $sdrf,
    );

    my ( $out_fh, $outfile ) = tempfile();

    local $/ = $sdrf_parser->get_eol_char();

    # Header
    my $harry = $sdrf_parser->getline();
    $harry = $sdrf_parser->strip_whitespace( $harry );
    my @tscols;
    for ( my $i = 0; $i < @$harry; $i++ ) {

        # Record the columns containing TSs.
        if ( $harry->[$i] =~ /Term *Source *REFs?/i ) {
            push @tscols, $i;
        }

        # Rewrite Protocol REF columns to remove prefixes.
        if ( $harry->[$i] =~ /Protocol *REFs?/i ) {
            $harry->[$i] = 'Protocol REF';
        }
    }
    $sdrf_parser->print( $out_fh, $harry );

    # Body
    my %termsource;
    while ( my $larry = $sdrf_parser->getline() ) {
        $larry = $sdrf_parser->strip_whitespace( $larry );

        foreach my $col ( @tscols ) {
            my $ts = $larry->[$col];
            $termsource{$ts}++ if $ts;
        }

        $sdrf_parser->print( $out_fh, $larry );
    }
    $sdrf_parser->confirm_full_parse();

    # Replace the original SDRF with the new one.
    close( $out_fh );
    copy( $outfile, $sdrf_parser->get_uri()->path() )
        or die("Error: unable to overwrite old SDRF: $!");

    $self->_set_termsources( [ keys %termsource ] );

    return;
}

sub rewrite_idf {

    my ( $self, $idf ) = @_;

    my $idf_parser = Bio::MAGETAB::Util::Reader::Tabfile->new(
        uri => $idf,
    );

    my ( $out_fh, $outfile ) = tempfile();

    my %needed = map { $_ => 1 } @{ $self->_get_termsources() };

    local $/ = $idf_parser->get_eol_char();

    my ( @lines, $tsline );
    while ( my $larry = $idf_parser->getline() ) {
        $larry = $idf_parser->strip_whitespace( $larry );

        # Store this line arrayref for later.
        if ( $larry->[0] =~ /Term *Source *Names?/ ) {
            $tsline = $larry;
        }

        # Record all the Term Source REFs used in the IDF, add them to
        # the list from the SDRF.
        if ( $larry->[0] =~ /Term *Source *REF/ ) {
            foreach my $name ( @{ $larry }[1..$#$larry] ) {
                $needed{ $name } = 1;
            }
        }

        # Fix the Experiment Design Term Source REF issue.
        if ( $larry->[0] =~ /Experiment *Design *Term *Source *REF/ ) {
            $larry->[0] = 'Experimental Design Term Source REF';
        }

        push @lines, $larry;
    }

    $idf_parser->confirm_full_parse();

    # Sometimes there's just no Term Source Name line. We handle that here.
    unless ( $tsline ) {
        $tsline = ['Term Source Name'];
        push @lines, $tsline;
    }

    # Add missing Term Sources to the Term Source Name line (we don't
    # bother with File or Version since they're optional).
    foreach my $needed ( keys %needed ) {
        unless ( first { $_ eq $needed } @{ $tsline }[1..$#$tsline] ) {
            push @$tsline, $needed;
        }
    }

    # Print out the result in a temporary file.
    foreach my $larry ( @lines ) {
        $idf_parser->print( $out_fh, $larry );
    }

    # Replace the original IDF with the new one.
    close( $out_fh );
    copy( $outfile, $idf_parser->get_uri()->path() )
        or die("Error: unable to overwrite old IDF: $!");
    
    return;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::RewriteAE - A utility class providing methods to
correct some common errors in ArrayExpress MAGE-TAB documents.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::RewriteAE;
 my $rw = Bio::MAGETAB::Util::RewriteAE->new();
 $rw->rewrite_sdrf( $sdrf );
 $rw->rewrite_idf( $idf );

=head1 DESCRIPTION

At the time of writing, many ArrayExpress MAGE-TAB documents do not
fully comply with the latest MAGE-TAB specification, and this class
can be used to rewrite such documents prior to import with the main
Bio::MAGETAB classes. Typically the order of rewriting should be as
shown in the SYNOPSIS, with the SDRF being rewritten first. This is so
the RewriteAE object can record all the Term Sources referenced by the
SDRF and make sure they are all declared in the IDF.

=head1 METHODS

=over 2

=item rewrite_sdrf

Given the name of an SDRF file, overwrite said file with a fixed copy.

=item rewrite_idf

Given the name of an IDF file, overwrite said file with a fixed copy.

=back

=head1 SEE ALSO

L<Bio::MAGETAB>
L<Bio::MAGETAB::Util::Reader>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
