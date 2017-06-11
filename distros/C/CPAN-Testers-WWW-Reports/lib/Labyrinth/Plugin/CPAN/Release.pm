package Labyrinth::Plugin::CPAN::Release;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '3.59';

=head1 NAME

Labyrinth::Plugin::CPAN::Release - Plugin to handle the release summary table

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DTUtils;
use Labyrinth::Variables;

use Labyrinth::Plugin::CPAN;

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 METHODS

=head2 Public Interface Methods

=over 4

=item Create

Create any missing entries. This is only expected to be run during initial
build of the table. Once summation occurs, this becomes redundant.

=item Update

Update table release_summary.

=item Rebuild

For a give distribution and version, rebuild all related entries within
the release_summary table.

=item Fix

For all distributions and versions, rebuild all related entries within
the release_summary table.

=back

=cut

sub Create {
    my ($self,$progress) = @_;
    $progress->( "Create START" )     if(defined $progress);

    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    my @rmax = $dbi->GetQuery('array','GetReportMax');
    my $rmax = @rmax ? ($rmax[0]->[0] || 0) : 0;
    my @dmax = $dbi->GetQuery('array','GetReleaseDataMax');
    my $dmax = @dmax ? ($dmax[0]->[0] || 0) : 0;

    my $id = 0;
    my $step = 1000000;
    my ($from,$to) = ($dmax,$step + $dmax);
    while(1) {
        my $changes = 0;
        my @summ = $dbi->GetQuery('hash','GetSummaryBlock',$from,$to);
        my %summ = map {$_->{id} => 1} @summ;
        my $next = $dbi->Iterator('hash','GetReportBlock',$from,$to);
        while( my $row = $next->() ) {
            $id = $row->{id};
            if($summ{$row->{id}}) {
                #$progress->( ".. processing $row->{id}" )     if(defined $progress);
                next;
            }

            $progress->( ".. inserting $row->{id} for $row->{dist} - $row->{version} = " . $cpan->DistIndex($row->{dist},$row->{version}) )
                if(defined $progress);

            $dbi->DoQuery('InsertReleaseData',
                $row->{dist},$row->{version},$row->{id},$row->{guid},

                $cpan->OnCPAN($row->{dist},$row->{version}) ? 1 : 2,

                $row->{version} =~ /_/        ? 2 : 1,
                $row->{perl} =~ /^5.(7|9|[1-9][13579])/ ? 2 : 1,
                $row->{perl} =~ /patch/       ? 2 : 1,

                $row->{state} eq 'pass'    ? 1 : 0,
                $row->{state} eq 'fail'    ? 1 : 0,
                $row->{state} eq 'na'      ? 1 : 0,
                $row->{state} eq 'unknown' ? 1 : 0,

                $cpan->DistIndex($row->{dist},$row->{version}));

                $changes++;
        }

        last    unless($id < $rmax);

        $from += $step;
        $to   += $step;
    }

    $progress->( "Create STOP" )     if(defined $progress);
}

sub Update {
    my ($self,$progress) = @_;
    $progress->( "Update START" )     if(defined $progress);

    my @dmax = $dbi->GetQuery('array','GetReleaseDataMax');
    my $dmax = @dmax ? ($dmax[0]->[0] || 0) : 0;
    my @smax = $dbi->GetQuery('array','GetReleaseSummaryMax');
    my $smax = @smax ? ($smax[0]->[0] || 0) : 0;

    $progress->( ".. summary max=$smax, data max=$dmax" )     if(defined $progress);

    if($dmax && $smax < $dmax) {
        # In case we have several hundred thousand or millions of release data
        # entries to get through, we only process a block at a time. This means
        # we don't use up too much memory with %summ and make progress in case
        # the process dies.

        my $step = 1000000;
        my ($from,$to) = ($smax,($smax+$step));
        while(1) {
            $progress->( ".. from=$from, to=$to" )  if(defined $progress);
            my %summ;
            my $next = $dbi->Iterator('array','GetReleaseData',$from,$to);
            while( my $row = $next->() ) {
                $progress->( ".. .. processing $row->[2]" )     if(defined $progress);
                $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{id}        = $row->[2];
                $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{guid}      = $row->[3];
                $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{pass}     += $row->[8];
                $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{fail}     += $row->[9];
                $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{na}       += $row->[10];
                $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{unknown}  += $row->[11];
                $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{uploadid}  = $row->[12];
            }

            for my $dist (keys %summ) {
            for my $vers (keys %{$summ{$dist}}) {
                for my $key1 (keys %{ $summ{$dist}{$vers} }) {
                for my $key2 (keys %{ $summ{$dist}{$vers}{$key1} }) {
                for my $key3 (keys %{ $summ{$dist}{$vers}{$key1}{$key2} }) {
                for my $key4 (keys %{ $summ{$dist}{$vers}{$key1}{$key2}{$key3} }) {
                    $progress->( ".. processing [$dist,$vers,$key1,$key2,$key3,$key4] = " .
		    		 "$summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id}" )     if(defined $progress);
                    my @rows = $dbi->GetQuery('hash','GetReleaseSummary',$dist,$vers,$key1,$key2,$key3,$key4);
#                    if(scalar(@rows) > 1) {
#	         #use Data::Dumper;
#            #$progress->( ".. rows=".Dumper(\@rows) )  if(defined $progress);
#            #$progress->( ".. summ=".Dumper($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}) )  if(defined $progress);
#                        for my $row (@rows) {
#                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{pass}    += $row->{pass};
#                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{fail}    += $row->{fail};
#                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{na}      += $row->{na};
#                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{unknown} += $row->{unknown};
#                        }
#
#                        $dbi->DoQuery('DeleteReleaseSummary',$dist,$vers,$key1,$key2,$key3,$key4);
#
#                        $dbi->DoQuery('InsertReleaseSummary',
#                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id},
#                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{guid},
#                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{pass}     || 0),
#                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{fail}     || 0),
#                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{na}       || 0),
#                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{unknown}  || 0),
#                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{uploadid} || 0),
#                            $dist,$vers,$key1,$key2,$key3,$key4);
#
#                    } elsif(scalar(@rows) > 0) {
                    if(scalar(@rows) > 0) {
	        #use Data::Dumper;
            #$progress->( ".. rows=".Dumper(\@rows) )  if(defined $progress);
            #$progress->( ".. summ=".Dumper($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}) )  if(defined $progress);

                        $dbi->DoQuery('UpdateReleaseSummary',
                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id},
                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{guid},
                            ($rows[0]->{pass}    + ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{pass}    || 0)),
                            ($rows[0]->{fail}    + ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{fail}    || 0)),
                            ($rows[0]->{na}      + ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{na}      || 0)),
                            ($rows[0]->{unknown} + ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{unknown} || 0)),
                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{uploadid} || 0),
                            $dist,$vers,$key1,$key2,$key3,$key4);
                    } else {
                        $dbi->DoQuery('InsertReleaseSummary',
                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id},
                            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{guid},
                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{pass}     || 0),
                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{fail}     || 0),
                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{na}       || 0),
                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{unknown}  || 0),
                            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{uploadid} || 0),
                            $dist,$vers,$key1,$key2,$key3,$key4);
                    }
                }
                }
                }
                }
            }
            }

            last    unless($to < $dmax);

            $from += $step;
            $to   += $step;
        }
    }

    $progress->( "Update STOP" )     if(defined $progress);
}

sub Rebuild {
    my ($self,$progress,$dist,$vers) = @_;
    $progress->( "Rebuild START [$dist-$vers]" )     if(defined $progress);

    my %summ;
    my $next = $dbi->Iterator('array','GetReleaseDataByDistVers',$dist,$vers);
    while( my $row = $next->() ) {
        $progress->( ".. .. processing $row->[2]" )     if(defined $progress);
        $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{id}        = $row->[2];
        $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{guid}      = $row->[3];
        $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{pass}     += $row->[8];
        $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{fail}     += $row->[9];
        $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{na}       += $row->[10];
        $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{unknown}  += $row->[11];
        $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{uploadid}  = $row->[12];
    }
    $dbi->DoQuery('DeleteReleaseSummaryByDistVers',$dist,$vers);
    for my $key1 (keys %{ $summ{$dist}{$vers} }) {
    for my $key2 (keys %{ $summ{$dist}{$vers}{$key1} }) {
    for my $key3 (keys %{ $summ{$dist}{$vers}{$key1}{$key2} }) {
    for my $key4 (keys %{ $summ{$dist}{$vers}{$key1}{$key2}{$key3} }) {
        $progress->( ".. processing [$dist,$vers,$key1,$key2,$key3,$key4] = " .
            "$summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id}" )     if(defined $progress);
        $dbi->DoQuery('InsertReleaseSummary',
            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id},
            $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{guid},
            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{pass}     || 0),
            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{fail}     || 0),
            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{na}       || 0),
            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{unknown}  || 0),
            ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{uploadid} || 0),
            $dist,$vers,$key1,$key2,$key3,$key4);
    }
    }
    }
    }

    $progress->( "Rebuild STOP" )   if(defined $progress);
}

sub Fix {
    my ($self,$progress) = @_;
    $progress->( "Fix START" )      if(defined $progress);

    my @rs = $dbi->Iterator('hash','GetReleaseDists');
    for my $rs (@rs) {
        my %summ;
        my $next = $dbi->Iterator('array','GetReleaseDataByDist',$rs->{dist});
        while( my $row = $next->() ) {
            $progress->( ".. .. processing $row->[2]" )     if(defined $progress);
            $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{id}        = $row->[2];
            $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{guid}      = $row->[3];
            $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{pass}     += $row->[8];
            $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{fail}     += $row->[9];
            $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{na}       += $row->[10];
            $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{unknown}  += $row->[11];
            $summ{$row->[0]}{$row->[1]}{$row->[4]}{$row->[5]}{$row->[6]}{$row->[7]}{uploadid}  = $row->[12];
        }

        $dbi->DoQuery('DeleteReleaseSummaryByDist',$rs->{dist});

        for my $dist (keys %summ) {
        for my $vers (keys %{$summ{$dist}}) {
            for my $key1 (keys %{ $summ{$dist}{$vers} }) {
            for my $key2 (keys %{ $summ{$dist}{$vers}{$key1} }) {
            for my $key3 (keys %{ $summ{$dist}{$vers}{$key1}{$key2} }) {
            for my $key4 (keys %{ $summ{$dist}{$vers}{$key1}{$key2}{$key3} }) {
                $progress->( ".. processing [$dist,$vers,$key1,$key2,$key3,$key4] = " .
                    "$summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id}" )     if(defined $progress);
                $dbi->DoQuery('InsertReleaseSummary',
                    $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{id},
                    $summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{guid},
                    ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{pass}     || 0),
                    ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{fail}     || 0),
                    ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{na}       || 0),
                    ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{unknown}  || 0),
                    ($summ{$dist}{$vers}{$key1}{$key2}{$key3}{$key4}{uploadid} || 0),
                    $dist,$vers,$key1,$key2,$key3,$key4);
            }
            }
            }
            }
        }
        }
    }

    $progress->( "Fix STOP" )   if(defined $progress);
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2017 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
