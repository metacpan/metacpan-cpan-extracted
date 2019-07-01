#!/usr/bin/env perl
# PODNAME: draw_bgc_maps.pl
# ABSTRACT: This script draws NRPS/PKS BGC clusters maps in PNG
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use Carp;
use GD::Simple;
use Getopt::Euclid qw(:vars);
use POSIX;

use Bio::Palantir;
use Bio::MUST::Core;

use aliased 'Bio::Palantir::Parser';
use aliased 'Bio::Palantir::Refiner::ClusterPlus';
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::FastParsers::Hmmer::DomTable';


# load biosynML.xml/regions.js file report
my $report = Parser->new( file => $ARGV_report_file);
my $root = $report->root;

# generate Cluster object depending on selected mode
mkdir $ARGV_outdir unless -d $ARGV_outdir;

for my $cluster ($root->all_clusters) {

    my %selection_for = (
        antismash => [$cluster],
        palantir  => [ClusterPlus->new( _cluster => $cluster )],
        all       => [
                       $cluster, 
                       ClusterPlus->new( _cluster => $cluster),
                       ClusterPlus->new( _cluster => $cluster, from_seq => 1),
                     ],
    );

    
    my @clusters = @{ $selection_for{$ARGV_mode} };

    carp 'Error: the given string for --mode is not correct.'  
        . ' Only these are available: antismash, palantir, and all.' 
        unless @clusters
    ;

    map_cluster(@clusters);
}


sub map_cluster {                           ## no critic (Subroutines::ProhibitExcessComplexity)

    #TODO fix magic number
    #TODO reduce sub complexity (35)
    my @clusters = @_;

    # create all objects to draw
    my $cluster_i = 1;
    my $y_cluster = 0;
    my ($cluster_rank, $cluster_type);
    my (@genes, @modules, @domains);

    CLUSTER:
    for my $cluster (@clusters) {

        unless ($cluster->type =~ m/nrps | pks/xmsi) {
            return;
        }

        if ($ARGV_verbose) {

            if (@clusters == 3) {
                my $annotation = $cluster_i == 1
                    ? 'antiSMASH annotation'
                    : $cluster_i == 2
                    ? 'Palantir standard annotation'
                    : 'Palantir exploratory annotation'
                ;

                say $annotation;
            }
            say 'Cluster' . $cluster->rank . ': ' . $cluster->type;
        }

        my $domains_size;

        $cluster_rank = $cluster->rank;
        $cluster_type = $cluster->type;
        
        my $gene_begin;
        my $gene_size  = 0;
        my $max_y_overlap = 0;

        # Gene objects
        GENE:
        for my $gene ($cluster->all_genes) {

            next GENE unless $gene->all_domains;
           
            say 'for Gene' . $gene->rank . '(' . $gene->name . '):'
                if $ARGV_verbose;

            $gene_begin += $gene_size + 1;  # + 10 to space genes
            $gene_size   = abs($gene->genomic_prot_size);

            my $gene_end = $gene_begin + $gene_size;

            push @genes, {
                name      => $gene->name,
                uui       => $gene->uui,
                begin     => $gene_begin, 
                end       => $gene_end, 
                y_cluster => $y_cluster,
                color     => scalar $gene->all_domains > 0 ? 'red' : 'gray',
            };

            # Domain objects
            my $y_overlap = 0;
            my $overlapping_end = 0; 

            for my $domain (sort { $a->rank <=> $b->rank } $gene->all_domains) {

                $domains_size += $domain->size;

                my $domain_begin = $gene_begin + $domain->begin;
                my $domain_end   = $gene_begin + $domain->end;

                # handle overlapping domains
                if ($domain->begin > $overlapping_end) {
                    $y_overlap -= 50 unless $y_overlap == 0;
                    $overlapping_end = $domain->end;
                }

               else { 
                    $y_overlap += 50;
                    $max_y_overlap = $y_overlap
                        if $y_overlap > $max_y_overlap;
                }
               
                my ($evalue, $subtype, $subevalue) = ('NULL') x 3;
                if ($cluster->meta->name eq 
                    'Bio::Palantir::Refiner::ClusterPlus') {
                    $evalue = $domain->evalue // 'NULL';
                    $subtype = $domain->subtype // 'NULL';
                    $subevalue = $domain->subtype_evalue // 'NULL';
                }

                say 'Domain' . $domain->rank . ': '. $domain->symbol . '['
                    . $evalue . '] | ' . $domain->begin . '-' . $domain->end
                    . "\n" . $domain->protein_sequence . "\n"
                    if $ARGV_verbose
                ;

                push @domains, {
                    function  => $domain->function . '['. $evalue . ']', 
                    symbol    => $domain->symbol,
                    subtype   => $subtype . '[' . $subevalue . ']',
                    begin     => $domain_begin, 
                    end       => $domain_end, 
                    class     => $domain->class,
                    y_cluster => $y_cluster,
                    y_overlap => $y_overlap,
                };

            }
        }
        
        # try next cluster mode if no @genes or no @domains 
        unless (@genes && @domains) {
            next CLUSTER;
        }

        # handle creation of module objects
        my $nomodule = 0;
        if ($cluster->meta->name eq 'Bio::Palantir::Refiner::ClusterPlus') {
            $nomodule = 1 if $cluster->from_seq == 1;
        }

        # Module objects
        if (scalar $cluster->all_modules > 0 && $nomodule == 0) {

            for my $module (sort { $a->rank <=> $b->rank } 
                $cluster->all_modules) {
            
                my @gene_uuis = @{ $module->gene_uuis };

                my @mgenes;
                for my $pattern (@gene_uuis) {
                    push @mgenes, grep { $_->{uui} eq $pattern } @genes;  #duplicated genes if 'all' mode
                }

                my @mdomains = sort { $a->rank <=> $b->rank } $module->all_domains;

                my $module_begin = $mgenes[0]->{begin}  + $mdomains[0]->begin;
                my $module_end   = $mgenes[-1]->{begin} + $mdomains[-1]->end;
                
                push @modules, {
                    name      => 'M' . $module->rank, 
                    begin     => $module_begin, 
                    end       => $module_end,
                    y_cluster => $y_cluster,
                };
            }
        }

        $y_cluster += $max_y_overlap + 625;
        $cluster_i++;
    }

    # do not draw if no @genes or @domains
    unless (@genes && @domains) {
        return;
    }
        
    # make the background transparent and interlaced
    my @sorted_ends = sort { $b <=> $a } map{ $_->{end} } @genes;
    my $width = $sorted_ends[0];
    my $height = $y_cluster + 600;

    my $left_margin = 50;
    my $right_margin = 50;
    
    my $img = GD::Simple->new($width + $left_margin + $right_margin, $height);

    ### Drawing object: 'Cluster' . $cluster_rank

    # draw tickles
    $img->penSize(5,5);
    $img->line($left_margin, 75, $width, 75);    # $img->line($x1,$y1,$x2,$y2 [,$color])

    my $font = 'Arial';
    my $tickles_space = 1000;
    my $tickles_n = floor($width / $tickles_space);

    for my $i (0..$tickles_n) {
    
        my $tickle_pos = $i * $tickles_space;

        # line
        my $x1 = $left_margin + $tickle_pos;
        my $y1 = 75;
        my $x2 = $x1;
        my $y2 = 65;
        
        $img->line($x1, $y1, $x2, $y2);

        # text
        $img->moveTo($x1 - 100, 60);     # -100 to centerize the string
        $img->font($font);
        $img->fontsize(50);
        $img->string($tickle_pos);
    }
    
    # draw genes
    $img->moveTo($left_margin, $y_cluster + 100);
    $img->font($font);
    $img->fontsize(50);
    $img->string('Legend:');

    for my $gene (@genes) {
       
        # rectangle
        $img->penSize(5,5);

        $img->bgcolor($gene->{color});
        $img->fgcolor('black');

        my $x1 = $gene->{begin} + $left_margin;
        my $y1 = 100 + $gene->{y_cluster};
        my $x2 = $gene->{end} + $left_margin;
        my $y2 = 200 + $gene->{y_cluster};

        $img->rectangle($x1, $y1, $x2, $y2); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
        $img->moveTo( ($x1 + $x2)/2 - (15 * length $gene->{name}), 
            (100 + 200)/2 + 12.5 + $gene->{y_cluster} );
        $img->font($font);
        $img->fontsize(40);
        $img->string($gene->{name});
    }

    # draw modules
    if (@modules) {

        for my $module (@modules) {

            # rectangle
            $img->penSize(5,5);

            $img->bgcolor('lightyellow');
            $img->fgcolor('black');
            
            my $x1 = $module->{begin} + $left_margin;
            my $y1 = 250 + $module->{y_cluster};
            my $x2 = $module->{end} + $left_margin;
            my $y2 = 350 + $module->{y_cluster};

            $img->rectangle($x1, $y1, $x2, $y2); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
            $img->moveTo( ($x1 + $x2)/2 - (15 * length $module->{name}), 
                ((250 + 350)/2) + 12.5 + $module->{y_cluster} );
            $img->font($font);
            $img->fontsize(40);
            $img->string($module->{name});
        }
    }

    my %color_for = (
        'substrate-selection' => 'deepskyblue',
        'carrier-protein'     => 'mediumseagreen', 
        condensation          => 'orangered',
        termination           => 'peru',
        'tailoring/other'     => 'navajowhite',
    );

    # draw domains
    for my $domain (@domains) {
        
        $img->bgcolor( $color_for{$domain->{class}} );
        $img->fgcolor('black');

        my $y_start = 400;
        my $y_end   = 450;
        my $y_font  = 150;

        my $x1 = $domain->{begin} + $left_margin;
        my $y1 = $y_start + $domain->{y_cluster} + $domain->{y_overlap};
        my $x2 = $domain->{end} + $left_margin;
        my $y2 = $y_end + $domain->{y_cluster} + $domain->{y_overlap};

        $img->rectangle($x1, $y1, $x2, $y2); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)

        $img->moveTo( ($x1 + $x2)/2 - (15 * length $domain->{$ARGV_label}), 
            ($y_start + $y_end)/2 + 12.5 + 
            $domain->{y_cluster} + $domain->{y_overlap} )
        ;

        $img->font($font);
        $img->fontsize(30);
        $img->string($domain->{$ARGV_label});
    }

    # draw legend
    my %legend_for = (
        'substrate-selection' => { x_start => 0   + $left_margin, 
            y_start => 150 + $y_cluster, color => 'deepskyblue' },
        'carrier-protein'     => { x_start => 525 + $left_margin, 
            y_start => 150 + $y_cluster, color => 'mediumseagreen' },
        'condensation'        => { x_start => 0   + $left_margin, 
            y_start => 300 + $y_cluster, color => 'orangered' },
        'termination'         => { x_start => 525 + $left_margin, 
            y_start => 300 + $y_cluster, color => 'peru' },
        'tailoring/other'     => { x_start => 0   + $left_margin, 
            y_start => 450 + $y_cluster, color => 'navajowhite' },
    );

    for my $legend (keys %legend_for) {
        
        $img->bgcolor( $legend_for{$legend}{color} );
        $img->fgcolor('black');

        my $x1 = $legend_for{$legend}{x_start};
        my $y1 = $legend_for{$legend}{y_start};
        my $x2 = $x1 + 125;
        my $y2 = $y1 + 75;
        
        $img->rectangle($x1, $y1, $x2, $y2); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
        $img->moveTo( $x2 + 15, ($y1 + $y2)/2 + 12.5);
        $img->font($font);
        $img->fontsize(30);
        $img->string($legend);
    }

    # convert into png data
    my $output = $ARGV_outdir . $ARGV_prefix . 'Cluster' . $cluster_rank . '_' 
        . $cluster_type . '.png'; 
    open my $out, '>', $output;
    binmode $out;
    print $out $img->png;

    return;
}

__END__

=pod

=head1 NAME

draw_bgc_maps.pl - This script draws NRPS/PKS BGC clusters maps in PNG

=head1 VERSION

version 0.191800

=head1 NAME

draw_bgc_maps.pl - This tool draws NRPS/PKS gene clusters in PNG format. 
Four modes are allowed: antiSMASH, Palantir, Palantir'exploratory mode, or all.

=head1 USAGE

	$0 [options] --report-file [=] <infile>

=head1 REQUIRED ARGUMENTS

=over

=item --report[-file] [=] <infile>

Path to the output file of antismash, which can be either a 
biosynML.xml (antiSMASH 3-4) or a regions.js file (antiSMASH 5).

=for Euclid: infile.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --mode [=] <str>

Mode from which drawings must be made: antismash (untreated antiSMASH data),
palantir (extended domain coordinates + potentially new detected domains),
exploratory (noisy overview of all domain protein signatures found without 
a consensus architecture) [default: all].

=for Euclid: str.type:       /all|antismash|palantir|exploratory/
    str.type.error: <str> must be of all, antismash, palantir, exploratory (not str)
    str.default:    'all'

=item --label [=] <str>

Label to use for the mapping of domains: symbol, function, subtype
[default: symbol]. 

=for Euclid: str.type:   /symbol|function|subtype/
    str.type.error: <str> must be of symbol, function, subtype (not str)
    str.default: 'symbol'

=item --verbose

Print additionnal information concerning domains (functions, 
coordinates and sequence).

=item --outdir [=] <dir_path>

Output directory name and path [default: ./png/].

=for Euclid: dir_path.type:    str
    dir_path.default: 'png/'

=item --prefix [=] <str>

String to use for prefixing the PNG files in output [default: none].

=for Euclid: str.type:    str
    str.default: ''

=item --version

=item --usage

=item --help

=item --man

print the usual program information

=back

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
