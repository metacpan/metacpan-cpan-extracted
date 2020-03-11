package Bio::Palantir::Parser;
# ABSTRACT: front-end class for Bio::Palantir::Parser module, wich handles the parsing of biosynML.xml and regions.js antiSMASH reports
$Bio::Palantir::Parser::VERSION = '0.200700';
use Moose;
use namespace::autoclean;

use autodie;

use Carp;
use File::Basename 'fileparse';
use File::Temp;
use JSON::Parse 'json_file_to_perl';
use POSIX 'ceil';
use XML::Bare;
use XML::Hash::XS;

use aliased 'Bio::Palantir::Parser::Root';
extends 'Bio::FastParsers::Base';


# ATTRIBUTES



has 'root' => (
    is       => 'ro',
    isa      => 'Bio::Palantir::Parser::Root',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_root',
);


has 'module_delineation' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'substrate-selection',
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_root {
    my $self = shift;

    my @exts = qw(.xml .js);
    my ($name, $dir, $ext) = fileparse($self->file, @exts);
 
    my $biosynml = File::Temp->new(suffix => '.xml'); 

    if ($ext eq '.js') {
        my $xmlstr = $self->_convert_js2biosynml;
        open my $out, '>', $biosynml->filename;
        say {$out} $xmlstr;
    }

    my $file = $ext eq '.xml' ? $self->file :  $biosynml->filename;

    my $xb = XML::Bare->new( file => $file )
        or croak "Can't open '$file' for reading: $!";

    my $root = $xb->parse->{'root'};
    unless ($root) {
        carp "Warning: '$file' unexpectedly empty; returning no root!";
        return;
    }

    return Root->new( _root => $root,
        module_delineation => $self->module_delineation );
}

## use critic

sub _convert_js2biosynml {
    my $self = shift;

    my $js = $self->file;
    my $json = File::Temp->new(suffix => '.json');

    open my $in, '<', $js;

    chomp( my @lines = <$in> );

    open my $out, '>', $json->filename;
    for my $i (0 .. @lines - 1) {

        if ($i == 0) {
            say {$out} '{' . "\n" . '  "recordData": [';
        }

        elsif ($lines[$i] =~ m/all_regions/xms) {
           say {$out} '  "all_regions": {';
        }

        elsif ($lines[$i] =~ m/details_data/xms) {
           say {$out} '  "details_data": {';
        }

        elsif ($i == @lines - 2) {
            say {$out} '    }';
        }

        elsif ($i == @lines - 1) {
            say {$out} '  }';
        }
        
        else {
            $lines[$i] =~ s/\]\;/\]\,/xms;
            $lines[$i] =~ s/\}\;/\}\,/xms;
            say {$out} '  ' . $lines[$i];
        }
    }

    print {$out} '}';
    close $out;

    my $root = json_file_to_perl($json->filename);

    my %json_for;
    my ($cluster_id, $gene_id) = (1,1);

    # parse the first part of the report
    my $region_for = $root->{all_regions};
    for my $region (@{ $region_for->{order} }) {

        my %cluster_for = (
            id    => $cluster_id++,
            name  => $region_for->{$region}{anchor},
            rank  => $region_for->{$region}{idx},
            type  => $region_for->{$region}{type},
            start => $region_for->{$region}{start}, # DNA coordinates
            end   => $region_for->{$region}{end},
        );
        
        $json_for{ $cluster_for{name} }{$_} = $cluster_for{$_} 
            for keys %cluster_for;

        my $orfs = $region_for->{$region}{orfs};

        for my $orf (@{ $orfs }) {

            my $def = $orf->{description};
            my ($sequence) 
                = $def =~ m/PROGRAMS=blastp&amp;QUERY=([A-Z]+)\&amp/xms;

            my %orf_for = (
                id       => $gene_id++,
                name     => $orf->{locus_tag},
                start    => $orf->{start},  # DNA coordinates
                end      => $orf->{end},
                type     => $orf->{type},
                sequence => $sequence,
                strand   => $orf->{strand},
            );

            $json_for{ $cluster_for{name} }{genes}{ $orf_for{name} }{$_} 
                = $orf_for{$_} for keys %orf_for;
        }
    }

    # parse the second part of the report
    my $domain_id = 1; 
    my $module_id = 1;
    $region_for = $root->{details_data}; # reassigning the region_for var
    for my $region (keys %{ $region_for }) {

        my $cluster_name = $region_for->{$region}{id};
        my $orfs = $region_for->{$region}{orfs};
    
        my $prev_domain;
        for my $orf (@{ $orfs }) {

            my $gene_name = $orf->{id};
            for my $domain (@{ $orf->{domains} }) {
                
                # fix duplicate domains in v5 (2019.11.02)
                if ($domain_id > 1 && $prev_domain
                    && $domain->{start} eq $prev_domain->{start}
                    && $domain->{sequence} eq $prev_domain->{sequence}
                    ) {
                    next;
                }
                
                $json_for{$cluster_name}{genes}{$gene_name}{domains}{$domain_id}
                    = {
                    id           => $domain_id++,
                    gene_id      => $json_for{$cluster_name}{genes}{$gene_name}{id},
                    prot_start   => $domain->{start},
                    prot_end     => $domain->{end},
                    type         => $domain->{type},
                    sequence     => $domain->{sequence},
                    dna_start    => $domain->{start} == 1 
                                        ? 1 : $domain->{start} * 3,
                    dna_end      => $domain->{end} * 3,
                    abbreviation => $domain->{abbreviation}, # = symbol
                };

                $prev_domain = $domain;
            }

            if ($orf->{modules}) {    # appeared in antiSMASH version 5.1
                
                for my $module (@{ $orf->{modules} }) {

                    my @gene_dna_coordinates = (
                        $json_for{$cluster_name}{genes}{$gene_name}{start},
                        $json_for{$cluster_name}{genes}{$gene_name}{end},
                    );

                    my $genomic_prot_start = ceil(($gene_dna_coordinates[0] / 3))
                        + $module->{start} - 1;     # if module starting pos is 1, this souldn't be position 2 on the gene coords
                    my $genomic_prot_end =   ceil(($gene_dna_coordinates[0] / 3))
                        + $module->{end} - 1;

                    my $dna_start = $module->{start} == 1   # if prot pos is 1, it should still be 1 in DNA
                        ? 1 
                        : $module->{start} * 3
                    ;

                    my $genomic_dna_start = $gene_dna_coordinates[0]
                        + $dna_start - 1;
                    my $genomic_dna_end   = $gene_dna_coordinates[0]
                        + ($module->{end} * 3) - 1;
                    
                    $json_for{$cluster_name}{modules}{
                        'module' . $module_id} = {
                        id         => $module_id++,
                        gene_id    => $gene_name,
                        rel_start  => $module->{start}, # relative to gene coordinates
                        rel_end    => $module->{end},
                        prot_start => $genomic_prot_start,
                        prot_end   => $genomic_prot_end,
                        dna_start  => $genomic_dna_start,
                        dna_end    => $genomic_dna_end,
                        complete   => $module->{complete} == 1
                            ? 'true' : 'false',
                        iterative  => $module->{iterative},
                        monomer    => $module->{monomer},
#                         domains    => join ',', @module_domains // 'NULL',
                    };
                }
            }
        }
    }

    # ### %json_for

    # writing biosynML format
    my %biosynml_for;
    for my $cluster (keys %json_for) {

        my ($c_id, $c_name, $c_begin, $c_end, $c_type) 
            = map {  $json_for{$cluster}{$_} } qw(id name start end type);

        my $model_id = 'model id="' . $c_id . '"';

        $biosynml_for{$model_id}{genecluster}{name} = $c_name; 
        $biosynml_for{$model_id}{genecluster}{type} = $c_type;
        $biosynml_for{$model_id}{genecluster}{region}{begin} = $c_begin;    # DNA coordinates
        $biosynml_for{$model_id}{genecluster}{region}{end}   = $c_end;

        GENE: 
        for my $gene (keys %{ $json_for{$cluster}{genes} }) {

            my ($g_id, $g_name, $g_begin, $g_end, $g_sequence) 
                = map { $json_for{$cluster}{genes}{$gene}{$_} } 
                qw(id name start end sequence)
            ;

            my $attr_gene_id = 'gene id="' . $g_id . '"';
            $biosynml_for{genelist}{$attr_gene_id}{gene_name} = $g_name;
            $biosynml_for{genelist}{$attr_gene_id}{gene_location}{begin} 
                = $g_begin;
            
            $biosynml_for{genelist}{$attr_gene_id}{gene_location}{end} 
                = $g_end;
            
            $biosynml_for{genelist}{$attr_gene_id}{gene_qualifiers}{'qualifier' 
                . ' name="translation" ori="auto-annotation" style="genbank"'} 
                = $g_sequence
            ;

            for my $domain (keys %{ $json_for{$cluster}{genes}{$gene}{domains}
                }) {
                
                my ($d_id, $dgene_id, $d_pbegin, $d_pend, $d_dbegin, 
                    $d_dend,$d_type, $d_sequence)
                    = map { $json_for{$cluster}{genes}{$gene}{domains}{
                    $domain}{$_} } 
                    qw(id gene_id prot_start prot_end 
                        dna_begin dna_end type sequence)
                ;

                my $attr_domain_id = 'domain id="' . $d_id .'"';

                $biosynml_for{domainlist}{$attr_domain_id} 
                    = { 
                    nodeid => $d_id,
                    function => $d_type,
                    location => {
                        gene => {
                            'geneid source ="genelist"' => $dgene_id,
                            position => { begin => $d_dbegin, end => $d_dend, },
                        },
                        protein => {
                            sequence => $d_sequence,
                            position => { begin => $d_pbegin, end => $d_pend, },
                        },
                    },
                };
            }
        }
       
       if ($json_for{$cluster}{modules}) {

            my $module_for = $json_for{$cluster}{modules}; 

            MODULE:
            for my $module (keys %{ $module_for }) {
            
                my $attr_module_id = 'module id="' 
                    . $module_for->{$module}{id} .'"';
             
                $biosynml_for{modulelist}{$attr_module_id}{$_} 
                  = $module_for->{$module}{$_} 
                  for keys %{ $module_for->{$module} }
                ;
            }
        }
    }

    # ### %biosynml_for

    # write XML file
    my $conv   = XML::Hash::XS->new(utf8 => 0, encoding => 'utf-8', indent => 4);
    my $xmlstr = $conv->hash2xml(\%biosynml_for, utf8 => 1);

    # correct artificial attributes
    $xmlstr =~ s/(<\/[a-z\_]+).*?>/$1>/xmsg;

    return($xmlstr);
}

sub is_cluster_type_ok {

    my $self = shift;

    my @filter_types  = shift;

    my @allowed_types = qw(
        acyl_amino_acids amglyccycl arylpolyene bacteriocin butyrolactone 
        cyanobactin ectoine hserlactone hglE-KS indole ladderane lantipeptide
        lassopeptide microviridin nrps nucleoside oligosaccharide otherks 
        phenazine phosphonate PKS proteusin PUFA resorcinol siderophore t1pks 
        t2pks t3pks terpene
    );

    for my $type (@filter_types) {

        unless (grep { $type =~ m/$_/xmsi } @allowed_types) {

            croak 'Error: value "' . $type . '" from --types option is '
            . 'incorrect. Please look allowed values with --help option';
        }
    }
    
    return(1);
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Parser - front-end class for Bio::Palantir::Parser module, wich handles the parsing of biosynML.xml and regions.js antiSMASH reports

=head1 VERSION

version 0.200700

=head1 SYNOPSIS

    #TODO

=head1 DESCRIPTION

This module implements classes and their methods for B<parsing antisMASH
reports>. The supported report formats are the F<biosynML.xml> file generated in
antiSMASH v3-4 (though the version 4 needs to be explicitely activated in the
options) or the F<regions.js> in the version 5.

The Biosynthetic Gene Cluster (BGC) information is hierarchically organized as
follows:

C<Root.pm>: contains the root of the BGC data structure

C<Cluster.pm>: contains attributes and methods for the BGC B<Cluster> level,
including an array of Gene objects 

C<Gene.pm>:    contains attributes and methods for the BGC B<Gene> level,
including an array of Domain objects (if NRPS/PKS BGCs)

C<Module.pm>:  contains attributes and methods for the BGC B<Module> level
(generated by Palantir), including an array of Domain objects (this class is
parallel to Genes, as module can be overlapping 2 genes)

C<domain.pm>:  contains attributes and methods for the BGC B<Domain> level,
including an array of Motif objects

C<Motif.pm>:   contains attributes and methods for the BGC B<Motif> level

=head1 ATTRIBUTES

=head2 file

Path to biosynML.xml or regions.js antiSMASH report file to be parsed.

=head2 root

C<Bio::Palantir::Parser::Root> composed object

=head2 file

Path to a biosynML.xml or regions.js file

=head2 root

L<Bio::Palantir::Parser::Root> composed object

=head2 module_delineation

Module delineation method: generates modules from condensation or selection domains.

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
