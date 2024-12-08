package App::Egaz::Command::template;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'create pipeline files';
}

sub opt_spec {
    return (
        [   "mode" => hidden => {
                default => "multi",
                one_of  => [
                    [ "multi" => "multiple genome alignments, orthologs" ],
                    [ "self"  => "self genome alignments, paralogs" ],
                    [ "prep"  => "prepare sequences" ],
                ],
            }
        ],
        [],
        [ "outdir|o=s",   "Output directory", { default => "." }, ],
        [ "queue=s",      "QUEUE_NAME",       { default => "mpi" }, ],
        [ "separate",     "separate each Target-Query groups", ],
        [ "tmp=s",        "user defined tempdir", ],
        [ "parallel|p=i", "number of threads", { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        [],
        [ "length=i",  "minimal length of alignment fragments", { default => 1000 }, ],
        [ "partition", "use partitioned sequences if available", ],
        [ "msa=s",     "aligning program for refine alignments", { default => "mafft" }, ],
        [ "taxon=s",   "taxon.csv for this project", ],
        [ "aligndb",   "create aligndb scripts", ],
        [],
        [ "multiname=s", "naming multiply alignment", ],
        [ "outgroup=s",  "the name of outgroup", ],
        [ "tree=s",      "a predefined guiding tree for multiz", ],
        [ "order",       "multiple alignments with original order (using fake_tree.nwk)", ],
        [ "fasttree", "use FastTree instead of RaxML to create a phylotree", ],
        [ "mash",     "create guiding tree by mash", ],
        [ "vcf",      "create vcf files", ],
        [],
        [ "circos",  "create circos script", ],
        [],
        [ "repeatmasker=s", "options passed to RepeatMasker", ],
        [ "perseq=s@",      "split these files by names", ],
        [ "min=i",   "minimal length of sequences",                      { default => 5000 }, ],
        [ "about=i", "split sequences to chunks about approximate size", { default => 5000000 }, ],
        [   "suffix=s@",
            "suffix of wanted files",
            { default => [ "_genomic.fna.gz", ".fsa_nt.gz" ] },
        ],
        [ "exclude=s", "regex to exclude some files", { default => "_from_" }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz template [options] <path/seqdir> [more path/seqdir]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* `path/seqdir` are directories containing multiple .fa files that represent genomes

* Each .fa files in `path/target` should contain only one sequences, otherwise second or latter
  sequences will be omitted

* Species/strain names in result files are the basenames of `path/seqdir`

* Default --multiname is the basename of --outdir. This option is for more than one aligning
  combinations

* without --tree, or --mash, the order of multiz stitch is the same as the one from
  command line

* --tree > --order > --mash

* --outgroup uses basename, not full path. *DON'T* set --outgroup to target

* --taxon may also contain unused taxonomy terms, for the construction of chr_length.csv

* --preq is designed for NCBI ASSEMBLY and WGS, `path/seqdir` are directories containing multiple
  directories

* By default, `RAxML` is used to produce a phylotree. Turn on `--fasttree` to use FastTree, which is
  less accurate and doesn't support outgroups by itself

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
        my $message = "This command need one or more directories.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_dir ) {
            $self->usage_error("The input directory [$_] doesn't exist.");
        }
    }

    if ( $opt->{mode} eq "multi" and @{$args} < 2 ) {
        $self->usage_error("Multiple alignments need at least 2 directories");
    }

    if ( $opt->{tree} ) {
        if ( !Path::Tiny::path( $opt->{tree} )->is_file ) {
            $self->usage_error("The tree file [$opt->{tree}] doesn't exist.");
        }
        else {
            $opt->{tree} = Path::Tiny::path( $opt->{tree} )->absolute()->stringify();
        }
    }

    if ( $opt->{taxon} ) {
        if ( !Path::Tiny::path( $opt->{taxon} )->is_file ) {
            $self->usage_error("The taxon file [$opt->{taxon}] doesn't exist.");
        }
        else {
            $opt->{taxon} = Path::Tiny::path( $opt->{taxon} )->absolute()->stringify();
        }

    }

    $opt->{outdir} = Path::Tiny::path( $opt->{outdir} )->absolute()->stringify();

    if ( !$opt->{multiname} ) {
        $opt->{multiname} = Path::Tiny::path( $opt->{outdir} )->basename();
    }

    $opt->{parallel2} = int( $opt->{parallel} / 2 );
    $opt->{parallel2} = 2 if $opt->{parallel2} < 2;

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    print STDERR "Create templates for [$opt->{mode}] genome alignments\n";

    #----------------------------#
    # prepare working dir
    #----------------------------#
    $opt->{outdir} = Path::Tiny::path( $opt->{outdir} )->absolute();
    $opt->{outdir}->mkpath();
    $opt->{outdir} = $opt->{outdir}->stringify();
    print STDERR "Working directory [$opt->{outdir}]\n";

    if ( $opt->{mode} eq "multi" ) {
        Path::Tiny::path( $opt->{outdir}, 'Pairwise' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Results' )->mkpath();
    }
    elsif ( $opt->{mode} eq "self" ) {
        Path::Tiny::path( $opt->{outdir}, 'Pairwise' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Processing' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Results' )->mkpath();
        Path::Tiny::path( $opt->{outdir}, 'Circos' )->mkpath();
    }

    $args = [ map { Path::Tiny::path($_)->absolute()->stringify() } @{$args} ];

    #----------------------------#
    # names and directories
    #----------------------------#
    print STDERR "Associate names and directories\n";
    my @data;
    {
        my %taxon_of;
        if ( $opt->{taxon} ) {
            for my $line ( Path::Tiny::path( $opt->{taxon} )->lines ) {
                my @fields = split /,/, $line;
                if ( $#fields >= 2 ) {
                    $taxon_of{ $fields[0] } = $fields[1];
                }
            }
        }
        @data = map {
            {   dir   => $_,
                name  => Path::Tiny::path($_)->basename(),
                taxon => exists $taxon_of{ Path::Tiny::path($_)->basename() }
                ? $taxon_of{ Path::Tiny::path($_)->basename() }
                : 0,
            }
        } @{$args};
    }

    # move $opt->{outgroup} to last
    if ( $opt->{mode} eq "multi" and $opt->{outgroup} ) {
        my ($exist) = grep { $_->{name} eq $opt->{outgroup} } @data;
        if ( !defined $exist ) {
            Carp::confess "--outgroup [$opt->{outgroup}] does not exist!\n";
        }

        @data = grep { $_->{name} ne $opt->{outgroup} } @data;
        push @data, $exist;
    }
    $opt->{data} = \@data;    # store in $opt

    print STDERR YAML::Syck::Dump( $opt->{data} )
        if $opt->{verbose} and $opt->{mode} ne "prep";

    # genome.lst
    if ( $opt->{mode} ne "prep" ) {
        print STDERR "Create genome.lst\n";
        my $fh = Path::Tiny::path( $opt->{outdir}, "genome.lst" )->openw;
        for my $i ( 0 .. $#data ) {
            print {$fh} "$data[$i]->{name}\n";
        }
        close $fh;
    }

    # If there's no phylo tree, generate a fake one.
    if ( $opt->{mode} eq "multi" and !$opt->{tree} ) {
        print STDERR "Create fake_tree.nwk\n";
        my $fh = Path::Tiny::path( $opt->{outdir}, "fake_tree.nwk" )->openw;
        print {$fh} "(" x ( scalar(@data) - 1 ) . "$data[0]->{name}";
        for my $i ( 1 .. $#data ) {
            print {$fh} ",$data[$i]->{name})";
        }
        print {$fh} ";\n";
        close $fh;
    }

    #----------------------------#
    # prep *.sh files
    #----------------------------#
    if ( $opt->{mode} eq "prep" ) {
        $self->gen_prep( $opt, $args );
    }

    #----------------------------#
    # multi *.sh files
    #----------------------------#
    if ( $opt->{mode} eq "multi" ) {
        $self->gen_pair( $opt, $args );

        # $self->gen_rawphylo( $opt, $args ) if $opt->{rawphylo};
        $self->gen_multi( $opt, $args );
        $self->gen_vcf( $opt, $args ) if $opt->{vcf};
    }

    #----------------------------#
    # self *.sh files
    #----------------------------#
    if ( $opt->{mode} eq "self" ) {
        $self->gen_self( $opt, $args );
        $self->gen_proc( $opt, $args );
        $self->gen_circos( $opt, $args ) if $opt->{circos};
    }

    if ( $opt->{mode} eq "multi" or $opt->{mode} eq "self" ) {
        $self->gen_mash( $opt, $args );

        $self->gen_aligndb( $opt, $args ) if $opt->{aligndb};
        $self->gen_packup( $opt, $args );
    }
}

sub gen_prep {
    my ( $self, $opt, $args ) = @_;

    my @patterns = map {"*$_"} @{ $opt->{suffix} };
    my %perseq   = map { $_ => 1, } @{ $opt->{perseq} };

    my @files;
    for ( @{$args} ) {
        push @files, File::Find::Rule->file->name(@patterns)->in($_);
    }

    {
        @files = grep { !/$opt->{exclude}/ } @files;
        @files = map  { Path::Tiny::path($_)->absolute()->stringify } @files;
        @files = map {
            {   basename => Path::Tiny::path($_)->parent()->basename(),
                perseq   => exists $perseq{ Path::Tiny::path($_)->parent()->basename() }
                ? 1
                : 0,
                file => $_,
            }
        } @files;

        print STDERR YAML::Syck::Dump \@files if $opt->{verbose};
    }

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "0_prep.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

[% FOREACH item IN files -%]
log_info [% item.basename %]

if [ -d [% item.basename %] ]; then
    log_debug "[% item.basename %] presents"
else
    log_debug Processing [% item.file %]

    egaz prepseq \
        [% item.file %] \
[% IF not item.perseq -%]
        --about [% opt.about %] \
[% END -%]
[% IF opt.repeatmasker -%]
        --repeatmasker "[% opt.repeatmasker %]" \
[% END -%]
        --min [% opt.min %] --gi -v \
        -o [% opt.outdir %]/[% item.basename %]
fi

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args  => $args,
            opt   => $opt,
            files => \@files,
            sh    => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

}

sub gen_aligndb {
    my ( $self, $opt, $args ) = @_;

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $template;
    my $sh_name;

    $sh_name = "6_chr_length.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Results;

echo "common_name,taxon_id,chr,length,assembly" > Results/chr_length.csv

[% FOREACH item IN opt.data -%]
# [% item.name %]
perl -nla -F"\t" -e '
    print qq{[% item.name %],[% item.taxon %],$F[0],$F[1],}
    ' \
    [% item.dir %]/chr.sizes \
    >> Results/chr_length.csv;

[% END -%]

log_info chr_length.csv generated

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

    if ( $opt->{mode} eq "multi" ) {
        $sh_name = "7_multi_aligndb.sh";
        print STDERR "Create $sh_name\n";
        $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Results;

cd Results

#----------------------------#
# Create anno.yml
#----------------------------#
log_info create anno.json

if [ -e [% opt.data.0.dir -%]/anno.json ]; then
    cp [% opt.data.0.dir -%]/anno.json anno.json;
else
    if [ -e [% opt.data.0.dir -%]/cds.json ]; then
        cp [% opt.data.0.dir -%]/cds.json cds.json;
    else
        spanr gff --tag CDS \
            [% opt.data.0.dir -%]/*.gff \
            -o cds.json
    fi

    if [ -e [% opt.data.0.dir -%]/repeat.json ]; then
        cp [% opt.data.0.dir -%]/repeat.json repeat.json;
    else
        spanr gff \
            [% opt.data.0.dir -%]/*.rm.gff \
            -o repeat.json
    fi

    # create empty cds.json or repeat.json
    spanr genome [% opt.data.0.dir -%]/chr.sizes -o chr.json
    spanr compare --op diff chr.json chr.json -o empty.json

    for type in cds repeat; do
        if [ ! -e ${type}.json ]; then
            cp empty.json ${type}.json
        fi
    done

    spanr merge \
        cds.json repeat.json \
        -o anno.json

    rm -f repeat.json cds.json chr.json empty.json
fi

#----------------------------#
# alignDB.pl
#----------------------------#
log_info run alignDB.pl

alignDB.pl \
    -d [% opt.multiname %] \
    --da [% opt.outdir %]/[% opt.multiname %]_refined \
    -a [% opt.outdir %]/Results/anno.json \
[% IF opt.outgroup -%]
    --outgroup \
[% END -%]
    --chr [% opt.outdir %]/Results/chr_length.csv \
    --lt [% opt.length %] --parallel [% opt.parallel %] --batch 10 \
    --run 1,2,5,10,21,30-32,40-42,44

exit;

EOF
        $tt->process(
            \$template,
            {   args => $args,
                opt  => $opt,
                sh   => $sh_name,
            },
            Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
        ) or Carp::confess Template->error;
    }
    elsif ( $opt->{mode} eq "self" ) {
        $sh_name = "7_self_aligndb.sh";
        print STDERR "Create $sh_name\n";
        $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Results;

cd Results

#----------------------------#
# [% opt.multiname %]
#----------------------------#
# steal multiname from --multi

log_info init_alignDB

alignDB.pl \
    -d [% opt.multiname %]_self \
    --chr [% opt.outdir %]/Results/chr_length.csv \
    --run 1


#----------------------------#
# gen_alignDB.pl
#----------------------------#
# gen_alignDB to existing database

log_info gen_alignDB

[% FOREACH item IN opt.data -%]
# [% item.name %]
alignDB.pl \
    -d [% opt.multiname %]_self \
    --da [% opt.outdir %]/Results/[% item.name %]/[% item.name %].pair.fas \
    --lt 1000 --parallel [% opt.parallel %] \
    --run 2

[% END -%]

#----------------------------#
# rest steps
#----------------------------#
alignDB.pl \
    -d [% opt.multiname %]_self \
    --parallel [% opt.parallel %] --batch 10 \
    --run 5,10,21,30-32,40,42,44

exit;

EOF
        $tt->process(
            \$template,
            {   args => $args,
                opt  => $opt,
                sh   => $sh_name,
            },
            Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
        ) or Carp::confess Template->error;

    }
}

sub gen_packup {
    my ( $self, $opt, $args ) = @_;

    my $tt       = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $sh_name  = "9_pack_up.sh";
    my $template = "9_pack_up.tt2.sh";

    print STDERR "Create $sh_name\n";

    $tt->process(
        $template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_pair {
    my ( $self, $opt, $args ) = @_;

    my $tt       = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $sh_name  = "1_pair.sh";
    my $template = "1_pair.tt2.sh";

    print STDERR "Create $sh_name\n";

    $tt->process(
        $template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_mash {
    my ( $self, $opt, $args ) = @_;

    my $tt       = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $sh_name  = "2_mash.sh";
    my $template = "2_mash.tt2.sh";

    print STDERR "Create $sh_name\n";

    $tt->process(
        $template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_multi {
    my ( $self, $opt, $args ) = @_;

    my $tt       = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $sh_name  = "3_multi.sh";
    my $template = "3_multi.tt2.sh";

    print STDERR "Create $sh_name\n";

    $tt->process(
        $template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_vcf {
    my ( $self, $opt, $args ) = @_;

    my $tt       = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $sh_name  = "4_vcf.sh";
    my $template = "4_vcf.tt2.sh";

    print STDERR "Create $sh_name\n";

    $tt->process(
        $template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_self {
    my ( $self, $opt, $args ) = @_;

    my $tt       = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $sh_name  = "1_self.sh";
    my $template = "1_self.tt2.sh";

    print STDERR "Create $sh_name\n";

    $tt->process(
        $template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_proc {
    my ( $self, $opt, $args ) = @_;

    my $tt       = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );
    my $sh_name  = "3_proc.sh";
    my $template = "3_proc.tt2.sh";

    print STDERR "Create $sh_name\n";

    $tt->process(
        $template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;
}

sub gen_circos {
    my ( $self, $opt, $args ) = @_;

    my $tt = Template->new( INCLUDE_PATH => [ File::ShareDir::dist_dir('App-Egaz') ], );

    # circos.conf and karyotype.id.txt
    for my $item ( @{ $opt->{data} } ) {
        print STDERR "Create circos.conf for $item->{name}\n"
            if $opt->{verbose};
        $tt->process(
            "circos.conf.tt2",
            {   dir => $opt->{outdir},
                id  => $item->{name},
            },
            Path::Tiny::path( $opt->{outdir}, 'Circos', $item->{name}, "circos.conf" )->stringify
        ) or Carp::confess Template->error;

        # copy prebuilt karyotype file
        if ( $item->{taxon} != 0 ) {
            my $karyo = Path::Tiny::path( File::ShareDir::dist_dir('App-Egaz'),
                "share", "karyotype", "karyotype.$item->{taxon}.txt" );

            if ( $karyo->is_file ) {
                print STDERR "    Copy prebuilt karyotype.$item->{name}.txt\n"
                    if $opt->{verbose};
                $karyo->copy( $opt->{outdir}, 'Circos', $item->{name},
                    "karyotype.$item->{name}.txt" );
            }
        }
    }

    # 4_circos.sh
    my $template;
    my $sh_name;

    $sh_name = "4_circos.sh";
    print STDERR "Create $sh_name\n";
    $template = <<'EOF';
[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Pairwise

[% FOREACH item IN opt.data -%]
[% id = item.name -%]
#----------------------------#
# [% id %]
#----------------------------#
log_info [% id %]
cd [% opt.outdir %]/Circos/[% id %]

#----------------------------#
# karyotype
#----------------------------#
log_debug Adjust karyotype

# generate karyotype files
if [ ! -e karyotype.[% id %].txt ]; then
    log_debug Create default karyotype
    perl -anl -e '$i++; print qq{chr - $F[0] $F[0] 0 $F[1] chr$i}' \
        [% item.dir %]/chr.sizes \
        > karyotype.[% id %].txt
fi

# spaces among chromosomes
if [[ $(perl -n -e '$l++; END{print qq{$l\n}}' [% item.dir %]/chr.sizes ) > 1 ]]; then
    log_debug Multiple chromosomes
    perl -nlpi -e 's/    default = 0r/    default = 0.005r/;' circos.conf
    perl -nlpi -e 's/show_label     = no/show_label     = yes/;' circos.conf
fi

# chromosome units
SIZE=$(perl -an -F'\t' -e '$s += $F[1]; END{print qq{$s\n}}' [% item.dir %]/chr.sizes )
log_debug "Genome size ${SIZE}"
if [ ${SIZE} -ge 1000000000 ]; then
    echo "    * Set chromosome unit to 1 Mbp"
    perl -nlpi -e 's/chromosomes_units = 1000/chromosomes_units = 100000/;' circos.conf
elif [ ${SIZE} -ge 100000000 ]; then
    echo "    * Set chromosome unit to 100 kbp"
    perl -nlpi -e 's/chromosomes_units = 1000/chromosomes_units = 100000/;' circos.conf
elif [ ${SIZE} -ge 10000000 ]; then
    echo "    * Set chromosome unit to 10 kbp"
    perl -nlpi -e 's/chromosomes_units = 1000/chromosomes_units = 10000/;' circos.conf
else
    echo "    * Keep chromosome unit as 1 kbp"
fi

#----------------------------#
# gff to highlight
#----------------------------#
log_debug Create highlight files

if [ ${SIZE} -ge 10000000 ]; then
    # avoid errors of too many highlights
    touch highlight.features.[% id %].txt
    touch highlight.repeats.[% id %].txt
else
    # coding and other features
    perl -anl -e '
        /^#/ and next;
        $F[0] =~ s/\.\d+//;
        $color = q{};
        $F[2] eq q{CDS} and $color = q{chr9};
        $F[2] eq q{ncRNA} and $color = q{dark2-8-qual-1};
        $F[2] eq q{rRNA} and $color = q{dark2-8-qual-2};
        $F[2] eq q{tRNA} and $color = q{dark2-8-qual-3};
        $F[2] eq q{tmRNA} and $color = q{dark2-8-qual-4};
        $color and ($F[4] - $F[3] > 49) and print qq{$F[0] $F[3] $F[4] fill_color=$color};
        ' \
        [% item.dir %]/*.gff \
        > highlight.features.[% id %].txt

    # repeats
    perl -anl -e '
        /^#/ and next;
        $F[0] =~ s/\.\d+//;
        $color = q{};
        $F[2] eq q{region} and $F[8] =~ /mobile_element|Transposon/i and $color = q{chr15};
        $F[2] =~ /repeat/ and $F[8] !~ /RNA/ and $color = q{chr15};
        $color and ($F[4] - $F[3] > 49) and print qq{$F[0] $F[3] $F[4] fill_color=$color};
        ' \
        [% item.dir %]/*.gff \
        > highlight.repeats.[% id %].txt
fi

#----------------------------#
# links of paralog ranges
#----------------------------#
log_debug Create link files

for n in 2 3 4-50; do
    linkr filter [% opt.outdir %]/Results/[% id %]/[% id %].links.tsv -n ${n} -o stdout \
        > links.copy${n}.tsv

    if [ "${n}" == "4-50" ]; then
        linkr circos links.copy${n}.tsv -o [% id %].linkN.txt --highlight
    else
        linkr circos links.copy${n}.tsv -o [% id %].link${n}.txt
    fi

    rm links.copy${n}.tsv
done

#----------------------------#
# run circos
#----------------------------#
log_info Run circos
circos -noparanoid -conf circos.conf

[% END -%]

exit;

EOF
    $tt->process(
        \$template,
        {   args => $args,
            opt  => $opt,
            sh   => $sh_name,
        },
        Path::Tiny::path( $opt->{outdir}, $sh_name )->stringify
    ) or Carp::confess Template->error;

}

1;
