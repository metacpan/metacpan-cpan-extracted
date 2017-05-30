package CPANTS::Kwalitee::Report;

$CPANTS::Kwalitee::Report::VERSION   = '0.10';
$CPANTS::Kwalitee::Report::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

CPANTS::Kwalitee::Report - CPANTS Kwalitee Report.

=head1 VERSION

Version 0.10

=cut

use 5.006;
use Data::Dumper;
use File::Temp qw/tempdir/;

use LWP::Simple;
use XML::RSS::Parser;
use Parse::CPAN::Packages;
use Module::CPANTS::Analyse;
use Module::CPANTS::Kwalitee;

use CPANTS::Kwalitee::Report::Score;
use CPANTS::Kwalitee::Report::Generator;
use CPANTS::Kwalitee::Report::Indicator;
use CPANTS::Kwalitee::Report::Distribution;

use Moo;
use namespace::clean;

our $PAUSE_INDEX = 'http://www.cpan.org/modules/02packages.details.txt.gz';
our $RECENT_MODS = 'https://metacpan.org/feed/recent';
our $MIN_COUNT   = 5;
our $MAX_COUNT   = 100;

has [ qw(parser generators indicators recent_dists verbose) ] => (is => 'rw');
has [ qw(index recent rss kwalitee) ] => (is => 'lazy');

sub _build_index    { get($PAUSE_INDEX)             }
sub _build_recent   { get($RECENT_MODS)             }
sub _build_rss      { XML::RSS::Parser->new         }
sub _build_kwalitee { Module::CPANTS::Kwalitee->new }
sub _build_verbose  { 0                             }

=head1 DESCRIPTION

This work is  inspired  by L<Module::CPANTS::Analyse> and  L<Test::Kwalitee>. The
main objective of this module  is to provide simple API to query Kwalitee scores.

I came across a script C<kwalitee-metrics>, part of  L<Test::Kwalitee>, where the
author wish there was an API to do what the author was doing. That prompted me to
begin the journey.

This is what it would look like now, if using this module:

    use strict; use warnings;
    use CPANTS::Kwalitee::Report;

    my $verbose = @ARGV && ($ARGV[0] eq '--verbose' || $ARGV[0] eq '-v');
    my $report  = CPANTS::Kwalitee::Report->new({ verbose => $verbose });

    print sprintf("%s\n\n", join("\n", @{$report->get_generators}));

Interesting comparison by L<Devel::Timer> shown below:

    Devel::Timer Report -- Total time: 0.1557 secs
    Interval  Time    Percent
    ----------------------------------------------
    00 -> 01  0.1458  93.62%  INIT -> old way
    01 -> 02  0.0099   6.38%  old way -> new way

It comes with a handy  script  C<kwalitee-report>, which can be used to query the
kwalitee scores of any distribution.

    $ kwalitee-score --dist=Map::Tube

More detailed options shown below:

    $ kwalitee-report -h
    USAGE: kwalitee-report [-hn] [long options...]

         --dist=String              Distribution name to generate Kwalitee
                                    report.
         --metrics                  Show CPANTS Kwalitee metrics.
         --recently_uploaded_dists  Lookup recently uploaded distributions.
         -n=Int                     Distribution count to generate Kwalitee
                                    report. Default is 5.
         --verbose                  Be more descriptive. Default is OFF.

         --usage                    show a short help message
         -h                         show a compact help message
         --help                     show a long help message
         --man                      show the manual

=head1 SYNOPSIS

    use strict; use warnings;
    use CPANTS::Kwalitee::Report;

    my $report = CPANTS::Kwalitee::Report->new;

    # Individual distribution kwalitee scores.
    print $report->scores('Map::Tube');

    # Recently uploaded last 3 distributions scores.
    my $dists = $report->recently_uploaded_distributions(3);
    print join("\n------\n", @$dists);

=head1 METHODS

=head2 kwalitee()

Returns an object of type L<Module::CPANTS::Kwalitee>.

=head2 get_generators()

Returns an array ref of objects of type L<CPANTS::Kwalitee::Report::Generator>.

=cut

sub get_generators {
    my ($self) = @_;

    unless (defined $self->{generators}) {
        $self->fetch_generators;
    }

    return $self->{generators};
}

=head2 get_indicators()

Returns an array ref of objects of type L<CPANTS::Kwalitee::Report::Indicator>.

=cut

sub get_indicators {
    my ($self) = @_;

    unless (defined $self->{indicators}) {
        $self->fetch_generators;
    }

    return [ values %{$self->{indicators}} ];
}

=head2 get_indicator($name)

Returns an object of type L<CPANTS::Kwalitee::Report::Indicator>.

=cut

sub get_indicator {
    my ($self, $name) = @_;

    unless (defined $self->{indicators}) {
        $self->fetch_generators;
    }

    return $self->{indicators}->{$name};
}

=head2 recently_uploaded_distributions($count)

Returns an array ref of objects of type L<CPANTS::Kwalitee::Report::Distribution>
with no more than C<$count> members.

=cut

sub recently_uploaded_distributions {
    my ($self, $count) = @_;

    if (defined $count) {
        if ($count < 0) {
            $count = $MIN_COUNT;
        }
        elsif ($count > $MAX_COUNT) {
            $count = $MAX_COUNT;
        }
    }

    my $r_dist = [];
    my $seen   = {};
    my $feed   = $self->rss->parse_string($self->recent);
    foreach my $item ($feed->query('//item')) {
        my $link = $item->query('link')->text_content;
        my $path = sprintf("%s.tar.gz", $link);
        my $cpan = CPAN::DistnameInfo->new($path);
        my $dist = $cpan->dist;
        next if (exists $seen->{$dist} || exists $self->{recent_dists}->{$dist});

        $seen->{$dist} = 1;
        $self->{recent_dists}->{$dist} = $path;
        push @$r_dist, { dist => $dist, path => $path, link => $link };

        if (defined $count && (scalar(keys %{$self->{recent_dists}}) == $count)) {
            last;
        }
    }

    my $dists = [];
    foreach my $d (@$r_dist) {
        push @$dists, $self->scores($d->{dist}, $d->{path}, $d->{link});
    }

    return $dists;
}

=head2 scores($dist_name, [$dist_path], [$dist_link])

Returns an object of type L<CPANTS::Kwalitee::Report::Distribution>.

=cut

sub scores {
    my ($self, $dist_name, $dist_path, $dist_link) = @_;

    die "ERROR: Missing distribution name.\n" unless (defined $dist_name);

    $dist_name = _format_dist_name($dist_name);
    $dist_path = $self->get_dist_path($dist_name) unless (defined $dist_path);
    my $analyser = Module::CPANTS::Analyse->new({ distdir => $dist_path, dist => tempdir(CLEANUP => 1) });
    $analyser->run;

    my $scores = [];
    foreach my $name (keys %{$analyser->d->{kwalitee}}) {
        my $indicator = $self->get_indicator($name);
        if (defined $indicator) {
            push @$scores, CPANTS::Kwalitee::Report::Score->new(
                {
                    indicator => $indicator,
                    value     => $analyser->d->{kwalitee}->{$name},
                });
        }
    }

    return CPANTS::Kwalitee::Report::Distribution->new(
        { name   => $dist_name,
          path   => $dist_path,
          link   => $dist_link,
          scores => $scores
        });
}

#
#
# PRIVATE METHODS

sub get_dist_path {
    my ($self, $dist_name) = @_;

    foreach my $dist (keys %{$self->{recent_dists}}) {
        if (exists $self->{recent_dists}->{$dist_name}) {
            return $self->{recent_dists}->{$dist_name};
        }
    }

    # Can't find it, look into pause index file now.
    my $parser = $self->parser;
    unless (defined $parser) {
        $parser = Parse::CPAN::Packages->new($self->index);
        $self->parser($parser);
    }

    my $dist = $parser->latest_distribution($dist_name);
    die "ERROR: Unable to locate distribution $dist_name.\n" unless (defined $dist);

    $self->{recent_dists}->{$dist_name} = $dist->{prefix};

    return $dist->{prefix};
}

sub fetch_generators {
    my ($self) = @_;

    my $generators = [];
    my $indicators = {};
    my $verbose    = $self->verbose;
    my $kwalitee   = $self->kwalitee;
    foreach my $generator (@{$kwalitee->generators}) {
        my $g_indicators = [];
        foreach my $indicator (@{$generator->kwalitee_indicators}) {
            my @types  = grep { exists $indicator->{$_} } qw(is_extra is_experimental needs_db);
            my $indicator_name = $indicator->{name};
            my $object = CPANTS::Kwalitee::Report::Indicator->new(
                {
                    name    => $indicator_name,
                    types   => \@types,
                    error   => $indicator->{error},
                    remedy  => $indicator->{remedy},
                    verbose => $verbose,
                }
            );

            push @$g_indicators, $object;
            $indicators->{$indicator_name} = $object;
        }

        push @$generators,
        CPANTS::Kwalitee::Report::Generator->new(
            {
                name       => $generator,
                version    => $generator->VERSION,
                indicators => $g_indicators,
                verbose    => $verbose,
            });
    }

    $self->{generators} = $generators;
    $self->{indicators} = $indicators;
}

sub _format_dist_name {
    my ($name) = @_;

    $name =~ s/\:\:/\-/g;
    return $name;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/CPANTS-Kwalitee-Report>

=head1 SEE ALSO

=over 4

=item L<Module::CPANTS::Analyse>

=item L<Test::Kwalitee>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpants-kwalitee-report at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANTS-Kwalitee-Report>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANTS::Kwalitee::Report

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPANTS-Kwalitee-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPANTS-Kwalitee-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPANTS-Kwalitee-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/CPANTS-Kwalitee-Report/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of CPANTS::Kwalitee::Report
