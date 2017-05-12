# -*- indent-tabs-mode: nil -*-

package Bio::IlluminaSAV;

our $VERSION = '1.0.' . [qw$Revision: 9706 $]->[1];

=head1 NAME

Bio::IlluminaSAV - Parse Illumina SAV files


=head1 SYNOPSIS

Routines for parsing and extracting information from Illumina SAV files
(aka "InterOp").

    use IlluminaSAV;

    my $savs = IlluminaSAV->new("/path/to/rundirectory");
    my @qmetrics = $savs->quality_metrics();
    my $cur_cycle = $savs->cur_cycle();
    my $num_reads = $savs->num_reads();

=head1 DESCRIPTION

Easy access to Illumina's SAV file data.

=head1 AUTHOR

Andrew Hoerter & Erik Aronesty, E<lt>earonesty@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013  Erik Aronesty / Expression Analysis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;

use Module::Load;
use File::Spec;
use XML::LibXML::Reader;
use Cwd 'realpath';

our @ISA = qw(Exporter);

# list of default exports
our @EXPORT = qw( TILE_METRIC_CLUST_DENS
                  TILE_METRIC_PF_CLUST_DENS
                  TILE_METRIC_NUM_CLUSTERS
                  TILE_METRIC_NUM_PF_CLUSTERS
                  TILE_METRIC_CONTROL_LANE
                );

# be nicer
#our @EXPORT_OK = @EXPORT;
#our %EXPORT_TAGS = ( const => [ @EXPORT ] );

my %SAV_FORMAT = 
    (
     'ExtractionMetrics'   => [ ['lane',          'v', 1],
                                ['tile',          'v', 1],
                                ['cycle',         'v', 1],
                                ['fwhm',          'f', 4],  # FWHM scores for A/C/G/T in order
                                ['intensities',   'v', 4],  # intensities for A/C/G/T in order
                                ['cif_datestamp', 'V', 1], 
                                ['cif_timestamp', 'V', 1] ],

     'QualityMetrics'      => [ ['lane',          'v',  1],
                                ['tile',          'v',  1],
                                ['cycle',         'v',  1],
                                ['qscores',       'L', 50] ],  # number of clusters with quality Q1-Q50

     'ErrorMetrics'        => [ ['lane',           'v', 1],
                                ['tile',           'v', 1],
                                ['cycle',          'v', 1],
                                ['err_rate',       'f', 1],    
                                ['err_reads',      'L', 5] ],  # number of perfect reads, reads with 1 error,
                                                               # 2 errors, 3 errors, 4 errors in order

     'TileMetrics'         => [ ['lane',          'v', 1],
                                ['tile',          'v', 1],
                                ['metric',        'v', 1],     # metric codes are exported here as constants
                                ['metric_val',    'f', 1] ],

     'CorrectedIntMetrics' => [ ['lane',              'v', 1],
                                ['tile',              'v', 1],
                                ['cycle',             'v', 1],
                                ['avg_intensity',     'v', 1],
                                ['avg_corrected_int', 'v', 4],   # avg corrected intensity for A/C/G/T in order
                                ['avg_called_int',    'v', 4],   # as above, but only called clusters
                                ['num_basecalls',     'f', 5],   # number of basecalls for no-call/A/C/G/T in order 
                                ['snr',               'f', 1] ], # signal to noise ratio

     'ControlMetrics'      => [ ['lane',             'v',     1],
                                ['tile',             'v',     1],
                                ['read',             'v',     1],
                                ['control_name',     'v/A',   undef],
                                ['index_name',       'v/A',   undef],
                                ['control_clusters', 'L',     1] ],

     'ImageMetrics'        => [ ['lane',          'v', 1],
                                ['tile',          'v', 1],
                                ['cycle',         'v', 1],
                                ['channel_id',    'v', 1],     # 0=A, 1=C, 2=G, 3=T
                                ['min_contrast',  'v', 1],
                                ['max_contrast',  'v', 1] ]
    );

# old change in HCS?  Who knows.
$SAV_FORMAT{'QMetrics'} = $SAV_FORMAT{'QualityMetrics'};

my $XML_PARSER;

### Constants

=head1 CONSTANTS

    # constants you can use
    TILE_METRIC_CLUST_DENS
    TILE_METRIC_PF_CLUST_DENS
    TILE_METRIC_NUM_CLUSTERS
    TILE_METRIC_NUM_PF_CLUSTERS
    TILE_METRIC_CONTROL_LANE

=cut

use constant TILE_METRIC_CLUST_DENS      => 100;
use constant TILE_METRIC_PF_CLUST_DENS   => 101;
use constant TILE_METRIC_NUM_CLUSTERS    => 102;
use constant TILE_METRIC_NUM_PF_CLUSTERS => 103;
use constant TILE_METRIC_CONTROL_LANE    => 400;

### Helper subs

sub unpack_fmt
{
    my ($packrule) = @_;
    my ($type, $repeat) = ($packrule->[1], $packrule->[2]);
    
    return ($repeat ? $type . "[$repeat]" : $type);
}

### Class methods

=head1 FUNCTIONS

=over

=cut

# System-independent way of accessing stuff beneath a run directory
sub rundir_concat
{
    my ($self, @rest) = @_;
    my @rundir_dirs = File::Spec->splitdir($self->{'rundir'});

    return File::Spec->join(@rundir_dirs, @rest);
}

=item cur_cycle
Return the current run extraction cycle
=cut
sub cur_cycle
{
    my $self = shift;
    # Extraction metrics seems to be the most reliable source... it's available early on
    # even for GA-II's 
    my $ext_metrics = $self->extraction_metrics();
    my @cycles_sorted = sort { $b <=> $a } (map { $_->{'cycle'} } (@$ext_metrics));
    
    return $cycles_sorted[0];
}

=item cur_copy_cycle
Return the current copy cycle
=cut
sub cur_copy_cycle
{
    my $self = shift;
    my $glob_pat = $self->rundir_concat('Data', 'Intensities', 'BaseCalls', 'L001', 'C*.1');

    my @cycles_sorted = sort { $b <=> $a } (map { /C(\d+)\.1/ && $1; } (glob($glob_pat)));

    return (scalar(@cycles_sorted) == 0) ? 0 : $cycles_sorted[0];
}


=item max_cycles
Return the maximum number of cycles
=cut
sub max_cycles
{
    my $self = shift;

    my $sum = 0;
    my @readcycles = map { $_->{'numcycles'} } @{$self->run_info->{'reads'}};
    
    return undef
        unless @readcycles;

    foreach (@readcycles)
    {
        $sum += $_;
    }

    return $sum;
}

=item num_lanes
Return the number of lanes
=cut
sub num_lanes
{
    my $self = shift;

    return $self->run_info->{'numlanes'};
}

=item num_reads
Return the number of reads
=cut
sub num_reads
{
    my $self = shift;
    return scalar(@{$self->run_info->{'reads'}});
}

=item run_info
Returns a hash with RunInfo.xml info
=cut
sub run_info {
    my $self = shift;
    $self->{'runinfo'} = parse_runinfo($self->rundir_concat('RunInfo.xml'))
        unless (defined($self->{'runinfo'}));
    return $self->{'runinfo'};
}

=item extraction_metrics
Load extraction metrics 
=cut
sub extraction_metrics
{
    my $self = shift;

    return parse_sav_file($self->rundir_concat('InterOp', 'ExtractionMetricsOut.bin'));
}

=item quality_metrics
Load quality metrics 
=cut
sub quality_metrics
{
    my $self = shift;

    return parse_sav_file($self->rundir_concat('InterOp', 'QMetricsOut.bin'));
}

=item error_metrics
Load error metrics 
=cut
sub error_metrics
{
    my $self = shift;

    return parse_sav_file($self->rundir_concat('InterOp', 'ErrorMetricsOut.bin'));
}

=item tile_metrics
Load tile metrics 
=cut
sub tile_metrics
{
    my $self = shift;

    return parse_sav_file($self->rundir_concat('InterOp', 'TileMetricsOut.bin'));
}

=item corrected_int_metrics
Load corrected int metrics 
=cut
sub corrected_int_metrics
{
    my $self = shift;

    return parse_sav_file($self->rundir_concat('InterOp', 'CorrectedIntMetricsOut.bin'));
}

=item control_metrics
Load control metrics 
=cut
sub control_metrics
{
    my $self = shift;

    return parse_sav_file($self->rundir_concat('InterOp', 'ControlMetricsOut.bin'));
}

=item image_metrics
Load image metrics
=cut
sub image_metrics
{
    my $self = shift;

    return parse_sav_file($self->rundir_concat('InterOp', 'ImageMetricsOut.bin'));
}

### Functional interfaces

=item parse_sav_file(PATHNAME)
Load binary SAV-format file PATHNAME, inferring the type from the filename
=cut
sub parse_sav_file
{
    my ($path) = @_;
    my (undef, $dir, $file) = File::Spec->splitpath($path);
    my $type = $file;

    $type =~ s/(Out)?\.bin//;

    if ($type)
    {
        my $rec;
        my $unpackfmt;
        my @ret;
        my $sav_version;
        my $reclen;

        open(SAV, $path)   || return undef;
        read(SAV, $rec, 1) || return undef; 

        $sav_version = unpack('C', $rec);
        # ControlMetrics has variable sized records
        if ($type eq 'ControlMetrics')
        {
            $reclen = 0;
        }
        else
        {
            read(SAV, $rec, 1) || return undef; 

            $reclen = unpack('C', $rec);
        }

        local $/ = \$reclen;

        my @packrules = @{$SAV_FORMAT{$type}};
        return undef unless (@packrules);

        if ($reclen == 0)
        {
            # variable sized records
            $unpackfmt = "(" . join('', (map { unpack_fmt($_) } @packrules)) . ")*";
        }
        else
        {
            # static sized records
            $unpackfmt = join('', (map { unpack_fmt($_) } @packrules));
        }

        # for variable sized records, slurp in the whole file and unpack as a whole.
        # memory-inefficient, but these files are not particularly large.
        # for static sized records, go record-by-record.
        while ($rec = <SAV>)
        {
            my @unpacked = unpack($unpackfmt, $rec);

            while (@unpacked)
            {
                my $parsedrec = {};

                foreach my $packrule (@packrules)
                {
                    my ($fieldname, $len) = ($packrule->[0], $packrule->[2]);
                    
                    next if !defined($fieldname);
                    
                    if (defined($len) && $len > 1)
                    {
                        # return array ref
                        $parsedrec->{$fieldname} = [splice(@unpacked, 0, $len)];
                    }
                    else
                    {
                        # return scalar
                        $parsedrec->{$fieldname} = shift(@unpacked);
                    }
                }
                
                push @ret, $parsedrec;
            }
        }

        close(SAV);

       return \@ret;
    }
    
    return undef;
}

sub parse_runinfo
{
    my ($path) = @_;
    my $parsed_ctx;
    my $numlanes;
    my @reads;
    my %ret;

    $XML_PARSER = XML::LibXML->new(recover=>1)
        unless (defined($XML_PARSER));

    return undef unless ($XML_PARSER);

    $parsed_ctx = XML::LibXML::XPathContext->new($XML_PARSER->parse_file($path));
    return undef unless ($parsed_ctx);

    $numlanes = $parsed_ctx->findvalue('/RunInfo/Run/FlowcellLayout/@LaneCount');
    if (!$numlanes)
    {
        # some (all?) GAII's use a slightly different format to enumerate lanes
        my @lanes = $parsed_ctx->findnodes('/RunInfo/Run/Tiles/Lane');
        $numlanes = scalar(@lanes);
    }

    $ret{'numlanes'}   = $numlanes;
    $ret{'runid'}      = $parsed_ctx->findvalue('/RunInfo/Run/@Id');
    $ret{'run_num'}    = $parsed_ctx->findvalue('/RunInfo/Run/@Number');
    $ret{'fcid'}       = $parsed_ctx->findvalue('/RunInfo/Run/Flowcell')
                           or $parsed_ctx->findvalue('/RunInfo/Run/FlowcellId');
    $ret{'instrument'} = $parsed_ctx->findvalue('/RunInfo/Run/Instrument');
    $ret{'date'}       = $parsed_ctx->findvalue('/RunInfo/Run/Date');

    my $read_idx = 0;
    foreach my $read_ele ($parsed_ctx->findnodes('/RunInfo/Run/Reads/Read'))
    {
        my %parsed_read;

        $read_idx++;
        my $first_cycle = $read_ele->getAttribute('FirstCycle');
        my $last_cycle  = $read_ele->getAttribute('LastCycle');

        my $has_idx_child = $read_ele->exists('Index');
        my $idx_attr  = $read_ele->getAttribute('IsIndexedRead');

        # default values are for HiSeqs and MiSeqs
        $parsed_read{'readnum'}   = $read_ele->getAttribute('Number')    // $read_idx;
        $parsed_read{'numcycles'} = $read_ele->getAttribute('NumCycles') // (($last_cycle - $first_cycle) + 1);
        $parsed_read{'is_index'}  = ((defined($idx_attr)?$idx_attr:"") eq 'Y') || ($has_idx_child);

        push @{$ret{'reads'}}, \%parsed_read;
    }

    $ret{'reads'} = [sort { $a->{readnum} <=> $b->{readnum} } @{$ret{'reads'}}];
    my $first_cyc = 1;
    foreach my $read (@{$ret{'reads'}})
    {
        $read->{'first_cycle'} = $first_cyc;
        $read->{'last_cycle'} = $first_cyc + $read->{'numcycles'} - 1;
        $first_cyc = $read->{'last_cycle'} + 1;
    }

    if (scalar(grep { !($_->{'is_index'}) } @{$ret{'reads'}}) > 1)
    {
        $ret{'runtype'} = 'PE';
    }
    else
    {
        $ret{'runtype'} = 'SR';
    }

    return \%ret;
}

### OO-interface

sub new
{
    my ($cls, $rundir) = @_;
    my $self = { rundir => realpath($rundir) };

    bless($self);
    
    return $self;
}

1;

