package Bio::JBrowse::Store::NCList::IntervalStore;
BEGIN {
  $Bio::JBrowse::Store::NCList::IntervalStore::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::JBrowse::Store::NCList::IntervalStore::VERSION = '0.1';
}
use strict;
use warnings;
use Carp;

use POSIX ();
use List::Util ();

use Bio::JBrowse::Store::NCList::LazyNCList ();


sub new {
    my ($class, $args) = @_;

    my $self = {
                store => $args->{store} || die,

                compress => $args->{compress},

                attrs => $args->{arrayRepr},
                urlTemplate => $args->{urlTemplate} || ("lf-{Chunk}"
                                                        . $args->{store}->ext),
                nclist => $args->{nclist},
                minStart => $args->{minStart},
                maxEnd => $args->{maxEnd},
                loadedChunks => {}
               };

    if( defined $args->{nclist} ) {
        # we're already loaded
        $self->{lazyNCList} =
          Bio::JBrowse::Store::NCList::LazyNCList->importExisting(
              $self->{attrs},
              $args->{count},
              $args->{minStart},
              $args->{maxEnd},
              sub { $self->_loadChunk( @_ ); },
              $args->{nclist} );
    }

    bless $self, $class;

    return $self;
}

sub _loadChunk {
    my ($self, $chunkId) = @_;
    my $chunk = $self->{loadedChunks}->{$chunkId};
    if (defined($chunk)) {
        return $chunk;
    } else {
        (my $path = $self->{urlTemplate}) =~ s/\{Chunk\}/$chunkId/g;
        $chunk = $self->{store}->get( $path );
        # TODO limit the number of chunks that we keep in memory
        $self->{loadedChunks}->{$chunkId} = $chunk;
        return $chunk;
    }
}


sub startLoad {
    my ( $self, $measure, $chunkBytes ) = @_;

    if (defined($self->{nclist})) {
        confess "loading into an already-loaded Bio::JBrowse::Store::NCList::IntervalStore";
    } else {
        my $lazyClass = $self->{attrs}->getClass( { start => 1, end => 2, chunk => 3 } );
        $self->{lazyClass} = $lazyClass->{index};

        # add a new class for "fake" features
        my $makeLazy = sub {
            my ($start, $end, $chunkId) = @_;
            my $f = { start => $start, end => $end, chunk => $chunkId };
            return [ $lazyClass->{index}, map { $f->{$_} } @{$lazyClass->{attributes}} ];
        };
        my $output = sub {
            my ($toStore, $chunkId) = @_;
            (my $path = $self->{urlTemplate}) =~ s/\{Chunk\}/$chunkId/ig;
            $self->{store}->put($path, $toStore);
        };
        $self->{lazyNCList} =
          Bio::JBrowse::Store::NCList::LazyNCList->new( $self->{attrs},
                          $self->{lazyClass},
                          $makeLazy,
                          sub { $self->_loadChunk( @_); },
                          $measure,
                          $output,
                          $chunkBytes);
    }
}


sub addSorted {
    my ($self, $feat) = @_;
    $self->{lazyNCList}->addSorted($feat);
}


sub finishLoad {
    my ($self) = @_;
    $self->{lazyNCList}->finish();
    $self->{nclist} = $self->lazyNCList->topLevelList();

    my $trackData = {
        featureCount => $self->count,
        intervals => $self->descriptor,
        histograms => $self->writeHistograms,
        formatVersion => 1
        };

    $self->store->put( 'trackData.'.( $self->{compress} ? 'jsonz' : 'json' ), $trackData);

}

sub writeHistograms {
    my ( $self ) = @_;
    #this series of numbers is used in JBrowse for zoom level relationships
    my @multiples = (1, 2, 5, 10, 20, 50, 100, 200, 500,
                     1000, 2000, 5000, 10_000, 20_000, 50_000,
                     100_000, 200_000, 500_000, 1_000_000);
    my $histChunkSize = 10_000;

    my $attrs = $self->{attrs};
    my $getStart = $attrs->makeGetter("start");
    my $getEnd = $attrs->makeGetter("end");

    my $jsonStore = $self->store;
    my $refEnd = $self->lazyNCList->maxEnd || 0;
    my $featureCount = $self->count;

    # $histBinThresh is the approximate the number of bases per
    # histogram bin at the zoom level where FeatureTrack.js switches
    # to the histogram view by default
    my $histBinThresh = $featureCount ? ($refEnd * 2.5) / $featureCount : 999_999_999_999;
    my $histBinBases  = ( List::Util::first { $_ > $histBinThresh } @multiples ) || $multiples[-1];

    # initialize histogram arrays to all zeroes
    my @histograms;
    for (my $i = 0; $i < @multiples; $i++) {
        my $binBases = $histBinBases * $multiples[$i];
        $histograms[$i] = [(0) x POSIX::ceil($refEnd / $binBases)];
        # somewhat arbitrarily cut off the histograms at 100 bins
        last if $binBases * 100 > $refEnd;
    }

    my $processFeat = sub {
        my ($feature) = @_;
        my $curHist;
        my $start = List::Util::max(0, List::Util::min($getStart->($feature), $refEnd));
        my $end = List::Util::min($getEnd->($feature), $refEnd);
        return if ($end < 0);

        for (my $i = 0; $i <= $#multiples; $i++) {
            my $binBases = $histBinBases * $multiples[$i];
            $curHist = $histograms[$i];
            last unless defined($curHist);

            my $firstBin = int($start / $binBases);
            my $lastBin = int($end / $binBases);
            for (my $bin = $firstBin; $bin <= $lastBin; $bin++) {
                $curHist->[$bin] += 1;
            }
        }
    };

    $self->overlapCallback($self->lazyNCList->minStart,
                           $self->lazyNCList->maxEnd,
                           $processFeat);

    # find multiple of base hist bin size that's just over $histBinThresh
    my $i;
    for ($i = 1; $i <= $#multiples; $i++) {
        last if ($histBinBases * $multiples[$i]) > $histBinThresh;
    }

    my @histogramMeta;
    my @histStats;
    for (my $j = $i - 1; $j <= $#multiples; $j += 1) {
        my $curHist = $histograms[$j];
        last unless defined($curHist);
        my $histBases = $histBinBases * $multiples[$j];

        my $chunks = $self->chunkArray($curHist, $histChunkSize);
        for (my $k = 0; $k <= $#{$chunks}; $k++) {
            $jsonStore->put("hist-$histBases-$k" . $jsonStore->ext,
                            $chunks->[$k]);
        }
        push @histogramMeta,
            {
                basesPerBin => $histBases,
                arrayParams => {
                    length => $#{$curHist} + 1,
                    urlTemplate => "hist-$histBases-{Chunk}" . $jsonStore->ext,
                    chunkSize => $histChunkSize
                }
            };
        push @histStats,
            {
                'basesPerBin' => $histBases,
                'max'  => @$curHist ? List::Util::max( @$curHist ) : undef,
                'mean' => @$curHist ? ( List::Util::sum( @$curHist ) / @$curHist ) : undef,
            };
    }

    return { meta => \@histogramMeta,
             stats => \@histStats };
}


sub chunkArray {
    my ( $self, $bigArray, $chunkSize) = @_;

    my @result;
    for (my $start = 0; $start <= $#{$bigArray}; $start += $chunkSize) {
        my $lastIndex = $start + $chunkSize;
        $lastIndex = $#{$bigArray} if $lastIndex > $#{$bigArray};

        push @result, [@{$bigArray}[$start..$lastIndex]];
    }
    return \@result;
}



sub overlapCallback {
    my ($self, $start, $end, $cb) = @_;
    $self->lazyNCList->overlapCallback($start, $end, $cb);
}


sub lazyNCList   { shift->{lazyNCList}        }
sub count        { shift->{lazyNCList}->count }
sub hasIntervals { shift->count > 0           }
sub store        { shift->{store}             }


sub descriptor {
    my ( $self ) = @_;
    return {
            lazyClass => $self->{lazyClass},
            nclist => $self->{nclist},
            classes => $self->{attrs}->descriptor,
            urlTemplate => $self->{urlTemplate},
            count => $self->count,
            minStart => $self->lazyNCList->minStart,
            maxEnd => $self->lazyNCList->maxEnd
           };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::JBrowse::Store::NCList::IntervalStore

=head1 SYNOPSIS

  my $is = Bio::JBrowse::Store::NCList::IntervalStore->new({
               urlTemplate => "lf-{Chunk}.jsonz",
           });
  my $chunkBytes = 80_000;
  $is->startLoad( $measure, $chunkBytes );
  $is->addSorted([10, 100, -1])
  $is->addSorted([50, 80, 1])
  $is->addSorted([90, 150, -1])
  $is->finishLoad();
  $is->overlap(60, 85)

  => ([10, 100, -1], [50, 80, 1])

=head1 NAME

Bio::JBrowse::Store::NCList::IntervalStore - stores a set of intervals
(genomic features) in an on-disk lazy nested-containment list

=head1 METHODS

=head2 new

 Title   : new
 Usage   : Bio:JBrowse::Store::NCList::IntervalStore->new(
               arrayRepr => {attributes => ["start", "end", "strand"]},
           )
 Function: create a new store
 Returns : an Bio::JBrowse::Store::NCList::IntervalStore object
 Args    : The Bio::JBrowse::Store::NCList::IntervalStore constuctor accepts the named parameters:
           store: optional object with put(path, data) method, will be used to output
                  feature data
           compress: if true, attempt to compress the data on disk
           arrayRepr: Bio::JBrowse::Store::NCList::ArrayRepr object used to represent the feature data
           urlTemplate (optional): template for URLs where chunks of feature
                                   data will be stored.  This is relative to
                                   the directory with the "trackData.json" file
           nclist (optional): the root of the nclist
           count (optional): the number of intervals in this Bio::JBrowse::Store::NCList::IntervalStore
           minStart (optional): the earliest interval start point
           maxEnd (optional): the latest interval end point

           If this Bio::JBrowse::Store::NCList::IntervalStore hasn't been loaded yet, the optional
           parameters aren't necessary.  But to access a previously-loaded
           Bio::JBrowse::Store::NCList::IntervalStore, the optional parameters *are* needed.

=head2 startLoad( $measure, $chunkBytes )

=head2 addSorted( \@feature )

=head2 finishLoad()

=head2 overlapCallback( $from, $to, \&func )

Calls the given function once for each of the intervals that overlap
the given interval if C<<$from <= $to>>, iterates left-to-right, otherwise
iterates right-to-left.

=head2 descriptor

 Title   : descriptor
 Usage   : $list->descriptor
 Returns : a hash containing the data needed to re-construct this
           Bio::JBrowse::Store::NCList::IntervalStore, including the
           root of the NCList plus some metadata and configuration.
           The return value can be passed to the constructor later.

=head1 AUTHOR

Mitchell Skinner E<lt>jbrowse@arctur.usE<gt>

Copyright (c) 2007-2011 The Evolutionary Software Foundation

This package and its accompanying libraries are free software; you can
redistribute it and/or modify it under the terms of the LGPL (either
version 2.1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text.

=head1 AUTHOR

Robert Buels <rbuels@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
