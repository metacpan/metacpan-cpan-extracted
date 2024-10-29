package App::SourcePlot::VO::SAMP;

=head1 NAME

App::SourcePlot::VO::SAMP - SAMP interface for SourcePlot

=head1 DESCRIPTION

This module provides a SAMP plugin for the SourcePlot application.  It should
attempt to register with a SAMP hub and subscribe to the C<table.load.votable>
mtype.  Coordinates thus received will be added to the source list.

=head2 Notes on Implementation

=over 4

=item *

In the absence of a usable SAMP library for Perl,
this module currently works by running a copy of the
JSamp "snooper" tool via StarJava.  The
C<STARLINK_DIR> environment variable must be set
to allow it to find C<starjava> and C<jsamp.jar>.

=item *

Tables received via SAMP are parsed using the library
C<Astro::Catalog::IO::VOTable> (which in turn uses
C<Astro::VO::VOTable>).  This module may only be able
to handle a limited variety of VOTable files.

=back

=cut

use strict;

our $VERSION = '1.32';

use File::Spec;
use Tk::IO;
use LWP::UserAgent;
use Astro::Catalog;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless {
    }, $class;
}

sub initialize {
    my $self = shift;
    my $w = shift;
    my %opt = @_;

    unless (defined $ENV{'STARLINK_DIR'}) {
        print STDERR "App::SourcePlot::VO::SAMP: \$STARLINK_DIR not defined\n";
        return;
    }

    my $starjava = File::Spec->catfile(
        $ENV{'STARLINK_DIR'},
        qw/java jre bin java/);

    $starjava = File::Spec->catfile(
        $ENV{'STARLINK_DIR'},
        qw/java bin java/)
        unless -e $starjava;

    unless (-e $starjava) {
        print STDERR "App::SourcePlot::VO::SAMP: starjava not found\n";
        return;
    }

    my $jsamp = File::Spec->catfile(
        $ENV{'STARLINK_DIR'},
        qw/starjava lib jsamp jsamp.jar/);

    unless (-e $jsamp) {
        print STDERR "App::SourcePlot::VO::SAMP: jsamp.jar not found\n";
        return;
    }

    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->agent('SourcePlot');

    my $fh = Tk::IO->new(-linecommand => sub {
        my $line = shift;

        return unless $line =~ /"url": "(http:\/\/[a-z0-9\/.:]+)"/;
        my $url = $1;

        my $res = $ua->get($url);

        unless ($res->is_success) {
            print STDERR "App::SourcePlot::VO::SAMP: Unable to retrieve $url\n";
        }
        else {
            my $doc = $res->content;
            my $cat = Astro::Catalog->new(Format => 'VOTable', Data => $doc);
            $opt{'-addCmd'}->([map {$_->coords} $cat->allstars]);
        }
    });

    $fh->exec("$starjava -jar $jsamp snooper -clientname SourcePlot -mtype table.load.votable");

    # Attempt to have the JSamp snooper exit when SourcePlot is closed.
    $w->bind('<Destroy>', sub {
        $fh->kill(2);
    });
}

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2024 East Asian Observatory
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc.,51 Franklin
Street, Fifth Floor, Boston, MA  02110-1301, USA

=cut
