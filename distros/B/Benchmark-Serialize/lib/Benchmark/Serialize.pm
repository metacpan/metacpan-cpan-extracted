package Benchmark::Serialize;

use strict;
use warnings;

=head1 NAME

Benchmark::Serialize - Benchmarks of serialization modules

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Benchmark::Serialize qw(cmpthese);

    my $structure = {
        array  => [ 'a' .. 'j' ],
        hash   => { 'a' .. 'z' },
        string => 'x' x 200,
    };

    cmpthese( -5, $structure, qw(:core :json :yaml) );

=head1 DESCRIPTION

This module encapsulates some basic benchmarks to help you choose a module
for serializing data. Note that using this module is only a part of chosing a
serialization format. Other factors than the benchmarked might be of
relevance!

Included is support for 24 different serialization modules. Also supported
is the Data::Serializer wrapper providing a unified interface for
serialization and some extra features. Benchmarking of specialized modules
made with Protocol Buffers for Perl/XS (protobuf-perlxs) is also available.

=head2 Functions

This module provides the following functions

=over 5

=item cmpthese(COUNT, STRUCTURE, BENCHMARKS ...)

Benchmark COUNT interations of a list of modules. A benchmark is either a name
of a supported module, a tag, or a hash ref containing at least an inflate, a
deflate, and a name attribute:

  {
      name    => 'JSON::XS',
      deflate => sub { JSON::XS::encode_json($_[0]) }
      inflate => inflate  => sub { JSON::XS::decode_json($_[0]) }
  }

By default Benchmark::Serialize will try to use the name attribute as a module
to be loaded. This can be overridden by having a packages attribute with an
arrayref containing modules to be loaded.

=back

=head2 Benchmark tags

The following tags are supported

=over 5

=item :all     - All modules with premade benchmarks 

=item :default - A default set of serialization modules

=item :core    - Serialization modules included in core

=item :json    - JSON modules

=item :yaml    - YAML modules

=item :xml     - XML formats

=back

=cut

use Benchmark          qw[timestr];
use Test::Deep::NoTest;

use Benchmark::Serialize::Library;

use Exporter qw(import);
our @EXPORT_OK   = qw( cmpthese );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $benchmark_deflate  = 1;       # boolean
our $benchmark_inflate  = 1;       # boolean
our $benchmark_roundtrip= 1;       # boolean
our $benchmark_size     = 1;       # boolean
our $verbose            = 0;       # boolean
our $output             = 'chart'; # chart or list

sub cmpthese {
    my $iterations = shift;
    my $structure  = shift;
    my @benchmarks = Benchmark::Serialize::Library->load( @_ );

    my $width   = width(map { $_->name } @benchmarks);
    my $results = { };

    print "\nModules\n";

    BENCHMARK:

    foreach my $benchmark ( sort { $a->name cmp $b->name } @benchmarks ) {
	my $name = $benchmark->name;

        my ($deflated, $inflated);
        eval {
            $deflated = $benchmark->deflate($structure);
            $inflated = $benchmark->inflate($deflated);
            1;
        } or do {
            warn "Benchmark $name died with:\n    $@\n";
            next BENCHMARK;
        };
    
        my ($likeliness, $diag) = likeliness( $inflated, $structure );
        printf( "%-${width}s : %8s %s\n", $benchmark->name, $benchmark->version, $likeliness);

        print Test::Deep::deep_diag($diag), "\n" if defined($diag) and $Benchmark::Serialize::verbose;

        $results->{deflate}->{$name} = timeit_deflate( $iterations, $structure, $benchmark )
            if $benchmark_deflate;

        $results->{inflate}->{$name} = timeit_inflate( $iterations, $structure, $benchmark )
            if $benchmark_inflate;

        $results->{roundtrip}->{$name} = timeit_roundtrip( $iterations, $structure, $benchmark )
            if $benchmark_roundtrip;

        $results->{size}->{$name}    = length( $deflated );
    }

    output( 'Sizes', "size", $output, $results->{size}, $width )
        if $benchmark_size;

    output( 'Deflate (perl -> serialized)', "time", $output, $results->{deflate}, $width )
        if $benchmark_deflate;

    output( 'Inflate (serialized -> perl)', "time", $output, $results->{inflate}, $width )
        if $benchmark_inflate;

    output( 'Roundtrip', "time", $output, $results->{roundtrip}, $width )
        if $benchmark_roundtrip;
}

sub output {
    my $title  = shift;
    my $type   = shift;
    my $output = shift;
    printf( "\n%s\n", $title );
    if ( $type eq "size" ) {
        ($output eq "list") ? &size_list : &size_chart ; 
    } elsif ( $type eq "time" ) {
        ($output eq "list") ? &time_list : &time_chart ; 

    } else {
        warn("Unknown data type: $type");
    }
}

sub time_chart {
    my $results = shift;
    Benchmark::cmpthese($results);
}

sub time_list {
    my $results = shift;
    my $width   = shift;
    foreach my $title ( sort keys %{ $results } ) {
        printf( "%-${width}s %s\n", $title, timestr( $results->{ $title } ) );
    }
}

sub size_chart {
    my $results = shift;
    my @vals    = sort { $a->[1] <=> $b->[1] } map { [ $_, $results->{$_} ] } keys %$results;

    my @rows    = ( [
        '',
        'bytes',
        map { $_->[0] } @vals,
    ] );

    my @col_width = map { length ( $_ ) } @{ $rows[0] };

    for my $row_val ( @vals ) {
        my @row;

        push @row, $row_val->[0], $row_val->[1];
        $col_width[0] = ( length ( $row_val->[0] ) > $col_width[0] ? length( $row_val->[0] ) : $col_width[0] );
        $col_width[1] = ( length ( $row_val->[1] ) > $col_width[1] ? length( $row_val->[1] ) : $col_width[1] );

        # Columns 2..N = performance ratios
        for my $col_num ( 0 .. $#vals ) {
            my $col_val = $vals[$col_num];
            my $out;

            if ( $col_val->[0] eq $row_val->[0] ) {
                $out = "--";
            } else {
                $out = sprintf( "%.0f%%", 100*$row_val->[1]/$col_val->[1] - 100 );
            }

            push @row, $out;
            $col_width[$col_num+2] = ( length ( $out ) > $col_width[$col_num+2] ? length ( $out ) : $col_width[$col_num+2]);
        }
        push @rows, \@row;
    }

    # Pasted from Benchmark.pm
    # Equalize column widths in the chart as much as possible without
    # exceeding 80 characters.  This does not use or affect cols 0 or 1.
    my @sorted_width_refs = 
       sort { $$a <=> $$b } map { \$_ } @col_width[2..$#col_width];
    my $max_width = ${$sorted_width_refs[-1]};

    my $total = @col_width - 1 ;
    for ( @col_width ) { $total += $_ }

    STRETCHER:
    while ( $total < 80 ) {
        my $min_width = ${$sorted_width_refs[0]};
        last
           if $min_width == $max_width;
        for ( @sorted_width_refs ) {
            last 
                if $$_ > $min_width;
            ++$$_;
            ++$total;
            last STRETCHER
                if $total >= 80;
        }
    }

    # Dump the output
    my $format = join( ' ', map { "%${_}s" } @col_width ) . "\n";
    substr( $format, 1, 0 ) = '-';
    for ( @rows ) {
        printf $format, @$_;
    }
}

sub size_list {
    my $results = shift;
    my $width   = shift;
    foreach my $title ( sort keys %{ $results } ) {
        printf( "%-${width}s : %d bytes\n", $title, $results->{ $title } );
    }
}

sub timeit_deflate {
    my ( $iterations, $structure, $benchmark ) = @_;
    return Benchmark::timethis( $iterations, sub { $benchmark->deflate($structure) }, '', 'none' );
}

sub timeit_inflate {
    my ( $iterations, $structure, $benchmark ) = @_;
    my $deflated = $benchmark->deflate($structure);
    return Benchmark::timethis( $iterations, sub { $benchmark->inflate($deflated) }, '', 'none' );
}

sub timeit_roundtrip {
    my ( $iterations, $structure, $benchmark ) = @_;
    return Benchmark::timethis( $iterations, sub { $benchmark->inflate( $benchmark->deflate( $structure )) }, '', 'none' );
}

sub width {
    return length( ( sort { length $a <=> length $b } @_ )[-1] );
}

sub likeliness {
    my ($got, $expected) = @_;
    my ($ok, $diag);

    ($ok, $diag) = Test::Deep::cmp_details( $got, $expected );
    return ("Identical", undef) if $ok;

    ($ok, $diag) = Test::Deep::cmp_details( $got, noclass($expected) );
    return ("Changes blessing", undef) if $ok;

    ($ok, $diag) = Test::Deep::cmp_details( $got, noclass(superhashof $expected) );
    return ("Adds content", undef) if $ok;

    ($ok, $diag) = Test::Deep::cmp_details( $got, noclass(subhashof $expected) );
    return ("Removes content", undef) if $ok;

    return ("Changes content", $diag);
}

=head1 RESULTS

See the README file for example results.

=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-serialize at
rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Serialize>.  I will
be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

This module started out as a script written by Christian Hansen, see 
http://idisk.mac.com/christian.hansen/Public/perl/serialize.pl

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
